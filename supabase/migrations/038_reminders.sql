-- Migración 038 · Recordatorios (fase 2 del rework: tareas que actúan).
-- Requiere 001–037. Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- «Llamar a mamá a las 7» no es trabajo: es un recordatorio. Vive en la agenda
-- de Hoy y suena a su hora (sync_reminders ya lee tasks), pero
--   · no da XP ni Monedas (trigger y complete_task) ni deja fila en el Historial;
--   · no aparece en Tareas, en Foco ni como sugerencia de Hoy (v_daily_highlight
--     y home_dashboard lo excluyen);
--   · create_task acepta p_is_reminder y exige hora;
--   · day_agenda marca cada bloque con is_reminder;
--   · la repetición copia is_reminder.
-- shortcut: un recordatorio de otro día solo se ve en Hoy ese día (y en su aviso);
-- añadir una lista de recordatorios próximos si hace falta cancelarlos antes.

begin;

alter table public.tasks add column if not exists is_reminder boolean not null default false;
grant insert (is_reminder) on public.tasks to authenticated;

-- Sin recompensa. Corre después de trg_set_task_reward (orden alfabético).
create or replace function public.reminder_without_reward()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.is_reminder then
    new.xp_reward := 0;
    new.coin_reward := 0;
  end if;
  return new;
end $$;
drop trigger if exists trg_zz_reminder_without_reward on public.tasks;
create trigger trg_zz_reminder_without_reward before insert on public.tasks
  for each row execute function public.reminder_without_reward();

-- De 007_daily.sql, sin recordatorios.
create or replace view public.v_daily_highlight with (security_invoker = true) as
select t.id, t.user_id, t.title, t.priority, t.due_date, t.status, t.xp_reward, t.coin_reward,
  case
    when t.status = 'delegated' then 'pending'
    when t.due_date is not null and t.due_date < now() + interval '24 hours' then 'urgent'
    else t.priority::text
  end as bucket,
  case
    when t.status = 'delegated' then 5
    when t.due_date is not null and t.due_date < now() + interval '24 hours' then 1
    when t.priority = 'high' then 2
    when t.priority = 'medium' then 3
    else 4
  end as bucket_order
from public.tasks t
where t.parent_task_id is null and not t.is_reminder
  and t.status in ('pending', 'in_progress', 'delegated');

-- De 032_scheduling.sql, con p_is_reminder.
drop function if exists public.create_task(text, text, public.urgency_level, timestamptz, uuid, uuid, uuid, text[], timestamptz, integer, integer, text);
create or replace function public.create_task(
  p_title text,
  p_description text default null,
  p_priority public.urgency_level default 'low',
  p_due_date timestamptz default null,
  p_skill_id uuid default null,
  p_project_id uuid default null,
  p_goal_id uuid default null,
  p_subtasks text[] default '{}',
  p_scheduled_at timestamptz default null,
  p_estimated_minutes integer default null,
  p_reminder_minutes integer default null,
  p_repeat_rule text default null,
  p_is_reminder boolean default false
)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_title text := trim(coalesce(p_title, ''));
  v_task public.tasks;
  v_sub text;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  if v_title = '' or length(v_title) > 200 then
    raise exception 'invalid_title' using errcode = '22023';
  end if;
  -- Un recordatorio vive en la agenda: sin hora no sonaría nunca.
  if p_is_reminder and p_scheduled_at is null then
    raise exception 'reminder_needs_time' using errcode = '22023';
  end if;
  if p_skill_id is not null
     and not exists (select 1 from public.skills where id = p_skill_id and user_id = v_uid) then
    raise exception 'skill_not_found' using errcode = 'P0002';
  end if;
  if p_project_id is not null and not exists (
    select 1 from public.projects where id = p_project_id and user_id = v_uid
      and status in ('not_started', 'in_progress') and archived_at is null) then
    raise exception 'project_not_found' using errcode = 'P0002';
  end if;
  if p_goal_id is not null and not exists (
    select 1 from public.goals where id = p_goal_id and user_id = v_uid
      and status in ('not_started', 'in_progress') and archived_at is null) then
    raise exception 'goal_not_found' using errcode = 'P0002';
  end if;

  insert into public.tasks (user_id, title, description, priority, due_date,
                            skill_id, project_id, goal_id, scheduled_at,
                            estimated_minutes, reminder_minutes, repeat_rule, is_reminder)
  values (v_uid, v_title, nullif(trim(coalesce(p_description, '')), ''), p_priority,
          p_due_date, p_skill_id, p_project_id, p_goal_id, p_scheduled_at,
          p_estimated_minutes,
          -- El recordatorio siempre avisa; por defecto, a su hora.
          case when p_is_reminder then coalesce(p_reminder_minutes, 0) else p_reminder_minutes end,
          nullif(trim(coalesce(p_repeat_rule, '')), ''), coalesce(p_is_reminder, false))
  returning * into v_task;

  foreach v_sub in array coalesce(p_subtasks, '{}') loop
    if trim(v_sub) <> '' then
      insert into public.tasks (user_id, parent_task_id, title, skill_id)
      values (v_uid, v_task.id, left(trim(v_sub), 200), p_skill_id);
    end if;
  end loop;

  return jsonb_build_object('id', v_task.id, 'xp_reward', v_task.xp_reward,
                            'coin_reward', v_task.coin_reward);
end $$;
revoke all on function public.create_task(text, text, public.urgency_level, timestamptz, uuid, uuid, uuid, text[], timestamptz, integer, integer, text, boolean) from public, anon;
grant execute on function public.create_task(text, text, public.urgency_level, timestamptz, uuid, uuid, uuid, text[], timestamptz, integer, integer, text, boolean) to authenticated;

-- De 036_restore_functions.sql, con recordatorios sin XP.
create or replace function public.complete_task(p_task_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_task public.tasks;
  v_xp integer;
  v_coins integer;
  v_res jsonb;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  select * into v_task from public.tasks
  where id = p_task_id and user_id = v_uid for update;
  if not found then
    raise exception 'task_not_found' using errcode = 'P0002';
  end if;
  if v_task.status not in ('pending', 'in_progress', 'delegated') then
    raise exception 'task_not_open' using errcode = '22023';
  end if;

  -- Recordatorio: se marca hecho sin XP ni entrada en el Historial.
  if v_task.is_reminder then
    perform set_config('lifequest.internal', 'on', true);
    update public.tasks set status = 'completed', completed_at = now() where id = p_task_id;
    return jsonb_build_object('xp', 0, 'coins', 0, 'reminder', true);
  end if;

  v_xp := v_task.xp_reward;
  v_coins := v_task.coin_reward;
  -- Anti-trampa: completada a menos de 2 min de crearla.
  if now() - v_task.created_at < make_interval(secs => public.rule('task_min_seconds')) then
    v_xp := public.rule('task_xp_base')::integer;
    v_coins := 0;
  end if;
  -- Anti-trampa: máximo 15 tareas con Monedas al día.
  if v_coins > 0 and (
    select count(*) from public.quest_log_entries
    where user_id = v_uid and source_type in ('task', 'npc') and coin_awarded > 0
      and occurred_at >= current_date and occurred_at < current_date + 1
  ) >= public.rule('task_daily_coin_limit') then
    v_coins := 0;
  end if;

  perform set_config('lifequest.internal', 'on', true);
  update public.tasks set status = 'completed', completed_at = now() where id = p_task_id;

  v_res := public._award(v_uid,
    case when v_task.npc_id is not null then 'npc'::public.quest_source else 'task'::public.quest_source end,
    p_task_id, v_xp, v_coins, v_task.skill_id);
  if v_task.goal_id is not null then
    v_res := v_res || jsonb_build_object('boss',
      public._damage_boss(v_uid, v_task.goal_id, v_task.xp_reward));
  end if;
  return v_res;
end $$;

-- De 032_scheduling.sql, con is_reminder.
create or replace function public.day_agenda(p_day date, p_utc_offset_minutes integer default 0)
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  with day as (
    select start_at, start_at + interval '1 day' as end_at
    from (select (p_day::timestamp - make_interval(mins => p_utc_offset_minutes))
                 at time zone 'UTC' as start_at) s
  )
  select jsonb_build_object(
    'scheduled', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', t.id, 'title', t.title, 'scheduled_at', t.scheduled_at,
        'estimated_minutes', t.estimated_minutes, 'repeat_rule', t.repeat_rule,
        'done', t.status = 'completed', 'is_reminder', t.is_reminder) order by t.scheduled_at)
      from public.tasks t, day
      where t.user_id = auth.uid() and t.parent_task_id is null
        and t.status in ('pending', 'in_progress', 'delegated', 'completed')
        and t.scheduled_at >= day.start_at and t.scheduled_at < day.end_at
    ), '[]'::jsonb),
    'unscheduled', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', t.id, 'title', t.title, 'due_date', t.due_date,
        'estimated_minutes', t.estimated_minutes, 'is_reminder', t.is_reminder) order by t.priority desc, t.due_date nulls last, t.created_at)
      from public.tasks t
      where t.user_id = auth.uid() and t.parent_task_id is null and t.scheduled_at is null
        and t.status in ('pending', 'in_progress')
    ), '[]'::jsonb)
  )
$$;

-- De 032_scheduling.sql, copia is_reminder.
create or replace function public.spawn_next_occurrence()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_tz text;
  v_base timestamptz := coalesce(new.scheduled_at, new.due_date, now());
  v_next timestamptz;
begin
  select coalesce(time_zone, 'UTC') into v_tz
  from public.game_master_settings where user_id = new.user_id;
  v_next := public._next_occurrence(new.repeat_rule, v_base, coalesce(v_tz, 'UTC'));
  if v_next is null then
    return null;
  end if;
  -- scheduled_at y due_date se mueven juntos para no perder la distancia entre ellos.
  -- shortcut: las subtareas no se copian; hacerlo si una tarea repetida las necesita.
  insert into public.tasks (user_id, project_id, goal_id, skill_id, parent_task_id, title,
                            description, priority, tags, delegated_to, source,
                            scheduled_at, due_date, estimated_minutes, reminder_minutes, repeat_rule,
                            is_reminder)
  values (new.user_id, new.project_id, new.goal_id, new.skill_id, new.parent_task_id, new.title,
          new.description, new.priority, new.tags, new.delegated_to, new.source,
          new.scheduled_at + (v_next - v_base), new.due_date + (v_next - v_base),
          new.estimated_minutes, new.reminder_minutes, new.repeat_rule, new.is_reminder);
  return null;
end $$;

-- De 036_restore_functions.sql, sin recordatorios como sugerencia.
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
        and not t.is_reminder
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

commit;
