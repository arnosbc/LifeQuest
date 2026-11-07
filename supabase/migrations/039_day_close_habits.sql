-- Migración 039 · Cierre del día y hábitos con versión mínima (rework, mejoras).
-- Requiere 001–038. Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
--   · postpone_task acepta p_days (1 = mañana, por defecto 7 como la revisión
--     semanal): el cierre del día manda lo pendiente a mañana.
--   · habits.min_version: la versión de 2 minutos de un hábito bueno («leer 1
--     página»). Marcar el hábito cuenta igual; el texto invita a no saltarlo.
--     create_habit la acepta y habits_overview la devuelve.

begin;

-- 1. Posponer N días -----------------------------------------------------------------
drop function if exists public.postpone_task(uuid);
create or replace function public.postpone_task(p_task_id uuid, p_days integer default 7)
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
  if p_days is null or p_days not between 1 and 30 then
    raise exception 'invalid_days' using errcode = '22023';
  end if;
  update public.tasks
  set due_date = greatest(coalesce(due_date, now()), now()) + make_interval(days => p_days),
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

-- 2. Versión mínima de un hábito -----------------------------------------------------
alter table public.habits add column if not exists min_version text;
-- Texto del usuario, no economía: se puede escribir como el resto del hábito (003).
grant insert (min_version), update (min_version) on public.habits to authenticated;

-- Cuerpo de 011 más p_min_version.
drop function if exists public.create_habit(text, public.habit_type, public.habit_frequency, integer[], integer, uuid);
create or replace function public.create_habit(
  p_name text,
  p_type public.habit_type,
  p_frequency public.habit_frequency default 'daily',
  p_specific_days integer[] default null,
  p_hp_penalty integer default 0,
  p_skill_id uuid default null,
  p_min_version text default null
)
returns uuid
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_name text := trim(coalesce(p_name, ''));
  v_min text := nullif(trim(coalesce(p_min_version, '')), '');
  v_days integer[];
  v_id uuid;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  if v_name = '' or length(v_name) > 100 then
    raise exception 'invalid_name' using errcode = '22023';
  end if;
  if length(v_min) > 100 or (v_min is not null and p_type = 'bad') then
    raise exception 'invalid_min_version' using errcode = '22023';
  end if;
  if p_type = 'bad' and coalesce(p_hp_penalty, 0) not in (3, 5, 8) then
    raise exception 'invalid_severity' using errcode = '22023';
  end if;
  if p_type = 'good' and p_frequency = 'specific_days' then
    select array_agg(distinct d order by d) into v_days
    from unnest(coalesce(p_specific_days, '{}')) d;
    if v_days is null or exists (select 1 from unnest(v_days) d where d not between 0 and 6) then
      raise exception 'invalid_days' using errcode = '22023';
    end if;
  end if;
  if p_skill_id is not null
     and not exists (select 1 from public.skills where id = p_skill_id and user_id = v_uid) then
    raise exception 'skill_not_found' using errcode = 'P0002';
  end if;

  insert into public.habits (user_id, skill_id, name, type, frequency, specific_days, hp_penalty, min_version)
  values (v_uid, p_skill_id, v_name, p_type,
          case when v_days is null then 'daily'::public.habit_frequency else 'specific_days' end,
          v_days, case when p_type = 'bad' then p_hp_penalty else 0 end, v_min)
  returning id into v_id;
  return v_id;
end $$;

-- Cuerpo de 034 más min_version.
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
        'min_version', h.min_version,
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

-- Permisos ----------------------------------------------------------------------------
do $$
declare f text;
begin
  foreach f in array array[
    'public.postpone_task(uuid, integer)', 'public.habits_overview(date)',
    'public.create_habit(text, public.habit_type, public.habit_frequency, integer[], integer, uuid, text)'] loop
    execute format('revoke all on function %s from public, anon', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;

commit;
