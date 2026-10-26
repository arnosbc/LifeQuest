-- Migración 012 · Mazmorra (Deep Working): leer, iniciar y terminar la sesión
-- (requiere 001–011). Ejecutar una vez en Supabase → SQL Editor. Se puede
-- volver a ejecutar.
--
-- 1. dungeon_overview: la sesión abierta (si hay) con sus tareas, ciclos y lo
--    ganado, más las misiones abiertas para la mochila (máx. 5, §13).
-- 2. RPC start_dungeon: crea la sesión y su mochila en una transacción.
-- 3. RPC end_dungeon: cierra la sesión sin perder lo ganado y da el resumen.
-- Cobrar cada ciclo sigue siendo complete_dungeon_cycle (008), que valida el
-- tiempo transcurrido, el tope de ciclos y que la tarea esté en la sesión.
--
-- shortcut: RF-031 (vida perdida al cerrar con tareas sin completar) no se
-- aplica; su valor sigue abierto (docs/plan-cambios-esquema.md §7).

begin;

-- 1. Datos de la pantalla Mazmorra --------------------------------------------
-- security invoker: todo se lee con el RLS del usuario.
create or replace function public.dungeon_overview()
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  with s as (
    select * from public.focus_sessions
    where user_id = auth.uid() and status in ('active', 'paused')
    order by started_at desc limit 1
  ),
  runs as (
    select r.* from public.dungeon_runs r join s on s.id = r.session_id
  )
  select jsonb_build_object(
    'session', (
      select jsonb_build_object(
        'id', s.id,
        'total_minutes', s.total_minutes,
        'cycle_minutes', s.cycle_minutes,
        'started_at', s.started_at,
        'cycles_done', (select count(*) from runs),
        'xp_earned', (select coalesce(sum(q.xp_awarded), 0) from public.quest_log_entries q
                      where q.source_type = 'dungeon' and q.source_id in (select id from runs)),
        'coins_earned', (select coalesce(sum(q.coin_awarded), 0) from public.quest_log_entries q
                         where q.source_type = 'dungeon' and q.source_id in (select id from runs)),
        'tasks', coalesce((
          select jsonb_agg(jsonb_build_object(
            'id', t.id,
            'title', t.title,
            'done', t.status = 'completed',
            'cycles', (select count(*) from runs where runs.task_id = t.id)
          ) order by t.created_at)
          from public.focus_session_tasks f join public.tasks t on t.id = f.task_id
          where f.session_id = s.id
        ), '[]'::jsonb)
      )
      from s
    ),
    'candidates', coalesce((
      select jsonb_agg(jsonb_build_object('id', c.id, 'title', c.title, 'bucket', c.bucket)
                       order by c.bucket_order, c.due_date nulls last)
      from (select * from public.v_daily_highlight
            order by bucket_order, due_date nulls last limit 30) c
    ), '[]'::jsonb),
    'max_tasks', public.rule('dungeon_max_tasks')::integer,
    'cycle_xp', public.rule('dungeon_cycle_xp')::integer
  )
$$;

-- 2. Iniciar --------------------------------------------------------------------
-- security invoker: el insert pasa por el RLS, los grants de columna de 006
-- (started_at lo pone el servidor) y los triggers de una sola sesión abierta
-- y del tope de tareas.
create or replace function public.start_dungeon(
  p_total_minutes integer,
  p_cycle_minutes integer,
  p_task_ids uuid[]
)
returns uuid
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_tasks uuid[];
  v_session uuid;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  if p_cycle_minutes is null or p_cycle_minutes not in (25, 30, 45)
     or p_total_minutes is null or p_total_minutes % 30 <> 0
     or p_total_minutes < p_cycle_minutes or p_total_minutes > 480 then
    raise exception 'invalid_duration' using errcode = '22023';
  end if;
  select array_agg(distinct x) into v_tasks from unnest(coalesce(p_task_ids, '{}')) x;
  if v_tasks is null then
    raise exception 'no_tasks' using errcode = '22023';
  end if;
  if cardinality(v_tasks) > public.rule('dungeon_max_tasks') then
    raise exception 'session_task_limit' using errcode = 'P0001';
  end if;
  if (select count(*) from public.tasks
      where id = any (v_tasks) and user_id = v_uid
        and status in ('pending', 'in_progress', 'delegated')) <> cardinality(v_tasks) then
    raise exception 'task_not_found' using errcode = 'P0002';
  end if;

  insert into public.focus_sessions (user_id, total_minutes, cycle_minutes)
  values (v_uid, p_total_minutes, p_cycle_minutes)
  returning id into v_session;
  insert into public.focus_session_tasks (session_id, task_id)
  select v_session, unnest(v_tasks);
  return v_session;
end $$;

-- 3. Terminar ---------------------------------------------------------------------
create or replace function public.end_dungeon(p_session_id uuid)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_session public.focus_sessions;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  update public.focus_sessions
  set status = 'completed', ended_at = now()
  where id = p_session_id and user_id = auth.uid() and status in ('active', 'paused')
  returning * into v_session;
  if not found then
    raise exception 'session_not_found' using errcode = 'P0002';
  end if;
  return (
    select jsonb_build_object(
      'cycles', count(r.id),
      'xp', coalesce(sum(q.xp_awarded), 0),
      'coins', coalesce(sum(q.coin_awarded), 0),
      'minutes', least(v_session.total_minutes,
                       floor(extract(epoch from v_session.ended_at - v_session.started_at) / 60)::integer)
    )
    from public.dungeon_runs r
    left join public.quest_log_entries q on q.source_type = 'dungeon' and q.source_id = r.id
    where r.session_id = p_session_id
  );
end $$;

-- Permisos ---------------------------------------------------------------------
do $$
declare f text;
begin
  foreach f in array array['public.dungeon_overview()',
    'public.start_dungeon(integer, integer, uuid[])', 'public.end_dungeon(uuid)'] loop
    execute format('revoke all on function %s from public, anon', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;

commit;
