-- Migración 042 · Estadísticas de crecimiento de Hábitos (requiere 001–041).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- habits_overview (011) devuelve además, para Habitos.dc.html:
--   month_heat  {día: registros de hábitos buenos} del mes (mapa de calor);
--   month_done  registros de hábitos buenos del mes;
--   year_done   registros de hábitos buenos del año.
-- El resto de la función es la misma copia de 011.

begin;

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
