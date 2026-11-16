-- Migración 073 · Tareas que se repiten (RF-050, mejora 2 del 2026-11-16).
-- Requiere 039 (pasos), 049 (hora local) y 068 (minutos por paso).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
--   1. tasks.repeat_rule (columna de v1, sin uso hasta hoy): 'daily',
--      'weekdays' (lunes a viernes), 'weekly' o 'monthly'. tasks.series_id une
--      las copias de una misma tarea (= id de la primera).
--   2. set_task_repeat(id, regla | null): elige o quita la repetición de una
--      tarea abierta. Sin fecha límite, toma hoy a las 23:59.
--   3. _spawn_repeating_tasks() (cron 00:12 local, después de daily_maintenance):
--      si la serie no tiene ninguna copia abierta, crea la siguiente cuando
--      llega su día, con los mismos datos y pasos (sin cobrar). Así la de
--      mañana no existe hoy: no se puede repetir para ganar XP de más.
--   4. Borrar una copia abierta detiene la serie.
--   5. missions_overview devuelve repeat_rule.

begin;

alter table public.tasks add column if not exists series_id uuid;
alter table public.tasks drop constraint if exists tasks_repeat_rule_check;
alter table public.tasks add constraint tasks_repeat_rule_check
  check (repeat_rule is null or repeat_rule in ('daily', 'weekdays', 'weekly', 'monthly'));
create index if not exists tasks_series_idx on public.tasks (series_id) where series_id is not null;

-- Siguiente día de la regla después de [p_after], nunca antes de [p_today].
create or replace function public._next_repeat(p_rule text, p_after date, p_today date)
returns date
language plpgsql
immutable
set search_path = ''
as $$
declare
  v_day date := p_after;
begin
  loop
    v_day := case p_rule
      when 'weekly' then v_day + 7
      when 'monthly' then (v_day + interval '1 month')::date
      else v_day + 1
    end;
    -- daily/weekdays: no hace falta recorrer los días ya pasados uno por uno.
    if p_rule in ('daily', 'weekdays') and v_day < p_today then
      v_day := p_today;
    end if;
    if p_rule = 'weekdays' then
      while extract(isodow from v_day) > 5 loop
        v_day := v_day + 1;
      end loop;
    end if;
    exit when v_day >= p_today;
  end loop;
  return v_day;
end $$;

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
      series_id = coalesce(series_id, id),
      due_date = case when p_rule is null then due_date
                      else coalesce(due_date, (current_date + time '23:59')::timestamptz) end
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
      coalesce(v_last.due_date::date, v_today - 1), v_today);
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

-- Borrar una copia abierta detiene la serie (si no, la cerrada anterior la
-- volvería a crear al día siguiente).
create or replace function public._stop_series_on_delete()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if old.series_id is not null then
    update public.tasks set repeat_rule = null where series_id = old.series_id;
  end if;
  return old;
end $$;

drop trigger if exists trg_stop_series_on_delete on public.tasks;
create trigger trg_stop_series_on_delete after delete on public.tasks
  for each row execute function public._stop_series_on_delete();

-- La lista de Tareas trae la regla para mostrar «↻ Cada día» y el menú.
create or replace function public.missions_overview()
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  select jsonb_build_object(
    'missions', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', t.id,
        'title', t.title,
        'description', t.description,
        'priority', t.priority,
        'due_date', t.due_date,
        'status', t.status,
        'bucket', h.bucket,
        'xp_reward', t.xp_reward,
        'coin_reward', t.coin_reward,
        'repeat_rule', t.repeat_rule,
        'skill_name', s.name,
        'project_title', p.title,
        'goal_title', g.title,
        'subtasks_total', (select count(*) from public.tasks c where c.parent_task_id = t.id)
                          + (select count(*) from public.task_steps ts where ts.task_id = t.id),
        'subtasks_done', (select count(*) from public.tasks c
                          where c.parent_task_id = t.id and c.status = 'completed')
                         + (select count(*) from public.task_steps ts
                            where ts.task_id = t.id and ts.done_at is not null)
      ) order by h.bucket_order, t.due_date nulls last, t.created_at)
      from public.v_daily_highlight h
      join public.tasks t on t.id = h.id
      left join public.skills s on s.id = t.skill_id
      left join public.projects p on p.id = t.project_id
      left join public.goals g on g.id = t.goal_id
    ), '[]'::jsonb),
    'skills', coalesce((
      select jsonb_agg(jsonb_build_object('id', id, 'name', name) order by created_at)
      from public.skills
    ), '[]'::jsonb),
    'projects', coalesce((
      select jsonb_agg(jsonb_build_object('id', id, 'title', title, 'goal_id', goal_id) order by created_at)
      from public.projects
      where status in ('not_started', 'in_progress') and archived_at is null
    ), '[]'::jsonb),
    'goals', coalesce((
      select jsonb_agg(jsonb_build_object('id', id, 'title', title) order by created_at)
      from public.goals
      where status in ('not_started', 'in_progress') and archived_at is null
    ), '[]'::jsonb)
  )
$$;

revoke all on function public._next_repeat(text, date, date) from public, anon, authenticated;
revoke all on function public._spawn_repeating_tasks(date) from public, anon, authenticated;
revoke all on function public._stop_series_on_delete() from public, anon, authenticated;
revoke all on function public.set_task_repeat(uuid, text) from public, anon;
grant execute on function public.set_task_repeat(uuid, text) to authenticated;

-- Cron: 05:12 UTC = 00:12 en Colombia, después de daily_maintenance (05:05).
do $$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    perform cron.unschedule(jobid) from cron.job where jobname = 'lifequest_repeat_tasks';
    perform cron.schedule('lifequest_repeat_tasks', '12 5 * * *',
                          'select public._spawn_repeating_tasks()');
  else
    raise notice 'Activa pg_cron (Database → Extensions) y vuelve a ejecutar esta migración.';
  end if;
end $$;

commit;
