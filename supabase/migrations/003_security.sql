-- Migración 003 · Seguridad de la economía (requiere 001 y 002).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
-- Plan: docs/plan-cambios-esquema.md §3 y paso 1.
--
-- CLAUDE.md §8: el cliente nunca escribe recompensas ni penalizaciones.
-- 1. Tablas de compras, canjes, pases, logros, inventario y Mazmorra: solo lectura.
-- 2. Catálogo del Marketplace: solo lectura (sin autorecompensas, RF-043).
-- 3. Tareas, hábitos, metas, proyectos, NPC y Game Master: el cliente edita
--    lo suyo, pero no las columnas de recompensa, vida del jefe, cooldown ni
--    límite de skills.
-- 4. Completar o vencer una tarea, proyecto o meta solo lo hace el servidor.
--
-- Las RPC (security definer) avisan con set_config('lifequest.internal','on',true);
-- el cliente no puede fijar ese valor porque PostgREST no expone set_config.

begin;

-- 1. Solo lectura ---------------------------------------------------------
do $$
declare t text;
begin
  foreach t in array array['purchases', 'hp_recovery_purchases',
    'black_market_redemptions', 'recovery_passes', 'user_achievements',
    'user_inventory'] loop
    execute format('drop policy if exists "own rows" on public.%I', t);
    execute format('drop policy if exists "read own rows" on public.%I', t);
    execute format(
      'create policy "read own rows" on public.%I for select using (auth.uid() = user_id)', t);
  end loop;
end $$;

drop policy if exists "own rows" on public.dungeon_runs;
drop policy if exists "read own rows" on public.dungeon_runs;
create policy "read own rows" on public.dungeon_runs
  for select using (exists (
    select 1 from public.focus_sessions fs
    where fs.id = dungeon_runs.session_id and fs.user_id = auth.uid()));

-- 2. Catálogo global de solo lectura --------------------------------------
drop policy if exists "manage own items" on public.market_items;
drop policy if exists "update own items" on public.market_items;
drop policy if exists "delete own items" on public.market_items;
drop policy if exists "read global or own items" on public.market_items;
drop policy if exists "read all" on public.market_items;
create policy "read all" on public.market_items
  for select using (auth.role() = 'authenticated' and user_id is null);

-- 3. Columnas que el cliente puede escribir -------------------------------
revoke insert, update on public.tasks from authenticated, anon;
grant insert (user_id, project_id, goal_id, skill_id, npc_id, parent_task_id,
              title, description, category, priority, due_date,
              estimated_minutes, difficulty, status, tags, repeat_rule,
              delegated_to, source)
  on public.tasks to authenticated;
grant update (project_id, goal_id, skill_id, npc_id, parent_task_id, title,
              description, category, priority, due_date, estimated_minutes,
              difficulty, status, tags, repeat_rule, delegated_to)
  on public.tasks to authenticated;

revoke insert, update on public.habits from authenticated, anon;
grant insert (user_id, skill_id, name, type, frequency, specific_days, hp_penalty)
  on public.habits to authenticated;
grant update (skill_id, name, type, frequency, specific_days, hp_penalty)
  on public.habits to authenticated;

revoke insert, update on public.goals from authenticated, anon;
grant insert (user_id, skill_id, title, smart_specific, smart_measurable,
              smart_achievable, smart_relevant, smart_timebound, start_date,
              due_date, status)
  on public.goals to authenticated;
grant update (skill_id, title, smart_specific, smart_measurable,
              smart_achievable, smart_relevant, smart_timebound, start_date,
              due_date, status)
  on public.goals to authenticated;

revoke insert, update on public.projects from authenticated, anon;
grant insert (user_id, goal_id, skill_id, title, description, start_date,
              end_date, urgency, status)
  on public.projects to authenticated;
grant update (goal_id, skill_id, title, description, start_date, end_date,
              urgency, status)
  on public.projects to authenticated;

revoke insert, update on public.npcs from authenticated, anon;
grant insert (user_id, name, avatar_url, banner_url, noble_mission, skill_id, frequency)
  on public.npcs to authenticated;
grant update (name, avatar_url, banner_url, noble_mission, skill_id, frequency)
  on public.npcs to authenticated;

-- El alta crea la fila (001); el usuario solo ajusta sus reglas.
revoke insert, update, delete on public.game_master_settings from authenticated, anon;
grant update (difficulty, notification_daily_limit, silence_window_start,
              silence_window_end, ignore_threshold, short_break_minutes,
              long_break_minutes, long_break_every_n_cycles)
  on public.game_master_settings to authenticated;

-- 4. Completar o vencer es cosa del servidor -----------------------------
create or replace function public.guard_server_status()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if coalesce(current_setting('lifequest.internal', true), '') = 'on' then
    return new;
  end if;
  if new.status::text in ('completed', 'expired')
     and (tg_op = 'INSERT' or old.status is distinct from new.status) then
    raise exception 'status_server_only' using errcode = '42501',
      hint = 'Usa la RPC de completar; vencer lo hace el job diario.';
  end if;
  return new;
end $$;

drop trigger if exists trg_guard_status on public.tasks;
create trigger trg_guard_status before insert or update of status on public.tasks
  for each row execute function public.guard_server_status();
drop trigger if exists trg_guard_status on public.goals;
create trigger trg_guard_status before insert or update of status on public.goals
  for each row execute function public.guard_server_status();
drop trigger if exists trg_guard_status on public.projects;
create trigger trg_guard_status before insert or update of status on public.projects
  for each row execute function public.guard_server_status();

commit;
