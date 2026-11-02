-- Migración 039 · Tareas guiadas con pasos (requiere 001–038).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- Plan: docs/plan-funcionalidades-asistente.md B1, B2, B6 y §6.1.
--
-- 1. tasks.guide (jsonb): objetivo, tema, pistas y búsquedas de la guía.
--    task_steps: los pasos marcables. El cliente solo los lee (RLS); se
--    escriben con las RPC de abajo (anti-trampa, CLAUDE.md §8).
-- 2. Reparto de la XP (§6.1): el total de la tarea no cambia. Cada paso paga
--    lo pendiente dividido entre los pasos sin pagar; el ÚLTIMO paso completa
--    la tarea con complete_task, que paga el resto. Así la Recompensa diaria,
--    el límite de 15 tareas al día, el avance de la meta y los Mentores siguen
--    contando la tarea como siempre.
--    - Se paga una sola vez por paso (paid_at no se borra nunca).
--    - Tarea de menos de task_min_seconds: el paso queda hecho sin pagar y su
--      parte pasa a los siguientes (la regla de 2 min de complete_task).
--    - Con el límite diario de tareas con Monedas alcanzado, el paso paga XP
--      sin Monedas (igual que complete_task).
--    shortcut: los pasos no cuentan para ese límite (lo cuenta la tarea al
--    completarse); el tope suave diario de Monedas de _award sí los frena.
-- 3. complete_task paga solo lo que falte: XP y Monedas menos lo ya pagado
--    por sus pasos. Resto: misma copia de 005.
-- 4. attach_task_guide(task, guide): guarda la guía y sus pasos (1–8). Solo
--    en tareas abiertas sin pasos pagados (si no, «guide_locked»).
--    toggle_task_step(step): marca o desmarca un paso; devuelve lo pagado.
--    task_detail(task): la tarea con su guía, sus pasos y lo ya cobrado.

alter type public.quest_source add value if not exists 'task_step';

begin;

-- 1. Datos ------------------------------------------------------------------------
alter table public.tasks add column if not exists guide jsonb;

create table if not exists public.task_steps (
  id uuid primary key default gen_random_uuid(),
  task_id uuid not null references public.tasks (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  position integer not null check (position between 1 and 8),
  title text not null check (length(title) between 1 and 300),
  done_at timestamptz,
  paid_at timestamptz,
  paid_xp integer not null default 0 check (paid_xp >= 0),
  paid_coins integer not null default 0 check (paid_coins >= 0),
  created_at timestamptz not null default now(),
  unique (task_id, position)
);
create index if not exists task_steps_task_idx on public.task_steps (task_id);

alter table public.task_steps enable row level security;
drop policy if exists task_steps_select_own on public.task_steps;
create policy task_steps_select_own on public.task_steps
  for select using (auth.uid() = user_id);
revoke all on public.task_steps from anon, authenticated;
grant select on public.task_steps to authenticated;

-- 2. complete_task paga lo que falte ------------------------------------------------
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

-- 3. Guía y pasos ------------------------------------------------------------------
create or replace function public._text_list(p jsonb, p_max integer, p_len integer)
returns jsonb
language sql
immutable
set search_path = ''
as $$
  select coalesce(jsonb_agg(left(trim(x), p_len) order by n), '[]'::jsonb)
  from jsonb_array_elements_text(
         case when jsonb_typeof(p) = 'array' then p else '[]'::jsonb end
       ) with ordinality as t(x, n)
  where trim(x) <> '' and n <= p_max
$$;

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
    'paid_xp', (select coalesce(sum(paid_xp), 0) from public.task_steps where task_id = t.id),
    'steps', coalesce((
      select jsonb_agg(jsonb_build_object(
               'id', s.id, 'position', s.position, 'title', s.title,
               'done_at', s.done_at, 'paid_xp', s.paid_xp) order by s.position)
      from public.task_steps s where s.task_id = t.id), '[]'::jsonb))
  from public.tasks t
  where t.id = p_task_id and t.user_id = auth.uid()
$$;

create or replace function public.attach_task_guide(p_task_id uuid, p_guide jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_task public.tasks;
  v_steps jsonb := public._text_list(p_guide -> 'steps', 8, 300);
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  select * into v_task from public.tasks
  where id = p_task_id and user_id = v_uid and parent_task_id is null for update;
  if not found then
    raise exception 'task_not_found' using errcode = 'P0002';
  end if;
  if v_task.status not in ('pending', 'in_progress') then
    raise exception 'task_not_open' using errcode = '22023';
  end if;
  if jsonb_array_length(v_steps) = 0 then
    raise exception 'invalid_guide' using errcode = '22023';
  end if;
  -- Con un paso ya cobrado, cambiar los pasos reordenaría el reparto.
  if exists (select 1 from public.task_steps where task_id = p_task_id and paid_at is not null) then
    raise exception 'guide_locked' using errcode = 'P0001';
  end if;

  delete from public.task_steps where task_id = p_task_id;
  insert into public.task_steps (task_id, user_id, position, title)
  select p_task_id, v_uid, n, x
  from jsonb_array_elements_text(v_steps) with ordinality as t(x, n);

  update public.tasks set guide = jsonb_build_object(
    'objective', nullif(left(trim(coalesce(p_guide ->> 'objective', '')), 400), ''),
    'topic', nullif(left(trim(coalesce(p_guide ->> 'topic', '')), 120), ''),
    'hints', public._text_list(p_guide -> 'hints', 4, 400),
    'search', public._text_list(p_guide -> 'search', 2, 120))
  where id = p_task_id;

  return public.task_detail(p_task_id);
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

revoke all on function public._text_list(jsonb, integer, integer) from public, anon, authenticated;
revoke all on function public.complete_task(uuid) from public, anon;
grant execute on function public.complete_task(uuid) to authenticated;
revoke all on function public.task_detail(uuid) from public, anon;
grant execute on function public.task_detail(uuid) to authenticated;
revoke all on function public.attach_task_guide(uuid, jsonb) from public, anon;
grant execute on function public.attach_task_guide(uuid, jsonb) to authenticated;
revoke all on function public.toggle_task_step(uuid) from public, anon;
grant execute on function public.toggle_task_step(uuid) to authenticated;

commit;
