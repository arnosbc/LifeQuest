-- Migración 046 · Hoy muestra los hábitos con hora y la meta quieta (rework, cierre).
-- Requiere 001–045. Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- · habit_times: hábitos buenos de hoy con hora de aviso (habits.reminder_time,
--   032). Hoy los pone en la agenda y se marcan con «Hecho» (complete_habit).
-- · stalled_goal: la meta abierta más antigua sin tareas completadas en 7 días
--   (creada hace más de 7), con su primera tarea abierta para empezar foco.
--   Si no tiene tareas, next_task es null y Hoy ofrece dividirla en pasos.
-- Se envuelve day_agenda (como 044 con weekly_review).

begin;

do $$
begin
  if to_regprocedure('public.day_agenda_before_habits(date, integer)') is null then
    alter function public.day_agenda(date, integer)
      rename to day_agenda_before_habits;
  end if;
end $$;

create or replace function public.day_agenda(
  p_day date,
  p_utc_offset_minutes integer default 0
)
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  with goal_tasks as (
    -- Tareas de cada meta: directas o a través de un proyecto.
    select g.id as goal_id, t.id, t.title, t.status, t.completed_at, t.created_at
    from public.goals g
    join public.tasks t on t.user_id = g.user_id
      and (t.goal_id = g.id
           or t.project_id in (select p.id from public.projects p where p.goal_id = g.id))
    where g.user_id = auth.uid() and t.parent_task_id is null and not t.is_reminder
  )
  select public.day_agenda_before_habits(p_day, p_utc_offset_minutes)
    || jsonb_build_object(
      'habit_times', coalesce((
        select jsonb_agg(jsonb_build_object('id', h.id, 'reminder_time', h.reminder_time)
                         order by h.reminder_time)
        from public.habits h
        where h.user_id = auth.uid() and h.type = 'good' and h.reminder_time is not null
          and (h.frequency = 'daily' or extract(dow from p_day)::int = any (h.specific_days))
      ), '[]'::jsonb),
      'stalled_goal', (
        select jsonb_build_object(
          'id', g.id, 'title', g.title,
          'next_task', (
            select jsonb_build_object('id', gt.id, 'title', gt.title)
            from goal_tasks gt
            where gt.goal_id = g.id and gt.status in ('pending', 'in_progress')
            order by gt.created_at
            limit 1))
        from public.goals g
        where g.user_id = auth.uid()
          and g.status in ('not_started', 'in_progress')
          and g.created_at < now() - interval '7 days'
          and not exists (
            select 1 from goal_tasks gt
            where gt.goal_id = g.id and gt.status = 'completed'
              and gt.completed_at > now() - interval '7 days')
        order by g.created_at
        limit 1)
    )
$$;

revoke all on function public.day_agenda(date, integer) from public, anon;
grant execute on function public.day_agenda(date, integer) to authenticated;
revoke all on function public.day_agenda_before_habits(date, integer) from public, anon;
grant execute on function public.day_agenda_before_habits(date, integer) to authenticated;

commit;
