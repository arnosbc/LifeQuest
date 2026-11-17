-- Migración 044 · Asignación atómica y avance secuencial de tareas guiadas.
-- Requiere 001–043. Ver docs/plan-funcionalidades-asistente.md §6.
--
-- La tarea de Mentor y sus pasos se guardan en la misma transacción; si no se
-- pueden asignar los pasos, tampoco se crea ni se cobra la tarea.
-- Solo se puede completar el primer paso pendiente. Deshacer solo está
-- permitido desde el último paso completado, para conservar el orden.

begin;

drop function if exists public.accept_npc_mission(uuid, text, text);

create or replace function public.accept_npc_mission(
  p_npc_id uuid,
  p_title text,
  p_description text default null,
  p_guide jsonb default null
)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_title text := trim(coalesce(p_title, ''));
  v_description text := nullif(trim(coalesce(p_description, '')), '');
  v_skill uuid;
  v_paid jsonb;
  v_task uuid;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  if v_title = '' or length(v_title) > 200 then
    raise exception 'invalid_title' using errcode = '22023';
  end if;
  if length(v_description) > 4000 then
    raise exception 'invalid_description' using errcode = '22023';
  end if;
  select skill_id into v_skill
  from public.npcs
  where id = p_npc_id and user_id = v_uid;
  if not found then
    raise exception 'npc_not_found' using errcode = 'P0002';
  end if;
  if exists (
    select 1 from public.tasks
    where npc_id = p_npc_id and status in ('pending', 'in_progress')
  ) then
    raise exception 'npc_mission_open' using errcode = 'P0001';
  end if;

  v_paid := public.request_npc_mission(p_npc_id);
  insert into public.tasks (user_id, npc_id, skill_id, title, description, source)
  values (v_uid, p_npc_id, v_skill, v_title, v_description, 'npc')
  returning id into v_task;

  if p_guide is not null then
    perform public.attach_task_guide(v_task, p_guide);
  end if;

  return v_paid || jsonb_build_object('task_id', v_task);
end $$;

revoke all on function public.accept_npc_mission(uuid, text, text, jsonb)
  from public, anon;
grant execute on function public.accept_npc_mission(uuid, text, text, jsonb)
  to authenticated;

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
  if public.rule('task_requires_focus') > 0
     and not public._task_in_focus(v_uid, p_task_id) then
    raise exception 'focus_required' using errcode = 'P0001';
  end if;
  if exists (
    select 1 from public.task_steps
    where task_id = p_task_id and done_at is null
  ) then
    raise exception 'task_steps_pending' using errcode = 'P0001';
  end if;

  select greatest(0, v_task.xp_reward - coalesce(sum(paid_xp), 0)),
         greatest(0, v_task.coin_reward - coalesce(sum(paid_coins), 0))
  into v_xp, v_coins
  from public.task_steps where task_id = p_task_id;
  if now() - v_task.created_at
     < make_interval(secs => public.rule('task_min_seconds')) then
    v_xp := least(v_xp, public.rule('task_xp_base')::integer);
    v_coins := 0;
  end if;
  if v_coins > 0 and (
    select count(*) from public.quest_log_entries
    where user_id = v_uid and source_type in ('task', 'npc') and coin_awarded > 0
      and occurred_at >= current_date and occurred_at < current_date + 1
  ) >= public.rule('task_daily_coin_limit') then
    v_coins := 0;
  end if;

  perform set_config('lifequest.internal', 'on', true);
  update public.tasks set status = 'completed', completed_at = now()
  where id = p_task_id;
  v_res := public._award(
    v_uid,
    case when v_task.npc_id is not null
      then 'npc'::public.quest_source
      else 'task'::public.quest_source
    end,
    p_task_id,
    v_xp,
    v_coins,
    v_task.skill_id
  );
  if v_task.goal_id is not null then
    v_res := v_res || jsonb_build_object(
      'boss', public._damage_boss(v_uid, v_task.goal_id, v_task.xp_reward)
    );
  end if;
  return v_res;
end $$;

revoke all on function public.complete_task(uuid) from public, anon;
grant execute on function public.complete_task(uuid) to authenticated;

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
  select * into v_step
  from public.task_steps
  where id = p_step_id and user_id = v_uid;
  if not found then
    raise exception 'step_not_found' using errcode = 'P0002';
  end if;
  select * into v_task from public.tasks where id = v_step.task_id for update;
  select * into v_step from public.task_steps where id = p_step_id for update;
  if v_task.status not in ('pending', 'in_progress') then
    raise exception 'task_not_open' using errcode = '22023';
  end if;
  if public.rule('task_requires_focus') > 0
     and not public._task_in_focus(v_uid, v_task.id) then
    raise exception 'focus_required' using errcode = 'P0001';
  end if;

  if v_step.done_at is null and exists (
    select 1 from public.task_steps
    where task_id = v_task.id and position < v_step.position and done_at is null
  ) then
    raise exception 'step_order_required' using errcode = 'P0001';
  end if;
  if v_step.done_at is not null and exists (
    select 1 from public.task_steps
    where task_id = v_task.id and position > v_step.position and done_at is not null
  ) then
    raise exception 'step_order_required' using errcode = 'P0001';
  end if;

  if v_step.done_at is not null then
    update public.task_steps set done_at = null where id = p_step_id;
    return jsonb_build_object('done', false);
  end if;

  update public.task_steps set done_at = now() where id = p_step_id;
  select count(*) into v_open
  from public.task_steps
  where task_id = v_task.id and done_at is null;
  if v_open = 0 then
    return public.complete_task(v_task.id)
      || jsonb_build_object('done', true, 'task_completed', true);
  end if;

  if v_step.paid_at is not null
     or now() - v_task.created_at
        < make_interval(secs => public.rule('task_min_seconds')) then
    return jsonb_build_object('done', true);
  end if;

  select count(*) into v_unpaid
  from public.task_steps
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
  v_res := public._award(
    v_uid, 'task_step', p_step_id, v_xp, v_coins, v_task.skill_id
  );
  return v_res || jsonb_build_object('done', true);
end $$;

revoke all on function public.toggle_task_step(uuid) from public, anon;
grant execute on function public.toggle_task_step(uuid) to authenticated;

commit;
