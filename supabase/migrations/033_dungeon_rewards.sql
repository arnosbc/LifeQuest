-- Migración 033 · Botín y tiempo efectivo de la Mazmorra (requiere 001–032).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- 1. Lo ganado en la sesión suma los ciclos Y las misiones de la mochila
--    completadas durante la sesión (antes solo los ciclos: completar una misión
--    dentro de la Mazmorra no cambiaba la tarjeta de recompensas).
-- 2. Tiempo efectivo = ciclos completados × duración del ciclo: solo el tiempo
--    de concentración que el servidor validó y pagó. end_dungeon devolvía el
--    tiempo de reloj desde el inicio, con descansos y pausas incluidos.
--
-- dungeon_overview: cuerpo de 017 + `missions_done` y `focus_minutes`.
-- end_dungeon: cuerpo de 012 + `missions` y `minutes` efectivos.

begin;

-- Recompensas de una sesión: ciclos (source 'dungeon') y misiones de su mochila
-- completadas desde que empezó (source 'task' o 'npc', ver complete_task 005).
create or replace function public._dungeon_loot(p_session_id uuid)
returns table (xp bigint, coins bigint, missions bigint)
language sql
stable
security invoker
set search_path = ''
as $$
  with s as (
    select * from public.focus_sessions where id = p_session_id
  ),
  q as (
    select q.xp_awarded, q.coin_awarded, q.source_type
    from public.quest_log_entries q, s
    where q.user_id = s.user_id
      and (
        (q.source_type = 'dungeon'
         and q.source_id in (select r.id from public.dungeon_runs r where r.session_id = s.id))
        or
        (q.source_type in ('task', 'npc')
         and q.result = 'completed'
         and q.occurred_at >= s.started_at
         and q.occurred_at <= coalesce(s.ended_at, now())
         and q.source_id in (select f.task_id from public.focus_session_tasks f
                             where f.session_id = s.id))
      )
  )
  select coalesce(sum(xp_awarded), 0),
         coalesce(sum(coin_awarded), 0),
         count(*) filter (where source_type in ('task', 'npc'))
  from q
$$;

-- 1. Datos de la pantalla Mazmorra ----------------------------------------------
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
        'xp_earned', l.xp,
        'coins_earned', l.coins,
        'missions_done', l.missions,
        'focus_minutes', (select count(*) from runs) * s.cycle_minutes,
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
      from s, public._dungeon_loot(s.id) l
    ),
    'candidates', coalesce((
      select jsonb_agg(jsonb_build_object('id', c.id, 'title', c.title, 'bucket', c.bucket)
                       order by c.bucket_order, c.due_date nulls last)
      from (select * from public.v_daily_highlight
            order by bucket_order, due_date nulls last limit 30) c
    ), '[]'::jsonb),
    'max_tasks', public.rule('dungeon_max_tasks')::integer,
    'cycle_xp', public.rule('dungeon_cycle_xp')::integer,
    -- RF-067: descansos que el jugador eligió en Configuración (016).
    'breaks', (
      select jsonb_build_object(
        'short_minutes', g.short_break_minutes,
        'long_minutes', g.long_break_minutes,
        'long_every_n_cycles', g.long_break_every_n_cycles
      )
      from public.game_master_settings g where g.user_id = auth.uid()
    )
  )
$$;

-- 2. Terminar la sesión con el botín completo -------------------------------------
create or replace function public.end_dungeon(p_session_id uuid)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_session public.focus_sessions;
  v_cycles integer;
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
  select count(*) into v_cycles from public.dungeon_runs where session_id = p_session_id;
  return (
    select jsonb_build_object(
      'cycles', v_cycles,
      'xp', l.xp,
      'coins', l.coins,
      'missions', l.missions,
      -- Tiempo efectivo: solo los ciclos de concentración cobrados.
      'minutes', v_cycles * v_session.cycle_minutes
    )
    from public._dungeon_loot(p_session_id) l
  );
end $$;

-- Permisos ---------------------------------------------------------------------
revoke all on function public._dungeon_loot(uuid) from public, anon;
grant execute on function public._dungeon_loot(uuid) to authenticated;
do $$
declare f text;
begin
  foreach f in array array['public.dungeon_overview()', 'public.end_dungeon(uuid)'] loop
    execute format('revoke all on function %s from public, anon', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;

commit;
