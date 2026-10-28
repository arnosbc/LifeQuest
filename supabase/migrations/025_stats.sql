-- Migración 025 · Estadísticas (requiere 001–024).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- stats_overview(p_day): últimos 7 días frente a los 7 anteriores (XP,
-- misiones, minutos de Mazmorra, mejor racha), XP por día, XP por Área
-- (skill) y los hábitos buenos más constantes de los últimos 30 días.
-- Las 3 observaciones de RPGenie (CLAUDE.md §13) se arman en la app con
-- estos números. Pantalla de lectura: no guarda datos propios.

begin;

create or replace function public.stats_overview(p_day date)
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  with q as (
    select q.*, q.occurred_at >= (p_day - 6)::timestamptz as this_week,
           (q.occurred_at at time zone 'UTC')::date as day
    from public.quest_log_entries q
    where q.occurred_at >= (p_day - 13)::timestamptz
      and q.occurred_at < (p_day + 1)::timestamptz
  ),
  runs as (
    select r.ended_at >= (p_day - 6)::timestamptz as this_week, s.cycle_minutes
    from public.dungeon_runs r join public.focus_sessions s on s.id = r.session_id
    where r.completed and r.ended_at >= (p_day - 13)::timestamptz
      and r.ended_at < (p_day + 1)::timestamptz
  )
  select jsonb_build_object(
    'xp', coalesce((select sum(xp_awarded) from q where this_week), 0),
    'xp_prev', coalesce((select sum(xp_awarded) from q where not this_week), 0),
    'missions', (select count(*) from q where this_week and result = 'completed'
                 and source_type::text in ('task', 'npc', 'project')),
    'missions_prev', (select count(*) from q where not this_week and result = 'completed'
                      and source_type::text in ('task', 'npc', 'project')),
    'focus_minutes', coalesce((select sum(cycle_minutes) from runs where this_week), 0),
    'focus_minutes_prev', coalesce((select sum(cycle_minutes) from runs where not this_week), 0),
    'best_streak', coalesce((select max(current_streak) from public.habits where type = 'good'), 0),
    'record_streak', coalesce((select max(best_streak) from public.habits where type = 'good'), 0),
    'xp_by_day', (
      select jsonb_agg(jsonb_build_object('day', d,
               'xp', coalesce((select sum(xp_awarded) from q where q.day = d), 0)) order by d)
      from (select g::date as d from generate_series(p_day - 6, p_day, interval '1 day') g) days
    ),
    'xp_by_skill', coalesce((
      select jsonb_agg(jsonb_build_object('name', s.name, 'xp', t.xp) order by t.xp desc)
      from (select skill_id, sum(xp_awarded) xp from q
            where this_week and skill_id is not null group by skill_id) t
      join public.skills s on s.id = t.skill_id
      where t.xp > 0
    ), '[]'::jsonb),
    'top_habits', coalesce((
      select jsonb_agg(jsonb_build_object('name', name, 'days', days, 'streak', current_streak)
                       order by days desc, name)
      from (
        select h.name, h.current_streak, count(r.id) days
        from public.habits h
        join public.habit_records r on r.habit_id = h.id
          and r.completed_on > p_day - 30 and r.completed_on <= p_day
        where h.type = 'good'
        group by h.id
        order by days desc
        limit 3
      ) t
    ), '[]'::jsonb)
  )
$$;

revoke all on function public.stats_overview(date) from public, anon;
grant execute on function public.stats_overview(date) to authenticated;

commit;
