-- Migración 006 · Tienda, Refugio, Taverna y Mazmorra (requiere 005).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
-- Plan: docs/plan-cambios-esquema.md §5.2, §5.3, §5.5 y §5.6, pasos 4 a 9.
--
-- 1. purchase(code): Hotel (vida) y Mercado (Elixir 1 activo, Cofre 1 al día).
-- 2. buy_black_market(code, habit): Pase (1 al mes, máx. 2 guardados) y
--    Recuperar racha (1 al mes). use_recovery_pass(habit). Ventana de 48 h.
-- 3. upgrade_refuge(building): 4 niveles, precio 120 × 1,35^nivel.
-- 4. Taverna: máx. 3 NPC (+1 por Estandarte); request_npc_mission (gratis
--    cada 3 h, si no 15 Monedas).
-- 5. Mazmorra: bloques de 30 min, ciclos de 25/30/45, máx. 5 tareas;
--    activate_elixir y complete_dungeon_cycle (3 Monedas, ×1,5 XP con Elixir).

begin;

-- 1. Hotel y Mercado ------------------------------------------------------------
create or replace function public.purchase(p_code text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_item public.market_items;
  v_left integer;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  select * into v_item from public.market_items where code = p_code and is_active;
  if not found then
    raise exception 'item_not_found' using errcode = 'P0002';
  end if;
  perform pg_advisory_xact_lock(hashtext('shop:' || v_uid::text));

  if v_item.daily_limit is not null and (
    select count(*) from public.purchases
    where user_id = v_uid and market_item_id = v_item.id
      and purchased_at >= current_date and purchased_at < current_date + 1
  ) >= v_item.daily_limit then
    raise exception 'daily_limit_reached' using errcode = 'P0001';
  end if;
  if v_item.code = 'elixir' and (
    select count(*) from public.user_consumables
    where user_id = v_uid and kind = 'elixir' and status in ('stored', 'active')
  ) >= coalesce(v_item.active_limit, 1) then
    raise exception 'active_limit_reached' using errcode = 'P0001';
  end if;

  v_left := public._spend(v_uid, v_item.coin_cost);
  insert into public.purchases (user_id, market_item_id, coins_spent)
  values (v_uid, v_item.id, v_item.coin_cost);

  if v_item.category = 'hotel' then
    update public.character_stats
    set hp_current = least(hp_max, hp_current + coalesce(v_item.hp_restore, hp_max))
    where user_id = v_uid;
  elsif v_item.code in ('elixir', 'cofre') then
    insert into public.user_consumables (user_id, kind)
    values (v_uid, v_item.code::public.consumable_kind);
  end if;

  return jsonb_build_object('coins', v_left,
    'hp_current', (select hp_current from public.character_stats where user_id = v_uid));
end $$;

-- 2. Rachas: 48 h para salvarlas ----------------------------------------------
-- Devuelve la racha rota y marca el día perdido como recuperado, para que
-- complete_habit la siga contando.
create or replace function public._restore_streak(p_uid uuid, p_habit_id uuid)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_habit public.habits;
  v_streak integer;
begin
  select * into v_habit from public.habits
  where id = p_habit_id and user_id = p_uid for update;
  if not found then
    raise exception 'habit_not_found' using errcode = 'P0002';
  end if;
  if v_habit.broken_on is null or v_habit.broken_streak = 0
     or now() > (v_habit.broken_on + 1)::timestamptz
                + make_interval(hours => public.rule('streak_recovery_hours')::integer) then
    raise exception 'nothing_to_recover' using errcode = '22023';
  end if;
  insert into public.habit_records (habit_id, user_id, completed_on, recovered)
  values (p_habit_id, p_uid, v_habit.broken_on, true);
  v_streak := v_habit.broken_streak + v_habit.current_streak;
  update public.habits
  set current_streak = v_streak, best_streak = greatest(best_streak, v_streak),
      broken_streak = 0, broken_on = null
  where id = p_habit_id;
  return v_streak;
end $$;

create or replace function public.buy_black_market(p_code text, p_habit_id uuid default null)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_item public.black_market_items;
  v_left integer;
  v_streak integer;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  select * into v_item from public.black_market_items where code = p_code;
  if not found then
    raise exception 'item_not_found' using errcode = 'P0002';
  end if;
  perform pg_advisory_xact_lock(hashtext('black:' || v_uid::text));

  -- Se repone el día 1: el límite cuenta por mes natural.
  if v_item.monthly_limit is not null and (
    select count(*) from public.black_market_redemptions
    where user_id = v_uid and item_id = v_item.id
      and redeemed_at >= date_trunc('month', now())
  ) >= v_item.monthly_limit then
    raise exception 'monthly_limit_reached' using errcode = 'P0001';
  end if;

  if p_code = 'pase_recuperacion' then
    if (select count(*) from public.recovery_passes
        where user_id = v_uid and used_at is null)
       >= public.rule('recovery_pass_max_stored') then
      raise exception 'too_many_passes' using errcode = 'P0001';
    end if;
    v_left := public._spend(v_uid, v_item.coin_cost);
    insert into public.recovery_passes (user_id) values (v_uid);
  elsif p_code = 'recuperar_racha' then
    if p_habit_id is null then
      raise exception 'habit_required' using errcode = '22023';
    end if;
    v_streak := public._restore_streak(v_uid, p_habit_id);
    v_left := public._spend(v_uid, v_item.coin_cost);
  else
    raise exception 'item_not_available' using errcode = 'P0002';
  end if;

  insert into public.black_market_redemptions (user_id, item_id) values (v_uid, v_item.id);
  return jsonb_build_object('coins', v_left, 'streak', v_streak);
end $$;

create or replace function public.use_recovery_pass(p_habit_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_pass uuid;
  v_day date;
  v_streak integer;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  select id into v_pass from public.recovery_passes
  where user_id = v_uid and used_at is null
  order by acquired_at limit 1 for update;
  if not found then
    raise exception 'no_pass' using errcode = 'P0001';
  end if;
  select broken_on into v_day from public.habits where id = p_habit_id and user_id = v_uid;
  v_streak := public._restore_streak(v_uid, p_habit_id);
  update public.recovery_passes
  set used_at = now(), habit_id = p_habit_id, protected_day = v_day
  where id = v_pass;
  return jsonb_build_object('streak', v_streak);
end $$;

-- 3. Refugio (nunca da Monedas) ----------------------------------------------
-- ⚠️ Por confirmar: n del precio = nivel actual de esa mejora.
create or replace function public.upgrade_refuge(p_building public.refuge_building)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_level integer;
  v_price integer;
  v_left integer;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  insert into public.refuge_upgrades (user_id, building) values (v_uid, p_building)
  on conflict (user_id, building) do nothing;
  select level into v_level from public.refuge_upgrades
  where user_id = v_uid and building = p_building for update;
  if v_level >= public.rule('refuge_max_level') then
    raise exception 'max_level' using errcode = 'P0001';
  end if;
  v_price := round(public.rule('refuge_base_price') * power(public.rule('refuge_growth'), v_level));
  v_left := public._spend(v_uid, v_price);
  update public.refuge_upgrades set level = level + 1, updated_at = now()
  where user_id = v_uid and building = p_building;
  return jsonb_build_object('coins', v_left, 'level', v_level + 1, 'price', v_price);
end $$;

-- 4. Taverna ------------------------------------------------------------------
create or replace function public.enforce_npc_limit()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform pg_advisory_xact_lock(hashtext('npcs:' || new.user_id::text));
  if (select count(*) from public.npcs where user_id = new.user_id)
     >= public.rule('npc_base_limit') + coalesce((
          select level from public.refuge_upgrades
          where user_id = new.user_id and building = 'estandarte'), 0) then
    raise exception 'npc_limit_reached' using errcode = 'P0001';
  end if;
  return new;
end $$;
drop trigger if exists trg_enforce_npc_limit on public.npcs;
create trigger trg_enforce_npc_limit before insert on public.npcs
  for each row execute function public.enforce_npc_limit();

-- RPGenie diseña la misión como una tarea real (source = 'npc'); esto solo
-- cobra el atajo y marca el cooldown.
create or replace function public.request_npc_mission(p_npc_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_last timestamptz;
  v_cost integer := 0;
  v_left integer;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  select last_mission_at into v_last from public.npcs
  where id = p_npc_id and user_id = v_uid for update;
  if not found then
    raise exception 'npc_not_found' using errcode = 'P0002';
  end if;
  if v_last is not null
     and v_last > now() - make_interval(hours => public.rule('npc_free_hours')::integer) then
    v_cost := public.rule('npc_instant_cost')::integer;
    v_left := public._spend(v_uid, v_cost);
  end if;
  update public.npcs set last_mission_at = now() where id = p_npc_id;
  return jsonb_build_object('cost', v_cost, 'coins', v_left);
end $$;

-- 5. Mazmorra -------------------------------------------------------------------
alter table public.focus_sessions drop constraint if exists focus_sessions_shape;
alter table public.focus_sessions add constraint focus_sessions_shape
  check (cycle_minutes in (25, 30, 45) and total_minutes > 0 and total_minutes % 30 = 0) not valid;

-- El inicio lo pone el servidor: si el cliente lo adelantara, cobraría ciclos antes.
revoke insert, update on public.focus_sessions from authenticated, anon;
grant insert (user_id, total_minutes, cycle_minutes) on public.focus_sessions to authenticated;
grant update (status, ended_at) on public.focus_sessions to authenticated;

create or replace function public.enforce_session_tasks()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if (select count(*) from public.focus_session_tasks where session_id = new.session_id)
     >= public.rule('dungeon_max_tasks') then
    raise exception 'session_task_limit' using errcode = 'P0001';
  end if;
  if not exists (
    select 1 from public.tasks t join public.focus_sessions s on s.user_id = t.user_id
    where t.id = new.task_id and s.id = new.session_id) then
    raise exception 'task_not_found' using errcode = 'P0002';
  end if;
  return new;
end $$;
drop trigger if exists trg_enforce_session_tasks on public.focus_session_tasks;
create trigger trg_enforce_session_tasks before insert on public.focus_session_tasks
  for each row execute function public.enforce_session_tasks();

create or replace function public.activate_elixir()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  if exists (select 1 from public.user_consumables
             where user_id = v_uid and kind = 'elixir' and status = 'active') then
    raise exception 'elixir_already_active' using errcode = 'P0001';
  end if;
  update public.user_consumables set status = 'active', activated_at = now()
  where id = (select id from public.user_consumables
              where user_id = v_uid and kind = 'elixir' and status = 'stored'
              order by acquired_at limit 1);
  if not found then
    raise exception 'no_elixir' using errcode = 'P0001';
  end if;
end $$;

-- Un ciclo terminado: 3 Monedas (diseño) y XP del ciclo; el Elixir activo se
-- gasta en la primera Mazmorra de la sesión y vale para toda ella.
create or replace function public.complete_dungeon_cycle(p_session_id uuid, p_task_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_session public.focus_sessions;
  v_skill uuid;
  v_cycle integer;
  v_run uuid;
  v_xp numeric;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  select * into v_session from public.focus_sessions
  where id = p_session_id and user_id = v_uid for update;
  if not found then
    raise exception 'session_not_found' using errcode = 'P0002';
  end if;
  if v_session.status not in ('active', 'paused') then
    raise exception 'session_not_active' using errcode = '22023';
  end if;
  if not exists (select 1 from public.focus_session_tasks
                 where session_id = p_session_id and task_id = p_task_id) then
    raise exception 'task_not_in_session' using errcode = '22023';
  end if;
  -- Un ciclo no puede durar menos que su duración desde el inicio de la sesión.
  select count(*) + 1 into v_cycle from public.dungeon_runs where session_id = p_session_id;
  if now() < v_session.started_at + make_interval(mins => v_session.cycle_minutes * v_cycle) then
    raise exception 'cycle_not_finished' using errcode = '22023';
  end if;

  update public.user_consumables
  set status = 'used', used_at = now(), session_id = p_session_id
  where user_id = v_uid and kind = 'elixir' and status = 'active';

  v_xp := public.rule('dungeon_cycle_xp')
          * case when exists (select 1 from public.user_consumables
                              where session_id = p_session_id and kind = 'elixir')
                 then public.rule('elixir_xp_factor') else 1 end;
  select skill_id into v_skill from public.tasks where id = p_task_id;

  insert into public.dungeon_runs (session_id, task_id, cycle_number, completed, ended_at)
  values (p_session_id, p_task_id, v_cycle, true, now())
  returning id into v_run;
  return public._award(v_uid, 'dungeon', v_run, floor(v_xp)::integer,
    round(public.rule('dungeon_cycle_xp') * public.rule('coin_ratio'))::integer, v_skill)
    || jsonb_build_object('cycle', v_cycle);
end $$;

-- Permisos ---------------------------------------------------------------------
do $$
declare f text;
begin
  execute 'revoke all on function public._restore_streak(uuid, uuid) from public, anon, authenticated';
  foreach f in array array[
    'public.purchase(text)', 'public.buy_black_market(text, uuid)',
    'public.use_recovery_pass(uuid)', 'public.upgrade_refuge(public.refuge_building)',
    'public.request_npc_mission(uuid)', 'public.activate_elixir()',
    'public.complete_dungeon_cycle(uuid, uuid)'] loop
    execute format('revoke all on function %s from public, anon', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;

commit;
