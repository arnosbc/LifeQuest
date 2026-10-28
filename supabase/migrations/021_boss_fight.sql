-- Migración 021 · Objetivos: Boss Fight (requiere 001–020).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- goals_overview(): cada Meta sin archivar como un jefe, con su vida, su
-- ficha S.M.A.R.T., los ataques disponibles (tareas y proyectos abiertos
-- vinculados, con su daño) y los últimos golpes. Atacar es complete_task o
-- complete_project (005/008); el daño lo pone _damage_boss. Archivar es
-- archive_item('goal', id) (014). Estado único: objective_status (RF-084).

begin;

create or replace function public.goals_overview()
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  select jsonb_build_object(
    'goals', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', g.id,
        'title', g.title,
        'status', g.status,
        'due_date', g.due_date,
        'skill_name', s.name,
        'boss_max_hp', g.boss_max_hp,
        'boss_current_hp', g.boss_current_hp,
        'smart', jsonb_build_object(
          'specific', g.smart_specific, 'measurable', g.smart_measurable,
          'achievable', g.smart_achievable, 'relevant', g.smart_relevant,
          'timebound', g.smart_timebound),
        'attacks', coalesce((
          select jsonb_agg(a order by a->>'kind' desc, a->>'title')
          from (
            select jsonb_build_object('kind', 'task', 'id', t.id, 'title', t.title,
                                      'damage', t.xp_reward) a
            from public.tasks t
            where t.goal_id = g.id and t.parent_task_id is null
              and t.status in ('pending', 'in_progress', 'delegated')
            union all
            select jsonb_build_object('kind', 'project', 'id', p.id, 'title', p.title,
                                      'damage', public.rule('boss_damage_project'))
            from public.projects p
            where p.goal_id = g.id and p.archived_at is null
              and p.status in ('not_started', 'in_progress')
          ) x
        ), '[]'::jsonb),
        'hits', coalesce((
          select jsonb_agg(jsonb_build_object('title', y.title, 'damage', y.damage, 'at', y.at)
                           order by y.at desc)
          from (
            select t.title, t.xp_reward::numeric as damage, t.completed_at as at
            from public.tasks t
            where t.goal_id = g.id and t.status = 'completed'
            union all
            select p.title, public.rule('boss_damage_project'), q.occurred_at
            from public.projects p
            join public.quest_log_entries q
              on q.source_id = p.id and q.source_type = 'project' and q.result = 'completed'
            where p.goal_id = g.id
            order by at desc
            limit 5
          ) y
        ), '[]'::jsonb)
      ) order by case when g.status in ('not_started', 'in_progress') then 0 else 1 end,
                 g.due_date nulls last, g.created_at)
      from public.goals g left join public.skills s on s.id = g.skill_id
      where g.archived_at is null
    ), '[]'::jsonb),
    'victory_xp', public.rule('boss_victory_xp'),
    'victory_coins', public.rule('boss_victory_coins')
  )
$$;

revoke all on function public.goals_overview() from public, anon;
grant execute on function public.goals_overview() to authenticated;

commit;
