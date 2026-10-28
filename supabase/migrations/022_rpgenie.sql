-- Migración 022 · RPGenie v1: Misión actual por reglas (requiere 001–021).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- current_mission(p_skip): la tarea abierta (sin subtareas) que toca ahora,
-- según RF-097: crítica (vence en < 24 h o ya venció) → prioridad alta >
-- media > baja → fecha límite más próxima → la más antigua. p_skip son las
-- que el usuario apartó con "Ahora no" (sin castigo; la app las recuerda
-- mientras dure la sesión). Completarla es complete_task (005).
-- La propuesta del cierre del diseño (§13: daño a jefes, "estoy cansado")
-- sigue abierta (CLAUDE.md §11): no se aplica todavía.

begin;

create or replace function public.current_mission(p_skip uuid[] default '{}')
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  with cand as (
    select t.*, t.due_date is not null and t.due_date < now() + interval '24 hours' as critical
    from public.tasks t
    where t.parent_task_id is null
      and t.status in ('pending', 'in_progress')
  ),
  pick as (
    select o.* from cand o
    where not (o.id = any (coalesce(p_skip, '{}')))
    order by o.critical desc,
             case o.priority when 'high' then 0 when 'medium' then 1 else 2 end,
             o.due_date nulls last, o.created_at
    limit 1
  )
  select jsonb_build_object(
    'mission', (
      select jsonb_build_object(
        'id', p.id,
        'title', p.title,
        'priority', p.priority,
        'due_date', p.due_date,
        'xp_reward', p.xp_reward,
        'coin_reward', p.coin_reward,
        'skill_name', s.name,
        'goal_title', g.title,
        'project_title', pr.title,
        'reason', case when p.critical then 'critical'
                       when p.priority = 'high' then 'high'
                       when p.due_date is not null then 'due'
                       else 'next' end)
      from pick p
      left join public.skills s on s.id = p.skill_id
      left join public.goals g on g.id = p.goal_id
      left join public.projects pr on pr.id = p.project_id),
    'open_count', (select count(*) from cand),
    'skipped_count', (select count(*) from cand where id = any (coalesce(p_skip, '{}')))
  )
$$;

revoke all on function public.current_mission(uuid[]) from public, anon;
grant execute on function public.current_mission(uuid[]) to authenticated;

commit;
