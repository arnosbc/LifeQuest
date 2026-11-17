-- Migración 051 · Prioridad de hábitos y Camino (requiere 011, 003 y 042).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
--   1. habits.priority: urgency_level, la única escala de la app (§6), por
--      defecto 'medium'.
--   2. create_habit(..., p_priority): guarda la prioridad al crear.
--   3. habits_overview: devuelve 'priority' de cada hábito. El resto es la
--      misma copia de 042. El Camino de la app ordena por prioridad.

begin;

alter table public.habits
  add column if not exists priority public.urgency_level not null default 'medium';

grant insert (priority), update (priority) on public.habits to authenticated;

-- 2. create_habit con prioridad -------------------------------------------------
drop function if exists public.create_habit(text, public.habit_type, public.habit_frequency, integer[], integer, uuid);

create or replace function public.create_habit(
  p_name text,
  p_type public.habit_type,
  p_frequency public.habit_frequency default 'daily',
  p_specific_days integer[] default null,
  p_hp_penalty integer default 0,
  p_skill_id uuid default null,
  p_priority public.urgency_level default 'medium'
)
returns uuid
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_name text := trim(coalesce(p_name, ''));
  v_days integer[];
  v_id uuid;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  if v_name = '' or length(v_name) > 100 then
    raise exception 'invalid_name' using errcode = '22023';
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

  insert into public.habits (user_id, skill_id, name, type, frequency, specific_days, hp_penalty, priority)
  values (v_uid, p_skill_id, v_name, p_type,
          case when v_days is null then 'daily'::public.habit_frequency else 'specific_days' end,
          v_days, case when p_type = 'bad' then p_hp_penalty else 0 end,
          coalesce(p_priority, 'medium'))
  returning id into v_id;
  return v_id;
end $$;
revoke all on function public.create_habit(text, public.habit_type, public.habit_frequency, integer[], integer, uuid, public.urgency_level) from public, anon;
grant execute on function public.create_habit(text, public.habit_type, public.habit_frequency, integer[], integer, uuid, public.urgency_level) to authenticated;

-- 3. habits_overview con prioridad ---------------------------------------------
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
        'priority', h.priority,
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
    -- 042: Estadísticas de crecimiento y mapa de calor de Habitos.dc.html.
    'month_heat', coalesce((
      select jsonb_object_agg(d, n) from (
        select extract(day from r.completed_on)::int as d, count(*) as n
        from public.habit_records r join h on h.id = r.habit_id
        where h.type = 'good'
          and r.completed_on >= date_trunc('month', p_day)::date and r.completed_on <= p_day
        group by 1) x
    ), '{}'::jsonb),
    'month_done', (
      select count(*) from public.habit_records r join h on h.id = r.habit_id
      where h.type = 'good'
        and r.completed_on >= date_trunc('month', p_day)::date and r.completed_on <= p_day
    ),
    'year_done', (
      select count(*) from public.habit_records r join h on h.id = r.habit_id
      where h.type = 'good'
        and r.completed_on >= date_trunc('year', p_day)::date and r.completed_on <= p_day
    ),
    'skills', coalesce((
      select jsonb_agg(jsonb_build_object('id', id, 'name', name) order by created_at)
      from public.skills
    ), '[]'::jsonb)
  )
$$;
revoke all on function public.habits_overview(date) from public, anon;
grant execute on function public.habits_overview(date) to authenticated;

commit;
