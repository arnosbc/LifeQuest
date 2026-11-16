-- Migración 068 · Foco unificado: tiempo según la tarea, pasos dentro de Foco
-- y hábitos en la sesión (idea del usuario, 2026-11-16). Requiere 033, 039, 066.
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- 1. task_steps.minutes: Nevi estima cuánto toma cada paso (set_step_minutes).
-- 2. focus_session_habits: hábitos buenos de hoy dentro de la sesión.
-- 3. dungeon_runs.habit_id: un bloque puede ser de un hábito (sin tarea).
-- 4. start_dungeon y complete_dungeon_cycle aceptan hábitos (parámetros con
--    default: la app anterior las sigue llamando igual).
-- 5. dungeon_overview trae minutos estimados, el paso actual de cada tarea y
--    los hábitos (de la sesión y candidatos de hoy).

begin;

-- 1. Minutos por paso -------------------------------------------------------------
alter table public.task_steps add column if not exists minutes smallint
  check (minutes between 1 and 240);

-- Los pasos pendientes, en orden, reciben los minutos en el mismo orden.
create or replace function public.set_step_minutes(p_task_id uuid, p_minutes integer[])
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  update public.task_steps s set minutes = least(greatest(m.v, 1), 240)
  from (select id, row_number() over (order by position) as n
        from public.task_steps
        where task_id = p_task_id and user_id = auth.uid() and paid_at is null) p
  join unnest(p_minutes) with ordinality as m(v, n) on m.n = p.n
  where s.id = p.id and m.v is not null;
end $$;

-- 2. Hábitos en la sesión ---------------------------------------------------------
create table if not exists public.focus_session_habits (
  session_id uuid not null references public.focus_sessions (id) on delete cascade,
  habit_id uuid not null references public.habits (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  primary key (session_id, habit_id)
);
alter table public.focus_session_habits enable row level security;
drop policy if exists focus_session_habits_select_own on public.focus_session_habits;
create policy focus_session_habits_select_own on public.focus_session_habits
  for select using (user_id = auth.uid());
revoke all on public.focus_session_habits from anon, authenticated;
grant select on public.focus_session_habits to authenticated;

-- 3. Bloques de un hábito ---------------------------------------------------------
alter table public.dungeon_runs alter column task_id drop not null;
alter table public.dungeon_runs add column if not exists habit_id uuid
  references public.habits (id) on delete set null;

-- 4a. Empezar con tareas y/o hábitos ----------------------------------------------
drop function if exists public.start_dungeon(integer, integer, uuid[]);
create or replace function public.start_dungeon(
  p_total_minutes integer,
  p_cycle_minutes integer,
  p_task_ids uuid[],
  p_habit_ids uuid[] default null
)
returns uuid
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_tasks uuid[];
  v_habits uuid[];
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
  select array_agg(distinct x) into v_habits from unnest(coalesce(p_habit_ids, '{}')) x;
  if v_tasks is null and v_habits is null then
    raise exception 'no_tasks' using errcode = '22023';
  end if;
  if coalesce(cardinality(v_tasks), 0) + coalesce(cardinality(v_habits), 0)
     > public.rule('dungeon_max_tasks') then
    raise exception 'session_task_limit' using errcode = 'P0001';
  end if;
  if v_tasks is not null and (select count(*) from public.tasks
      where id = any (v_tasks) and user_id = v_uid
        and status in ('pending', 'in_progress', 'delegated')) <> cardinality(v_tasks) then
    raise exception 'task_not_found' using errcode = 'P0002';
  end if;
  if v_habits is not null and (select count(*) from public.habits
      where id = any (v_habits) and user_id = v_uid and type = 'good') <> cardinality(v_habits) then
    raise exception 'habit_not_found' using errcode = 'P0002';
  end if;

  insert into public.focus_sessions (user_id, total_minutes, cycle_minutes)
  values (v_uid, p_total_minutes, p_cycle_minutes)
  returning id into v_session;
  if v_tasks is not null then
    insert into public.focus_session_tasks (session_id, task_id)
    select v_session, unnest(v_tasks);
  end if;
  -- La tabla no tiene grant de insert: lo hace una función definer aparte.
  perform public._add_session_habits(v_session, v_habits);
  return v_session;
end $$;

create or replace function public._add_session_habits(p_session_id uuid, p_habits uuid[])
returns void
language sql
security definer
set search_path = ''
as $$
  insert into public.focus_session_habits (session_id, habit_id, user_id)
  select s.id, h.id, s.user_id
  from public.focus_sessions s
  join public.habits h on h.user_id = s.user_id and h.type = 'good'
  where s.id = p_session_id and s.user_id = auth.uid()
    and h.id = any (coalesce(p_habits, '{}'))
  on conflict do nothing;
$$;
-- start_dungeon (invoker) la llama como el usuario; solo inserta en su sesión
-- y con sus hábitos buenos.
revoke all on function public._add_session_habits(uuid, uuid[]) from public, anon;
grant execute on function public._add_session_habits(uuid, uuid[]) to authenticated;

-- 4b. Cobrar un bloque de una tarea o de un hábito (cuerpo de 008) -----------------
drop function if exists public.complete_dungeon_cycle(uuid, uuid);
create or replace function public.complete_dungeon_cycle(
  p_session_id uuid,
  p_task_id uuid default null,
  p_habit_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_session public.focus_sessions;
  v_skill uuid;
  v_cycle integer;
  v_run uuid;
  v_xp numeric;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  select * into v_session from public.focus_sessions
  where id = p_session_id and user_id = v_uid for update;
  if not found then
    raise exception 'session_not_found' using errcode = 'P0002';
  end if;
  if v_session.status not in ('active', 'paused') then
    raise exception 'session_not_active' using errcode = '22023';
  end if;
  if p_task_id is not null then
    if not exists (select 1 from public.focus_session_tasks
                   where session_id = p_session_id and task_id = p_task_id) then
      raise exception 'task_not_in_session' using errcode = '22023';
    end if;
  elsif p_habit_id is null or not exists (select 1 from public.focus_session_habits
                   where session_id = p_session_id and habit_id = p_habit_id) then
    raise exception 'task_not_in_session' using errcode = '22023';
  end if;
  -- Un ciclo no puede durar menos que su duración desde el inicio de la sesión.
  select count(*) + 1 into v_cycle from public.dungeon_runs where session_id = p_session_id;
  if v_cycle > floor(v_session.total_minutes::numeric / v_session.cycle_minutes) then
    raise exception 'session_cycles_exhausted' using errcode = '22023';
  end if;
  if now() < v_session.started_at + make_interval(mins => v_session.cycle_minutes * v_cycle) then
    raise exception 'cycle_not_finished' using errcode = '22023';
  end if;

  update public.user_consumables
  set status = 'used', used_at = now(), session_id = p_session_id
  where user_id = v_uid and kind = 'elixir' and status = 'active';

  v_xp := public.rule('dungeon_cycle_xp')
          * case when exists (select 1 from public.user_consumables
                              where session_id = p_session_id and kind = 'elixir')
                 then public.rule('elixir_xp_factor') else 1 end;
  select coalesce((select skill_id from public.tasks where id = p_task_id),
                  (select skill_id from public.habits where id = p_habit_id))
  into v_skill;

  insert into public.dungeon_runs (session_id, task_id, habit_id, cycle_number, completed, ended_at)
  values (p_session_id, p_task_id, case when p_task_id is null then p_habit_id end,
          v_cycle, true, now())
  returning id into v_run;
  return public._award(v_uid, 'dungeon', v_run, floor(v_xp)::integer,
    round(public.rule('dungeon_cycle_xp') * public.rule('coin_ratio'))::integer, v_skill)
    || jsonb_build_object('cycle', v_cycle);
end $$;

-- 5. El tablero de Foco (cuerpo de 033 + minutos, paso actual y hábitos) ------------
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
  ),
  today as (select (now() at time zone 'America/Bogota')::date as d),
  -- Por tarea: minutos de lo que falta (null si Nevi no los estimó) y el paso actual.
  steps as (
    select ts.task_id,
           count(*) filter (where ts.done_at is null) as pending,
           count(*) as total,
           sum(ts.minutes) filter (where ts.done_at is null) as minutes,
           (array_agg(jsonb_build_object('id', ts.id, 'title', ts.title,
                      'position', ts.position, 'minutes', ts.minutes)
                      order by ts.position) filter (where ts.done_at is null))[1] as current
    from public.task_steps ts where ts.user_id = auth.uid()
    group by ts.task_id
  ),
  hab as (
    select h.id, h.name,
           exists (select 1 from public.habit_records r, today
                   where r.habit_id = h.id and r.completed_on = today.d) as done
    from public.habits h, today
    where h.user_id = auth.uid() and h.type = 'good'
      and (h.frequency = 'daily' or extract(dow from today.d)::int = any (h.specific_days))
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
            'cycles', (select count(*) from runs where runs.task_id = t.id),
            'minutes', st.minutes,
            'step_count', coalesce(st.total, 0),
            'step', case when t.status = 'completed' then null else st.current end
          ) order by t.created_at)
          from public.focus_session_tasks f join public.tasks t on t.id = f.task_id
          left join steps st on st.task_id = t.id
          where f.session_id = s.id
        ), '[]'::jsonb),
        'habits', coalesce((
          select jsonb_agg(jsonb_build_object(
            'id', h.id,
            'title', h.name,
            'done', exists (select 1 from public.habit_records r, today
                            where r.habit_id = h.id and r.completed_on = today.d),
            'cycles', (select count(*) from runs where runs.habit_id = h.id)
          ) order by h.created_at)
          from public.focus_session_habits fh join public.habits h on h.id = fh.habit_id
          where fh.session_id = s.id
        ), '[]'::jsonb)
      )
      from s, public._dungeon_loot(s.id) l
    ),
    'candidates', coalesce((
      select jsonb_agg(jsonb_build_object('id', c.id, 'title', c.title, 'bucket', c.bucket,
                                          'minutes', st.minutes,
                                          'step_count', coalesce(st.pending, 0))
                       order by c.bucket_order, c.due_date nulls last)
      from (select * from public.v_daily_highlight
            order by bucket_order, due_date nulls last limit 30) c
      left join steps st on st.task_id = c.id
    ), '[]'::jsonb),
    -- Hábitos buenos que tocan hoy y aún no se cumplen.
    'habit_candidates', coalesce((
      select jsonb_agg(jsonb_build_object('id', hab.id, 'title', hab.name) order by hab.name)
      from hab where not hab.done
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

-- Permisos ---------------------------------------------------------------------
do $$
declare f text;
begin
  foreach f in array array['public.dungeon_overview()',
    'public.start_dungeon(integer, integer, uuid[], uuid[])',
    'public.complete_dungeon_cycle(uuid, uuid, uuid)',
    'public.set_step_minutes(uuid, integer[])'] loop
    execute format('revoke all on function %s from public, anon', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;

commit;

notify pgrst, 'reload schema';
