-- Migración 005 · Motor de recompensas, tareas y hábitos (requiere 004).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
-- Plan: docs/plan-cambios-esquema.md §5.1, §5.2 y §5.4, paso 3 y 4.
--
-- 1. rule(): lee game_rules. _level_threshold(): XP para subir (100 × n^1,5).
-- 2. _award(): único camino para dar XP, Monedas y vida. Aplica dificultad,
--    debilitado (−25 % XP), tope suave diario (75), bolsa con límite y Tesoro,
--    sube nivel del personaje y de la skill, y escribe la Bitácora.
-- 3. Recompensa de tareas por reglas (10–40 XP, Monedas = 30 %) al crearlas.
-- 4. RPC complete_task, complete_project y daño al jefe (+300 XP / +90 al vencerlo).
-- 5. RPC complete_habit (recompensa del servidor) y register_bad_habit (−3/−5/−8).
-- 6. RPC claim_daily_chest: 15 Monedas con ≥ 3 misiones en el día.
--
-- shortcut: "hoy" es el día UTC del servidor (tope diario, 15 tareas, cofre);
-- pasar la zona horaria del dispositivo si hace falta precisión local.

begin;

-- 1. Reglas y curva de niveles ----------------------------------------------
create or replace function public.rule(p_key text)
returns numeric
language sql
stable
security definer
set search_path = ''
as $$
  select value from public.game_rules where key = p_key
$$;
grant execute on function public.rule(text) to authenticated;

create or replace function public._level_threshold(p_level integer)
returns integer
language sql
stable
security definer
set search_path = ''
as $$
  select round(public.rule('level_base') * power(p_level, public.rule('level_exp')))::integer
$$;

-- 2. Pagar ---------------------------------------------------------------------
create or replace function public._award(
  p_uid uuid,
  p_source public.quest_source,
  p_source_id uuid,
  p_xp integer,
  p_coins integer,
  p_skill_id uuid default null,
  p_result public.quest_result default 'completed',
  p_hp integer default 0
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_stats public.character_stats;
  v_xp_mult numeric;
  v_coin_mult numeric;
  v_xp integer;
  v_coins integer;
  v_earned integer;
  v_full integer;
  v_half integer;
  v_cap integer;
  v_wallet integer;
  v_treasury integer;
  v_level integer;
  v_cur integer;
  v_next integer;
begin
  insert into public.character_stats (user_id) values (p_uid)
  on conflict (user_id) do nothing;
  select * into v_stats from public.character_stats where user_id = p_uid for update;

  select dl.xp_multiplier, dl.coin_multiplier into v_xp_mult, v_coin_mult
  from public.game_master_settings g
  join public.difficulty_levels dl on dl.level = g.difficulty
  where g.user_id = p_uid;

  v_xp := floor(greatest(p_xp, 0) * coalesce(v_xp_mult, 1)
                * case when v_stats.is_weakened then public.rule('weakened_xp_factor') else 1 end);
  v_coins := floor(greatest(p_coins, 0) * coalesce(v_coin_mult, 1));

  -- Tope suave: las primeras 50 completas, las 50 siguientes a la mitad.
  select coalesce(sum(coin_awarded), 0) into v_earned
  from public.quest_log_entries
  where user_id = p_uid and occurred_at >= current_date and occurred_at < current_date + 1;
  v_full := least(v_coins, greatest(0, public.rule('daily_coins_full') - v_earned));
  v_half := least(
    floor((v_coins - v_full) / 2.0),
    greatest(0, floor(public.rule('daily_coins_half') / 2)
                - greatest(0, v_earned - public.rule('daily_coins_full'))));
  v_coins := v_full + v_half;

  -- Bolsa: 400 + 25 por nivel (máx. 1.000); lo que no cabe va al Tesoro.
  v_cap := least(public.rule('purse_base') + public.rule('purse_per_level') * v_stats.level,
                 public.rule('purse_max'));
  v_wallet := least(v_coins, greatest(0, v_cap - v_stats.coins));
  v_treasury := v_coins - v_wallet;

  v_level := v_stats.level;
  v_cur := v_stats.current_xp + v_xp;
  v_next := v_stats.xp_to_next_level;
  while v_cur >= v_next loop
    v_cur := v_cur - v_next;
    v_level := v_level + 1;
    v_next := public._level_threshold(v_level);
  end loop;

  update public.character_stats
  set level = v_level,
      current_xp = v_cur,
      xp_to_next_level = v_next,
      coins = coins + v_wallet,
      treasury = treasury + v_treasury,
      hp_current = least(hp_max, greatest(0, hp_current + p_hp)),
      last_active_on = current_date,
      updated_at = now()
  where user_id = p_uid;

  if p_skill_id is not null and v_xp > 0 then
    update public.skills s
    set current_xp = x.cur, level = x.lvl, xp_to_next_level = x.nxt
    from (
      with recursive up (lvl, cur, nxt) as (
        select level, current_xp + v_xp, xp_to_next_level
        from public.skills where id = p_skill_id and user_id = p_uid
        union all
        select lvl + 1, cur - nxt, public._level_threshold(lvl + 1)
        from up where cur >= nxt
      )
      select lvl, cur, nxt from up order by lvl desc limit 1
    ) x
    where s.id = p_skill_id and s.user_id = p_uid;
  end if;

  insert into public.quest_log_entries
    (user_id, source_type, source_id, result, xp_awarded, coin_awarded, hp_change, skill_id)
  values (p_uid, p_source, p_source_id, p_result, v_xp, v_coins, p_hp, p_skill_id);

  return jsonb_build_object(
    'xp', v_xp, 'coins', v_wallet, 'treasury', v_treasury, 'hp_change', p_hp,
    'level', v_level, 'level_up', v_level > v_stats.level);
end $$;

-- Gastar: solo de la bolsa, nunca del Tesoro.
create or replace function public._spend(p_uid uuid, p_amount integer)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare v_left integer;
begin
  update public.character_stats
  set coins = coins - p_amount, updated_at = now()
  where user_id = p_uid and coins >= p_amount
  returning coins into v_left;
  if not found then
    raise exception 'not_enough_coins' using errcode = 'P0001';
  end if;
  return v_left;
end $$;

create or replace function public._hp_multiplier(p_uid uuid)
returns numeric
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce((
    select dl.hp_penalty_multiplier
    from public.game_master_settings g
    join public.difficulty_levels dl on dl.level = g.difficulty
    where g.user_id = p_uid), 1)
$$;

-- 3. Recompensa de tareas por reglas --------------------------------------
create or replace function public._task_xp(
  p_title text, p_priority public.urgency_level, p_goal_id uuid, p_project_id uuid)
returns integer
language sql
stable
security definer
set search_path = ''
as $$
  select (public.rule('task_xp_base')
    + case when array_length(regexp_split_to_array(trim(p_title), '\s+'), 1)
                >= public.rule('task_long_title_words')
           then public.rule('task_xp_long_title') else 0 end
    + case p_priority when 'high' then public.rule('task_xp_priority_high')
                      when 'medium' then public.rule('task_xp_priority_medium') else 0 end
    + case when p_goal_id is not null then public.rule('task_xp_goal')
           when p_project_id is not null then public.rule('task_xp_project') else 0 end
  )::integer
$$;

-- Se calcula al crear y no cambia al editar (anti-inflado, RF-112).
create or replace function public.set_task_reward()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  new.xp_reward := public._task_xp(new.title, new.priority, new.goal_id, new.project_id);
  new.coin_reward := round(new.xp_reward * public.rule('coin_ratio'));
  return new;
end $$;
drop trigger if exists trg_set_task_reward on public.tasks;
create trigger trg_set_task_reward before insert on public.tasks
  for each row execute function public.set_task_reward();

-- Las tareas abiertas pudieron traer recompensas del cliente: se recalculan.
update public.tasks
set xp_reward = public._task_xp(title, priority, goal_id, project_id),
    coin_reward = round(public._task_xp(title, priority, goal_id, project_id) * public.rule('coin_ratio'))
where status in ('pending', 'in_progress', 'delegated');

-- 4. Completar y golpear al jefe ------------------------------------------
create or replace function public._damage_boss(p_uid uuid, p_goal_id uuid, p_damage integer)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_goal public.goals;
  v_hp integer;
begin
  select * into v_goal from public.goals
  where id = p_goal_id and user_id = p_uid for update;
  if not found or v_goal.status in ('completed', 'expired') or v_goal.archived_at is not null then
    return null;
  end if;
  v_hp := greatest(0, v_goal.boss_current_hp - greatest(p_damage, 0));
  perform set_config('lifequest.internal', 'on', true);
  update public.goals
  set boss_current_hp = v_hp,
      status = case when v_hp = 0 then 'completed'::public.objective_status
                    when status = 'not_started' then 'in_progress'::public.objective_status
                    else status end
  where id = p_goal_id;
  if v_hp = 0 then
    -- shortcut: el diseño da también un título; falta el catálogo de títulos.
    return jsonb_build_object('boss_hp', 0, 'defeated', true,
      'victory', public._award(p_uid, 'goal', p_goal_id,
        public.rule('boss_victory_xp')::integer, public.rule('boss_victory_coins')::integer,
        v_goal.skill_id));
  end if;
  return jsonb_build_object('boss_hp', v_hp, 'defeated', false);
end $$;

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

-- shortcut: un proyecto se puede completar con ≥ 1 tarea hecha y ninguna
-- abierta; el diseño no fija la condición.
create or replace function public.complete_project(p_project_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_project public.projects;
  v_res jsonb;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  select * into v_project from public.projects
  where id = p_project_id and user_id = v_uid for update;
  if not found then
    raise exception 'project_not_found' using errcode = 'P0002';
  end if;
  if v_project.status in ('completed', 'expired') then
    raise exception 'project_not_open' using errcode = '22023';
  end if;
  if exists (select 1 from public.tasks
             where project_id = p_project_id and status in ('pending', 'in_progress', 'delegated')) then
    raise exception 'project_has_open_tasks' using errcode = '22023';
  end if;
  if not exists (select 1 from public.tasks
                 where project_id = p_project_id and status = 'completed') then
    raise exception 'project_has_no_completed_tasks' using errcode = '22023';
  end if;

  perform set_config('lifequest.internal', 'on', true);
  update public.projects set status = 'completed' where id = p_project_id;
  v_res := public._award(v_uid, 'project', p_project_id,
    public.rule('project_xp')::integer,
    round(public.rule('project_xp') * public.rule('coin_ratio'))::integer,
    v_project.skill_id);
  if v_project.goal_id is not null then
    v_res := v_res || jsonb_build_object('boss',
      public._damage_boss(v_uid, v_project.goal_id, public.rule('boss_damage_project')::integer));
  end if;
  return v_res;
end $$;

-- 5. Hábitos ---------------------------------------------------------------------
create or replace function public.complete_habit(p_habit_id uuid, p_day date)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_habit public.habits;
  v_prev date;
  v_streak integer;
  v_xp integer;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  if p_day is null or abs(p_day - current_date) > 1 then
    raise exception 'invalid_day' using errcode = '22023';
  end if;
  select * into v_habit from public.habits
  where id = p_habit_id and user_id = v_uid for update;
  if not found then
    raise exception 'habit_not_found' using errcode = 'P0002';
  end if;
  if v_habit.type <> 'good' then
    raise exception 'not_a_good_habit' using errcode = '22023';
  end if;
  if v_habit.frequency = 'specific_days'
     and not (extract(dow from p_day)::int = any (v_habit.specific_days)) then
    raise exception 'not_scheduled' using errcode = '22023';
  end if;
  if exists (select 1 from public.habit_records
             where habit_id = p_habit_id and completed_on = p_day) then
    raise exception 'already_completed' using errcode = '23505';
  end if;

  v_prev := p_day - 1;
  if v_habit.frequency = 'specific_days' then
    while not (extract(dow from v_prev)::int = any (v_habit.specific_days))
          and v_prev > p_day - 7 loop
      v_prev := v_prev - 1;
    end loop;
  end if;
  v_streak := case
    when exists (select 1 from public.habit_records
                 where habit_id = p_habit_id and completed_on = v_prev)
    then v_habit.current_streak + 1
    else 1
  end;

  insert into public.habit_records (habit_id, user_id, completed_on)
  values (p_habit_id, v_uid, p_day);
  update public.habits
  set current_streak = v_streak, best_streak = greatest(best_streak, v_streak)
  where id = p_habit_id;

  v_xp := public.rule('habit_good_xp')::integer;
  perform public._award(v_uid, 'habit', p_habit_id, v_xp,
    round(v_xp * public.rule('coin_ratio'))::integer, v_habit.skill_id);
end $$;

-- Mal hábito: un registro por evento; resta su gravedad × dificultad (RF-032).
create or replace function public.register_bad_habit(p_habit_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_habit public.habits;
  v_hp integer;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  select * into v_habit from public.habits where id = p_habit_id and user_id = v_uid;
  if not found then
    raise exception 'habit_not_found' using errcode = 'P0002';
  end if;
  if v_habit.type <> 'bad' then
    raise exception 'not_a_bad_habit' using errcode = '22023';
  end if;
  v_hp := -round(v_habit.hp_penalty * public._hp_multiplier(v_uid))::integer;
  insert into public.habit_records (habit_id, user_id, completed_on, hp_change)
  values (p_habit_id, v_uid, current_date, v_hp);
  return public._award(v_uid, 'habit', p_habit_id, 0, 0, v_habit.skill_id, 'failed', v_hp);
end $$;

-- 6. Cofre del día ------------------------------------------------------------
create or replace function public.claim_daily_chest()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  perform pg_advisory_xact_lock(hashtext('chest:' || v_uid::text));
  if exists (select 1 from public.quest_log_entries
             where user_id = v_uid and source_type = 'daily_chest'
               and occurred_at >= current_date and occurred_at < current_date + 1) then
    raise exception 'chest_already_claimed' using errcode = '23505';
  end if;
  if (select count(*) from public.quest_log_entries
      where user_id = v_uid and source_type in ('task', 'npc') and result = 'completed'
        and occurred_at >= current_date and occurred_at < current_date + 1)
     < public.rule('daily_chest_min_missions') then
    raise exception 'chest_locked' using errcode = '22023';
  end if;
  return public._award(v_uid, 'daily_chest', v_uid, 0,
    public.rule('daily_chest_coins')::integer);
end $$;

-- Permisos: las RPC para el usuario; los ayudantes internos, para nadie.
do $$
declare f text;
begin
  foreach f in array array[
    'public._level_threshold(integer)',
    'public._award(uuid, public.quest_source, uuid, integer, integer, uuid, public.quest_result, integer)',
    'public._spend(uuid, integer)',
    'public._hp_multiplier(uuid)',
    'public._task_xp(text, public.urgency_level, uuid, uuid)',
    'public._damage_boss(uuid, uuid, integer)'] loop
    execute format('revoke all on function %s from public, anon, authenticated', f);
  end loop;
  foreach f in array array[
    'public.complete_task(uuid)', 'public.complete_project(uuid)',
    'public.complete_habit(uuid, date)', 'public.register_bad_habit(uuid)',
    'public.claim_daily_chest()'] loop
    execute format('revoke all on function %s from public, anon', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;

commit;
