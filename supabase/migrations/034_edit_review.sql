-- Migración 034 · Editar y revisar (mejoras tras el rework, docs/plan-rework.md).
-- Requiere 001–033. Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- 1. update_task: editar una tarea abierta (título, prioridad, fecha, agenda,
--    aviso y repetición). No recalcula la recompensa (RF-112: editar no sube XP).
-- 2. set_habit_reminder y habits_overview con reminder_time.
-- 3. Revisión semanal: weekly_review (lo hecho y lo pendiente de la semana) y
--    postpone_task (pasar una tarea a la semana siguiente).

begin;

-- 1. Editar tarea --------------------------------------------------------------------
-- security invoker: el update pasa por el RLS y los grants de columna (003, 032);
-- los checks de 032 validan duración, aviso y formato de repetición.
create or replace function public.update_task(
  p_task_id uuid,
  p_title text,
  p_priority public.urgency_level default 'low',
  p_due_date timestamptz default null,
  p_scheduled_at timestamptz default null,
  p_estimated_minutes integer default null,
  p_reminder_minutes integer default null,
  p_repeat_rule text default null,
  p_description text default null
)
returns void
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_title text := trim(coalesce(p_title, ''));
begin
  if auth.uid() is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  if v_title = '' or length(v_title) > 200 then
    raise exception 'invalid_title' using errcode = '22023';
  end if;
  update public.tasks
  set title = v_title,
      description = nullif(trim(coalesce(p_description, '')), ''),
      priority = coalesce(p_priority, 'low'),
      due_date = p_due_date,
      scheduled_at = p_scheduled_at,
      estimated_minutes = p_estimated_minutes,
      -- Sin hora no hay aviso.
      reminder_minutes = case when p_scheduled_at is null then null else p_reminder_minutes end,
      repeat_rule = nullif(trim(coalesce(p_repeat_rule, '')), '')
  where id = p_task_id and user_id = auth.uid()
    and status in ('pending', 'in_progress', 'delegated');
  if not found then
    raise exception 'task_not_found' using errcode = 'P0002';
  end if;
end $$;

-- 2. Aviso de hábitos -----------------------------------------------------------------
-- Solo hábitos buenos: el aviso invita a cumplirlo. p_time null lo quita.
create or replace function public.set_habit_reminder(p_habit_id uuid, p_time time)
returns void
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  update public.habits set reminder_time = p_time
  where id = p_habit_id and user_id = auth.uid() and type = 'good';
  if not found then
    raise exception 'habit_not_found' using errcode = 'P0002';
  end if;
end $$;

-- Cuerpo de 011 más reminder_time.
create or replace function public.habits_overview(p_day date)
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  with week as (
    select generate_series(p_day - 6, p_day, interval '1 day')::date as day
  ),
  h as (
    select h.*,
           h.frequency = 'daily' or extract(dow from p_day)::int = any (h.specific_days) as scheduled_today
    from public.habits h
  ),
  -- Días de la semana en que tocaba cada hábito bueno (desde que existe).
  scheduled as (
    select h.id, w.day
    from h cross join week w
    where h.type = 'good' and w.day >= h.created_at::date
      and (h.frequency = 'daily' or extract(dow from w.day)::int = any (h.specific_days))
  )
  select jsonb_build_object(
    'habits', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', h.id,
        'name', h.name,
        'type', h.type,
        'frequency', h.frequency,
        'specific_days', coalesce(to_jsonb(h.specific_days), '[]'::jsonb),
        'skill_name', s.name,
        'hp_penalty', h.hp_penalty,
        'current_streak', coalesce(h.current_streak, 0),
        'best_streak', coalesce(h.best_streak, 0),
        'scheduled_today', h.scheduled_today,
        'done_today', exists (select 1 from public.habit_records r
                              where r.habit_id = h.id and r.completed_on = p_day),
        'today_count', (select count(*) from public.habit_records r
                        where r.habit_id = h.id and r.completed_on = p_day),
        'reminder_time', to_char(h.reminder_time, 'HH24:MI'),
        'week', (select jsonb_agg(exists (select 1 from public.habit_records r
                                          where r.habit_id = h.id and r.completed_on = w.day)
                                  order by w.day)
                 from week w)
      ) order by h.type, h.created_at)
      from h left join public.skills s on s.id = h.skill_id
    ), '[]'::jsonb),
    'week_xp', (
      select coalesce(sum(q.xp_awarded), 0) from public.quest_log_entries q
      where q.source_type = 'habit' and q.occurred_at >= (p_day - 6)::timestamptz
    ),
    'week_done', (
      select count(*) from scheduled sc
      where exists (select 1 from public.habit_records r
                    where r.habit_id = sc.id and r.completed_on = sc.day)
    ),
    'week_scheduled', (select count(*) from scheduled),
    'bad_free_days', (
      select count(*) from week w
      where not exists (select 1 from public.habit_records r join h on h.id = r.habit_id
                        where h.type = 'bad' and r.completed_on = w.day)
    ),
    'month_days', coalesce((
      select jsonb_agg(distinct extract(day from r.completed_on)::int)
      from public.habit_records r join h on h.id = r.habit_id
      where h.type = 'good'
        and r.completed_on >= date_trunc('month', p_day)::date and r.completed_on <= p_day
    ), '[]'::jsonb),
    'skills', coalesce((
      select jsonb_agg(jsonb_build_object('id', id, 'name', name) order by created_at)
      from public.skills
    ), '[]'::jsonb)
  )
$$;

-- 3. Revisión semanal --------------------------------------------------------------
-- security invoker. La semana va de lunes a domingo y contiene p_day (día local);
-- p_utc_offset_minutes la convierte a instantes como home_dashboard (001).
-- pending: tareas abiertas (sin subtareas) con fecha límite antes del fin de la
-- semana, vencidas incluidas: lo que conviene decidir.
create or replace function public.weekly_review(
  p_day date,
  p_utc_offset_minutes integer default 0
)
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  with week as (
    select start_at, start_at + interval '7 days' as end_at
    from (select ((p_day - (extract(isodow from p_day)::int - 1))::timestamp
                  - make_interval(mins => p_utc_offset_minutes)) at time zone 'UTC' as start_at) s
  )
  select jsonb_build_object(
    'week_start', (p_day - (extract(isodow from p_day)::int - 1)),
    'done', (
      select count(*) from public.tasks t, week
      where t.user_id = auth.uid() and t.parent_task_id is null and t.status = 'completed'
        and t.completed_at >= week.start_at and t.completed_at < week.end_at
    ),
    'focus_minutes', (
      select coalesce(sum(least(f.total_minutes,
        floor(extract(epoch from coalesce(f.ended_at, now()) - f.started_at) / 60)::int)), 0)
      from public.focus_sessions f, week
      where f.user_id = auth.uid() and f.started_at >= week.start_at and f.started_at < week.end_at
    ),
    'habit_days', (
      select count(*) from public.habit_records r, week
      where r.user_id = auth.uid()
        and r.completed_on >= (p_day - (extract(isodow from p_day)::int - 1))
        and r.completed_on < (p_day - (extract(isodow from p_day)::int - 1)) + 7
    ),
    'pending', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', t.id, 'title', t.title, 'due_date', t.due_date, 'priority', t.priority,
        'repeat_rule', t.repeat_rule) order by t.due_date, t.created_at)
      from public.tasks t, week
      where t.user_id = auth.uid() and t.parent_task_id is null
        and t.status in ('pending', 'in_progress')
        and t.due_date < week.end_at
    ), '[]'::jsonb)
  )
$$;

-- Una semana más: desde la fecha límite o desde ahora si ya venció. El bloque
-- de agenda se quita (ya no corresponde) y se vuelve a poner desde Hoy.
create or replace function public.postpone_task(p_task_id uuid)
returns timestamptz
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_due timestamptz;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  update public.tasks
  set due_date = greatest(coalesce(due_date, now()), now()) + interval '7 days',
      scheduled_at = null,
      reminder_minutes = null
  where id = p_task_id and user_id = auth.uid()
    and status in ('pending', 'in_progress', 'delegated')
  returning due_date into v_due;
  if not found then
    raise exception 'task_not_found' using errcode = 'P0002';
  end if;
  return v_due;
end $$;

-- Permisos ----------------------------------------------------------------------------
do $$
declare f text;
begin
  foreach f in array array[
    'public.update_task(uuid, text, public.urgency_level, timestamptz, timestamptz, integer, integer, text, text)',
    'public.set_habit_reminder(uuid, time)', 'public.habits_overview(date)',
    'public.weekly_review(date, integer)', 'public.postpone_task(uuid)'] loop
    execute format('revoke all on function %s from public, anon', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;

commit;
