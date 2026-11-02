-- Migración 038 · Lista «Hoy» en el Inicio (requiere 001–037).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- Plan: docs/plan-funcionalidades-asistente.md S2 (Inicio = Hoy).
-- home_dashboard (001) devuelve además today_tasks: hasta 6 tareas abiertas
-- (sin subtareas) que vencen hoy, ya vencieron o tienen prioridad alta. El
-- resto de la función es la misma copia de 001. Completar una sigue siendo
-- complete_task (005), que paga en el servidor.

begin;

create or replace function public.home_dashboard(
  p_day date,
  p_utc_offset_minutes integer default 0
)
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  with day as (
    select start_at, start_at + interval '1 day' as end_at
    from (
      select (p_day::timestamp - make_interval(mins => p_utc_offset_minutes))
             at time zone 'UTC' as start_at
    ) s
  ),
  today_habits as (
    select h.id, h.name, h.current_streak, h.created_at,
           exists (
             select 1 from public.habit_records r
             where r.habit_id = h.id and r.completed_on = p_day
           ) as done
    from public.habits h
    where h.user_id = auth.uid()
      and h.type = 'good'
      and (h.frequency = 'daily'
           or extract(dow from p_day)::int = any (h.specific_days))
  )
  select jsonb_build_object(
    'display_name', p.display_name,
    'character_class', p.character_class,
    'level', s.level,
    'current_xp', s.current_xp,
    'xp_to_next_level', s.xp_to_next_level,
    'coins', s.coins,
    'hp_current', s.hp_current,
    'hp_max', s.hp_max,
    'is_weakened', s.is_weakened,
    'priority_mission', (
      select jsonb_build_object(
        'id', t.id,
        'title', t.title,
        'due_date', t.due_date,
        'priority', t.priority,
        'xp_reward', t.xp_reward,
        'coin_reward', t.coin_reward
      )
      from public.tasks t
      where t.user_id = auth.uid()
        and t.parent_task_id is null
        and t.status in ('pending', 'in_progress')
      order by coalesce(t.due_date < now() + interval '24 hours', false) desc,
               t.priority desc,
               t.due_date asc nulls last,
               t.created_at
      limit 1
    ),
    'habits', coalesce((
      select jsonb_agg(
        jsonb_build_object('id', id, 'name', name, 'done', done)
        order by created_at
      )
      from today_habits
    ), '[]'::jsonb),
    'habits_done', (select count(*) from today_habits where done),
    'habits_total', (select count(*) from today_habits),
    'streak_days', (select coalesce(max(current_streak), 0) from today_habits),
    -- 038: lista «Hoy» del Inicio (plan S2). Vencen hoy, vencidas o de
    -- prioridad alta; la app quita la que ya muestra como Siguiente paso.
    'today_tasks', coalesce((
      select jsonb_agg(jsonb_build_object(
               'id', t.id,
               'title', t.title,
               'priority', t.priority,
               'due_date', t.due_date,
               'xp_reward', t.xp_reward,
               'overdue', coalesce(t.due_date < now(), false))
             order by t.due_date nulls last, t.created_at)
      from (
        select t.* from public.tasks t, day
        where t.user_id = auth.uid()
          and t.parent_task_id is null
          and t.status in ('pending', 'in_progress')
          and (t.due_date < day.end_at or t.priority = 'high')
        order by t.due_date nulls last, t.created_at
        limit 6
      ) t
    ), '[]'::jsonb),
    'missions_done', (
      select count(*) from public.tasks t, day
      where t.user_id = auth.uid()
        and t.parent_task_id is null
        and t.status = 'completed'
        and t.completed_at >= day.start_at and t.completed_at < day.end_at
    ),
    'missions_total', (
      select count(*) from public.tasks t, day
      where t.user_id = auth.uid()
        and t.parent_task_id is null
        and ((t.status = 'completed'
              and t.completed_at >= day.start_at
              and t.completed_at < day.end_at)
             or (t.status in ('pending', 'in_progress')
                 and t.due_date >= day.start_at
                 and t.due_date < day.end_at))
    ),
    'focus_minutes', (
      select coalesce(sum(least(
        f.total_minutes,
        floor(extract(epoch from coalesce(f.ended_at, now()) - f.started_at)
              / 60)::int
      )), 0)
      from public.focus_sessions f, day
      where f.user_id = auth.uid()
        and f.started_at >= day.start_at and f.started_at < day.end_at
    )
  )
  from public.profiles p
  left join public.character_stats s on s.user_id = p.id
  where p.id = auth.uid()
$$;
revoke all on function public.home_dashboard(date, integer) from public, anon;
grant execute on function public.home_dashboard(date, integer) to authenticated;

commit;
