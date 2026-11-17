-- Migración 040 · Las tareas se hacen en Modo Foco y todas pueden tener pasos (requiere 001–039).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- Pedido del usuario (2026-10-29): para completar una tarea hay que usar el
-- Modo Foco, y los pasos deben servir en cualquier tarea, no solo en las de
-- los Mentores.
--
-- 1. Regla task_requires_focus (1 = sí; 0 la apaga sin publicar) y
--    _task_in_focus(uid, task): la tarea está en una sesión activa o en pausa.
-- 2. complete_task y toggle_task_step lanzan «focus_required» fuera del Foco.
--    El Modo Foco completa con complete_task mientras la sesión está abierta,
--    así que su flujo no cambia. Resto: misma copia de 039.
-- 3. task_detail devuelve in_focus para que la app ofrezca «Empezar en Foco».
-- 4. create_task (010) guarda p_subtasks como pasos (task_steps) en lugar de
--    tareas hijas; missions_overview cuenta hijas viejas + pasos.

begin;

insert into public.game_rules (key, value, provisional, note) values
  ('task_requires_focus', 1, true, 'Completar tareas y pasos solo dentro del Modo Foco (040)')
on conflict (key) do nothing;

create or replace function public._task_in_focus(p_uid uuid, p_task_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.focus_session_tasks f
    join public.focus_sessions s on s.id = f.session_id
    where f.task_id = p_task_id and s.user_id = p_uid
      and s.status in ('active', 'paused'))
$$;

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
  -- 040: las tareas se hacen en Modo Foco (regla task_requires_focus).
  if public.rule('task_requires_focus') > 0
     and not public._task_in_focus(v_uid, p_task_id) then
    raise exception 'focus_required' using errcode = 'P0001';
  end if;

  -- 039: lo que ya pagaron sus pasos no se vuelve a pagar.
  select greatest(0, v_task.xp_reward - coalesce(sum(paid_xp), 0)),
         greatest(0, v_task.coin_reward - coalesce(sum(paid_coins), 0))
  into v_xp, v_coins
  from public.task_steps where task_id = p_task_id;
  -- Anti-trampa: completada a menos de 2 min de crearla.
  if now() - v_task.created_at < make_interval(secs => public.rule('task_min_seconds')) then
    v_xp := least(v_xp, public.rule('task_xp_base')::integer);
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

create or replace function public.toggle_task_step(p_step_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_step public.task_steps;
  v_task public.tasks;
  v_unpaid integer;
  v_open integer;
  v_xp integer;
  v_coins integer;
  v_res jsonb;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  select * into v_step from public.task_steps where id = p_step_id and user_id = v_uid;
  if not found then
    raise exception 'step_not_found' using errcode = 'P0002';
  end if;
  -- Primero la tarea (mismo orden de bloqueo que complete_task).
  select * into v_task from public.tasks where id = v_step.task_id for update;
  select * into v_step from public.task_steps where id = p_step_id for update;
  if v_task.status not in ('pending', 'in_progress') then
    raise exception 'task_not_open' using errcode = '22023';
  end if;
  -- 040: las tareas se hacen en Modo Foco (regla task_requires_focus).
  if public.rule('task_requires_focus') > 0
     and not public._task_in_focus(v_uid, v_task.id) then
    raise exception 'focus_required' using errcode = 'P0001';
  end if;

  -- Desmarcar: lo pagado se queda pagado; al volver a marcar no paga de nuevo.
  if v_step.done_at is not null then
    update public.task_steps set done_at = null where id = p_step_id;
    return jsonb_build_object('done', false);
  end if;

  update public.task_steps set done_at = now() where id = p_step_id;

  -- El último paso abierto completa la tarea: complete_task paga el resto.
  select count(*) into v_open from public.task_steps
  where task_id = v_task.id and done_at is null;
  if v_open = 0 then
    return public.complete_task(v_task.id)
      || jsonb_build_object('done', true, 'task_completed', true);
  end if;

  if v_step.paid_at is not null
     or now() - v_task.created_at < make_interval(secs => public.rule('task_min_seconds')) then
    return jsonb_build_object('done', true);
  end if;

  -- §6.1: lo pendiente entre los pasos sin pagar (la tarea cuenta como uno:
  -- su parte la paga complete_task al final).
  select count(*) into v_unpaid from public.task_steps
  where task_id = v_task.id and paid_at is null;
  select floor(greatest(0, v_task.xp_reward - coalesce(sum(paid_xp), 0)) / v_unpaid::numeric),
         floor(greatest(0, v_task.coin_reward - coalesce(sum(paid_coins), 0)) / v_unpaid::numeric)
  into v_xp, v_coins
  from public.task_steps where task_id = v_task.id;
  if v_coins > 0 and (
    select count(*) from public.quest_log_entries
    where user_id = v_uid and source_type in ('task', 'npc') and coin_awarded > 0
      and occurred_at >= current_date and occurred_at < current_date + 1
  ) >= public.rule('task_daily_coin_limit') then
    v_coins := 0;
  end if;

  update public.task_steps
  set paid_at = now(), paid_xp = v_xp, paid_coins = v_coins
  where id = p_step_id;
  v_res := public._award(v_uid, 'task_step', p_step_id, v_xp, v_coins, v_task.skill_id);
  return v_res || jsonb_build_object('done', true);
end $$;

create or replace function public.task_detail(p_task_id uuid)
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  select jsonb_build_object(
    'id', t.id,
    'title', t.title,
    'description', t.description,
    'status', t.status,
    'xp_reward', t.xp_reward,
    'coin_reward', t.coin_reward,
    'created_at', t.created_at,
    'completed_at', t.completed_at,
    'guide', t.guide,
    -- En línea (no _task_in_focus): esta función corre con el RLS del usuario.
    'in_focus', exists (
      select 1 from public.focus_session_tasks f
      join public.focus_sessions s on s.id = f.session_id
      where f.task_id = t.id and s.status in ('active', 'paused')),
    'paid_xp', (select coalesce(sum(paid_xp), 0) from public.task_steps where task_id = t.id),
    'steps', coalesce((
      select jsonb_agg(jsonb_build_object(
               'id', s.id, 'position', s.position, 'title', s.title,
               'done_at', s.done_at, 'paid_xp', s.paid_xp) order by s.position)
      from public.task_steps s where s.task_id = t.id), '[]'::jsonb))
  from public.tasks t
  where t.id = p_task_id and t.user_id = auth.uid()
$$;

create or replace function public.create_task(
  p_title text,
  p_description text default null,
  p_priority public.urgency_level default 'low',
  p_due_date timestamptz default null,
  p_skill_id uuid default null,
  p_project_id uuid default null,
  p_goal_id uuid default null,
  p_subtasks text[] default '{}'
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
                            skill_id, project_id, goal_id)
  values (v_uid, v_title, nullif(trim(coalesce(p_description, '')), ''), p_priority,
          p_due_date, p_skill_id, p_project_id, p_goal_id)
  returning * into v_task;

  -- 040: las subtareas son ahora los pasos de la tarea (039, máx. 8). Va por
  -- attach_task_guide: esta función corre como el usuario, que solo lee pasos.
  if exists (select 1 from unnest(coalesce(p_subtasks, '{}')) x where trim(x) <> '') then
    perform public.attach_task_guide(v_task.id, jsonb_build_object('steps', to_jsonb(p_subtasks)));
  end if;

  return jsonb_build_object('id', v_task.id, 'xp_reward', v_task.xp_reward,
                            'coin_reward', v_task.coin_reward);
end $$;

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

revoke all on function public._task_in_focus(uuid, uuid) from public, anon, authenticated;
revoke all on function public.complete_task(uuid) from public, anon;
grant execute on function public.complete_task(uuid) to authenticated;
revoke all on function public.toggle_task_step(uuid) from public, anon;
grant execute on function public.toggle_task_step(uuid) to authenticated;
revoke all on function public.task_detail(uuid) from public, anon;
grant execute on function public.task_detail(uuid) to authenticated;

commit;
