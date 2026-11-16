-- Migración 074 · La repetición ya no cambia la fecha límite (corrige 073).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- 073 ponía hoy 23:59 a una tarea sin fecha al elegir «Repetir», y «No
-- repetir» no la quitaba: la tarea quedaba «vence hoy» sin que la persona lo
-- pidiera. Sin fecha, la siguiente copia se cuenta desde el día en que se
-- completó la anterior (nunca el mismo día).

begin;

create or replace function public.set_task_repeat(p_task_id uuid, p_rule text)
returns void
language plpgsql
security definer
set search_path = ''
set timezone to 'America/Bogota'
as $$
declare
  v_task public.tasks;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  if p_rule is not null and p_rule not in ('daily', 'weekdays', 'weekly', 'monthly') then
    raise exception 'invalid_repeat_rule' using errcode = '22023';
  end if;
  select * into v_task from public.tasks
  where id = p_task_id and user_id = auth.uid() and parent_task_id is null
    and status in ('pending', 'in_progress', 'delegated')
  for update;
  if not found then
    raise exception 'task_not_open' using errcode = 'P0002';
  end if;
  update public.tasks
  set repeat_rule = p_rule,
      series_id = coalesce(series_id, id)
  where id = p_task_id;
end $$;

create or replace function public._spawn_repeating_tasks(p_today date default null)
returns integer
language plpgsql
security definer
set search_path = ''
set timezone to 'America/Bogota'
as $$
declare
  v_today date := coalesce(p_today, current_date);
  v_last public.tasks;
  v_next date;
  v_new uuid;
  v_count integer := 0;
begin
  for v_last in
    -- Última copia de cada serie que sigue repitiéndose y ya no tiene nada abierto.
    select distinct on (t.series_id) t.*
    from public.tasks t
    where t.series_id is not null
    order by t.series_id, t.created_at desc
  loop
    continue when v_last.repeat_rule is null
      or v_last.status in ('pending', 'in_progress', 'delegated');
    v_next := public._next_repeat(v_last.repeat_rule,
      coalesce(v_last.due_date::date, v_last.completed_at::date, v_today - 1), v_today);
    continue when v_next > v_today;

    insert into public.tasks (user_id, title, description, priority, due_date, skill_id,
                              project_id, goal_id, guide, repeat_rule, series_id, source)
    values (v_last.user_id, v_last.title, v_last.description, v_last.priority,
            (v_next + coalesce(v_last.due_date::time, time '23:59'))::timestamptz,
            v_last.skill_id, v_last.project_id, v_last.goal_id, v_last.guide,
            v_last.repeat_rule, v_last.series_id, v_last.source)
    returning id into v_new;
    insert into public.task_steps (task_id, user_id, position, title, minutes)
    select v_new, s.user_id, s.position, s.title, s.minutes
    from public.task_steps s where s.task_id = v_last.id;
    v_count := v_count + 1;
  end loop;
  return v_count;
end $$;

commit;
