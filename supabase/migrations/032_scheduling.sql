-- Migración 032 · Tareas que actúan (rework fase 2, docs/plan-rework.md).
-- Requiere 001–031. Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- 1. Columnas: bloque en la agenda, duración, aviso, repetición cerrada,
--    minutos de Foco medidos y hora del aviso de hábitos.
-- 2. game_master_settings.time_zone: la repetición cuenta días locales.
-- 3. Repetición: al completar una tarea con repeat_rule nace la siguiente
--    ocurrencia en la misma transacción (trigger, sirve para complete_task).
-- 4. RPC schedule_task y snooze_task; create_task acepta los campos nuevos.
-- 5. end_dungeon suma los minutos medidos a las tareas de la sesión.
-- 6. missions_overview devuelve los campos nuevos.

begin;

-- 1. Columnas ------------------------------------------------------------------
alter table public.tasks
  add column if not exists scheduled_at timestamptz,
  add column if not exists estimated_minutes integer,  -- vuelve como duración del bloque (004 la quitó)
  add column if not exists reminder_minutes integer,
  add column if not exists focus_minutes integer not null default 0;
alter table public.habits add column if not exists reminder_time time;

-- repeat_rule era texto libre sin uso: lo que no cumpla el formato se descarta.
update public.tasks set repeat_rule = null
where repeat_rule is not null
  and repeat_rule !~ '^(daily|weekdays|weekly:[0-6](,[0-6])*|monthly:([1-9]|[12][0-9]|3[01]))$';

alter table public.tasks drop constraint if exists tasks_repeat_rule_check;
alter table public.tasks add constraint tasks_repeat_rule_check check (
  repeat_rule ~ '^(daily|weekdays|weekly:[0-6](,[0-6])*|monthly:([1-9]|[12][0-9]|3[01]))$');
alter table public.tasks drop constraint if exists tasks_estimated_minutes_check;
alter table public.tasks add constraint tasks_estimated_minutes_check
  check (estimated_minutes between 5 and 720);
alter table public.tasks drop constraint if exists tasks_reminder_minutes_check;
alter table public.tasks add constraint tasks_reminder_minutes_check
  check (reminder_minutes between 0 and 1440);

-- focus_minutes no se concede: solo lo escribe end_dungeon.
grant insert (scheduled_at, estimated_minutes, reminder_minutes, repeat_rule)
  on public.tasks to authenticated;
grant update (scheduled_at, estimated_minutes, reminder_minutes, repeat_rule)
  on public.tasks to authenticated;
grant insert (reminder_time), update (reminder_time) on public.habits to authenticated;

-- 2. Zona horaria del usuario ----------------------------------------------------
alter table public.game_master_settings
  add column if not exists time_zone text not null default 'UTC';
create or replace function public.check_time_zone()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  perform now() at time zone new.time_zone;  -- falla si la zona no existe
  return new;
exception when others then
  raise exception 'invalid_time_zone' using errcode = '22023';
end $$;
drop trigger if exists trg_check_time_zone on public.game_master_settings;
create trigger trg_check_time_zone before insert or update of time_zone
  on public.game_master_settings for each row execute function public.check_time_zone();
grant update (time_zone) on public.game_master_settings to authenticated;

-- 3. Repetición --------------------------------------------------------------------
-- Siguiente momento que cumple la regla, después de p_from y en el futuro.
-- Conserva la hora local; monthly:31 cae en el último día de los meses cortos.
create or replace function public._next_occurrence(p_rule text, p_from timestamptz, p_tz text)
returns timestamptz
language plpgsql
stable
set search_path = ''
as $$
declare
  v_local timestamp := p_from at time zone p_tz;
  v_now timestamp := now() at time zone p_tz;
  v_kind text := split_part(p_rule, ':', 1);
  v_arg text := split_part(p_rule, ':', 2);
  v_cand timestamp;
  v_day integer;
begin
  -- Si el bloque quedó atrás, se avanza en días enteros hasta hoy.
  if v_local < v_now then
    v_local := v_local + make_interval(days => (v_now::date - v_local::date));
  end if;
  for i in 0..62 loop
    v_cand := v_local + make_interval(days => i);
    if v_cand > v_now and v_cand > p_from at time zone p_tz and (
         v_kind = 'daily'
      or (v_kind = 'weekdays' and extract(isodow from v_cand) < 6)
      or (v_kind = 'weekly' and extract(dow from v_cand)::text = any (string_to_array(v_arg, ',')))
      or (v_kind = 'monthly' and extract(day from v_cand) = least(v_arg::integer,
            extract(day from date_trunc('month', v_cand) + interval '1 month - 1 day')))) then
      return v_cand at time zone p_tz;
    end if;
  end loop;
  return null;
end $$;

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
                            scheduled_at, due_date, estimated_minutes, reminder_minutes, repeat_rule)
  values (new.user_id, new.project_id, new.goal_id, new.skill_id, new.parent_task_id, new.title,
          new.description, new.priority, new.tags, new.delegated_to, new.source,
          new.scheduled_at + (v_next - v_base), new.due_date + (v_next - v_base),
          new.estimated_minutes, new.reminder_minutes, new.repeat_rule);
  return null;
end $$;
drop trigger if exists trg_spawn_next_occurrence on public.tasks;
create trigger trg_spawn_next_occurrence after update of status on public.tasks
  for each row
  when (new.status = 'completed' and old.status is distinct from 'completed'
        and new.repeat_rule is not null)
  execute function public.spawn_next_occurrence();

-- 4. Agenda ----------------------------------------------------------------------------
-- security invoker: el update pasa por el RLS y los grants de columna.
create or replace function public.schedule_task(
  p_task_id uuid, p_at timestamptz, p_minutes integer default null)
returns void
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  update public.tasks
  set scheduled_at = p_at, estimated_minutes = coalesce(p_minutes, estimated_minutes)
  where id = p_task_id and user_id = auth.uid()
    and status in ('pending', 'in_progress', 'delegated');
  if not found then
    raise exception 'task_not_found' using errcode = 'P0002';
  end if;
end $$;

-- Mueve el bloque N minutos desde ahora (o desde su hora, si aún no llega).
create or replace function public.snooze_task(p_task_id uuid, p_minutes integer default 60)
returns timestamptz
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_at timestamptz;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  if p_minutes is null or p_minutes not between 1 and 1440 then
    raise exception 'invalid_minutes' using errcode = '22023';
  end if;
  update public.tasks
  set scheduled_at = greatest(coalesce(scheduled_at, now()), now()) + make_interval(mins => p_minutes)
  where id = p_task_id and user_id = auth.uid()
    and status in ('pending', 'in_progress', 'delegated')
  returning scheduled_at into v_at;
  if not found then
    raise exception 'task_not_found' using errcode = 'P0002';
  end if;
  return v_at;
end $$;

-- create_task con agenda: se borra la firma de 010 para no dejar dos sobrecargas.
drop function if exists public.create_task(text, text, public.urgency_level, timestamptz, uuid, uuid, uuid, text[]);
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
  p_repeat_rule text default null
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
                            estimated_minutes, reminder_minutes, repeat_rule)
  values (v_uid, v_title, nullif(trim(coalesce(p_description, '')), ''), p_priority,
          p_due_date, p_skill_id, p_project_id, p_goal_id, p_scheduled_at,
          p_estimated_minutes, p_reminder_minutes, nullif(trim(coalesce(p_repeat_rule, '')), ''))
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

-- 5. Tiempo medido en Foco ----------------------------------------------------------
-- Cuerpo de 012 más el reparto de minutos. security definer porque
-- focus_minutes no se concede al cliente; el where filtra por auth.uid().
-- shortcut: los minutos se reparten por igual entre las tareas de la sesión;
-- medir por tarea si Foco deja cambiar de tarea a mitad de ciclo.
create or replace function public.end_dungeon(p_session_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_session public.focus_sessions;
  v_minutes integer;
  v_count integer;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  update public.focus_sessions
  set status = 'completed', ended_at = now()
  where id = p_session_id and user_id = auth.uid() and status in ('active', 'paused')
  returning * into v_session;
  if not found then
    raise exception 'session_not_found' using errcode = 'P0002';
  end if;

  v_minutes := greatest(0, least(v_session.total_minutes,
    floor(extract(epoch from v_session.ended_at - v_session.started_at) / 60)::integer));
  select count(*) into v_count from public.focus_session_tasks where session_id = p_session_id;
  if v_count > 0 and v_minutes > 0 then
    update public.tasks t
    set focus_minutes = t.focus_minutes + v_minutes / v_count
      + case when fst.rn = 1 then v_minutes % v_count else 0 end
    from (select task_id, row_number() over (order by task_id) rn
          from public.focus_session_tasks where session_id = p_session_id) fst
    where t.id = fst.task_id and t.user_id = auth.uid();
  end if;

  return (
    select jsonb_build_object(
      'cycles', count(r.id),
      'xp', coalesce(sum(q.xp_awarded), 0),
      'coins', coalesce(sum(q.coin_awarded), 0),
      'minutes', v_minutes
    )
    from public.dungeon_runs r
    left join public.quest_log_entries q on q.source_type = 'dungeon' and q.source_id = r.id
    where r.session_id = p_session_id
  );
end $$;

-- 6. Misiones con agenda ----------------------------------------------------------------
-- Cuerpo de 010 más los campos de agenda.
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
        'skill_name', s.name,
        'project_title', p.title,
        'goal_title', g.title,
        'scheduled_at', t.scheduled_at,
        'estimated_minutes', t.estimated_minutes,
        'reminder_minutes', t.reminder_minutes,
        'repeat_rule', t.repeat_rule,
        'focus_minutes', t.focus_minutes,
        'subtasks_total', (select count(*) from public.tasks c where c.parent_task_id = t.id),
        'subtasks_done', (select count(*) from public.tasks c
                          where c.parent_task_id = t.id and c.status = 'completed')
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

-- 7. Agenda de Hoy ------------------------------------------------------------------
-- security invoker. p_day y p_utc_offset_minutes definen "hoy" igual que home_dashboard (001).
-- scheduled: bloques del día (también los ya hechos); unscheduled: lo abierto sin hora.
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
        'done', t.status = 'completed') order by t.scheduled_at)
      from public.tasks t, day
      where t.user_id = auth.uid() and t.parent_task_id is null
        and t.status in ('pending', 'in_progress', 'delegated', 'completed')
        and t.scheduled_at >= day.start_at and t.scheduled_at < day.end_at
    ), '[]'::jsonb),
    'unscheduled', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', t.id, 'title', t.title, 'due_date', t.due_date,
        'estimated_minutes', t.estimated_minutes) order by t.priority desc, t.due_date nulls last, t.created_at)
      from public.tasks t
      where t.user_id = auth.uid() and t.parent_task_id is null and t.scheduled_at is null
        and t.status in ('pending', 'in_progress')
    ), '[]'::jsonb)
  )
$$;

-- 8. Avisos del teléfono ------------------------------------------------------------
-- La app la llama al abrir y al volver: guarda su zona horaria (la usa la
-- repetición) y recibe lo que debe programar como aviso local en 7 días.
create or replace function public.sync_reminders(p_time_zone text)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_gms public.game_master_settings;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  update public.game_master_settings set time_zone = p_time_zone
  where user_id = auth.uid() and p_time_zone is not null and time_zone is distinct from p_time_zone;
  select * into v_gms from public.game_master_settings where user_id = auth.uid();
  -- Los avisos de tareas y hábitos no son críticos: la app los salta en la ventana de silencio.
  return jsonb_build_object(
    'silence_start', v_gms.silence_window_start,
    'silence_end', v_gms.silence_window_end,
    'tasks', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', t.id, 'title', t.title, 'scheduled_at', t.scheduled_at,
        'reminder_minutes', t.reminder_minutes) order by t.scheduled_at)
      from public.tasks t
      where t.user_id = auth.uid() and t.reminder_minutes is not null
        and t.status in ('pending', 'in_progress', 'delegated')
        and t.scheduled_at - make_interval(mins => t.reminder_minutes) > now()
        and t.scheduled_at < now() + interval '7 days'
    ), '[]'::jsonb),
    'habits', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', h.id, 'name', h.name, 'reminder_time', h.reminder_time,
        'days', case when h.frequency = 'daily' then '[0,1,2,3,4,5,6]'::jsonb
                     else to_jsonb(coalesce(h.specific_days, '{}')) end) order by h.created_at)
      from public.habits h
      where h.user_id = auth.uid() and h.type = 'good' and h.reminder_time is not null
    ), '[]'::jsonb)
  );
end $$;

-- Permisos ----------------------------------------------------------------------------
revoke all on function public._next_occurrence(text, timestamptz, text) from public, anon, authenticated;
do $$
declare f text;
begin
  foreach f in array array['public.missions_overview()', 'public.end_dungeon(uuid)',
    'public.schedule_task(uuid, timestamptz, integer)', 'public.snooze_task(uuid, integer)',
    'public.day_agenda(date, integer)', 'public.sync_reminders(text)',
    'public.create_task(text, text, public.urgency_level, timestamptz, uuid, uuid, uuid, text[], timestamptz, integer, integer, text)'] loop
    execute format('revoke all on function %s from public, anon', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;

commit;
