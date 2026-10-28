-- Migración 020 · Diario: la Bitácora (requiere 001–019).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- journal_overview(p_day): resumen de los últimos 7 días comparado con los 7
-- anteriores y las últimas 150 entradas de quest_log_entries (60 días) con el
-- nombre de lo que las produjo. Sin Diario del Héroe (CLAUDE.md §13).
-- source_id es polimórfico: el nombre se busca según source_type.

begin;

create or replace function public.journal_overview(p_day date)
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  with q as (
    select q.*, (q.occurred_at >= (p_day - 6)::timestamptz) as this_week
    from public.quest_log_entries q
    where q.occurred_at >= (p_day - 13)::timestamptz
      and q.occurred_at < (p_day + 1)::timestamptz
  ),
  week as (
    select this_week,
           sum(xp_awarded) as xp,
           count(*) filter (where result = 'completed'
                            and source_type::text in ('task', 'npc', 'project')) as missions,
           count(*) filter (where source_type::text = 'dungeon') as cycles
    from q group by this_week
  )
  select jsonb_build_object(
    'summary', jsonb_build_object(
      'xp', coalesce((select xp from week where this_week), 0),
      'xp_prev', coalesce((select xp from week where not this_week), 0),
      'missions', coalesce((select missions from week where this_week), 0),
      'missions_prev', coalesce((select missions from week where not this_week), 0),
      'cycles', coalesce((select cycles from week where this_week), 0),
      'cycles_prev', coalesce((select cycles from week where not this_week), 0),
      'best_streak', coalesce((select max(current_streak) from public.habits where type = 'good'), 0)
    ),
    'entries', coalesce((
      select jsonb_agg(e order by e->>'occurred_at' desc)
      from (
        select jsonb_build_object(
          'id', l.id,
          'source', l.source_type,
          'result', l.result,
          'xp', l.xp_awarded,
          'coins', l.coin_awarded,
          'hp', l.hp_change,
          'occurred_at', l.occurred_at,
          'title', case l.source_type::text
            when 'task' then (select title from public.tasks where id = l.source_id)
            when 'npc' then (select title from public.tasks where id = l.source_id)
            when 'project' then (select title from public.projects where id = l.source_id)
            when 'goal' then (select title from public.goals where id = l.source_id)
            when 'habit' then (select name from public.habits where id = l.source_id)
            when 'dungeon' then (select t.title from public.dungeon_runs r
                                 join public.tasks t on t.id = r.task_id where r.id = l.source_id)
            when 'achievement' then (select name from public.achievements where id = l.source_id)
            else null end
        ) as e
        from public.quest_log_entries l
        where l.occurred_at >= (p_day - 59)::timestamptz
        order by l.occurred_at desc
        limit 150
      ) x
    ), '[]'::jsonb)
  )
$$;

revoke all on function public.journal_overview(date) from public, anon;
grant execute on function public.journal_overview(date) to authenticated;

commit;
