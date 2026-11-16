-- Instalación completa de LifeQuest en un proyecto de Supabase NUEVO (vacío).
-- Generado 2026-11-13: esquema base v1 + migraciones 001–071 en orden.
-- Pegar completo en Supabase → SQL Editor → Run. Solo para una base vacía:
-- en una base vieja choca (complete_habit de 001/005 vs. 037).

-- ===== base: tests/deployed_v1.sql =====
-- Esquema desplegado (v1) completo para las pruebas, según la exportación del
-- panel de Supabase del 2026-10-18: 31 tablas, 16 enums y RLS, en el estado
-- ANTERIOR a 001_home.sql (las pruebas aplican 001 y 002 encima).
-- Requiere los stubs de auth de bootstrap.mjs.

create type entity_type as enum ('task','project','goal');
create type brain_dump_status as enum ('pending','reference','someday','converted');
create type objective_status as enum ('not_started','in_progress','completed','expired');
create type urgency_level as enum ('low','medium','high');
create type difficulty_scale as enum ('easy','medium','hard');
create type task_status as enum ('pending','in_progress','completed','delegated','expired');
create type task_source as enum ('manual','gtd_diagnosis','smart_goal','npc','deep_working');
create type habit_type as enum ('good','bad');
create type habit_frequency as enum ('daily','specific_days');
create type session_status as enum ('active','paused','completed','cancelled');
create type npc_frequency as enum ('daily','weekly','monthly');
create type quest_source as enum ('task','project','habit','npc','goal');
create type quest_result as enum ('completed','failed');
create type market_category as enum ('descanso','indulgencia','experiencia');
create type difficulty_level as enum ('easy','normal','hard');
create type notification_type as enum ('critical','motivational','informational');

create table public.profiles (
  id uuid not null primary key references auth.users(id),
  display_name text, character_class text, identity_statement text, avatar_url text,
  created_at timestamptz not null default now());
create table public.character_stats (
  user_id uuid not null primary key references public.profiles(id),
  level int not null default 1, current_xp int not null default 0, xp_to_next_level int not null default 100,
  coins int not null default 0, hp_current int not null default 100, hp_max int not null default 100,
  is_weakened boolean not null default false, updated_at timestamptz not null default now());
create table public.vision_boards (
  user_id uuid not null primary key references public.profiles(id), content text,
  updated_at timestamptz not null default now());
create table public.skills (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id),
  name text not null, level int not null default 1, current_xp int not null default 0,
  xp_to_next_level int not null default 100, created_at timestamptz not null default now());
create table public.brain_dump_entries (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id),
  content text not null, status brain_dump_status not null default 'pending',
  converted_to_type entity_type, converted_to_id uuid, created_at timestamptz not null default now());
create table public.goals (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id),
  skill_id uuid references public.skills(id), title text not null,
  smart_specific text, smart_measurable text, smart_achievable text, smart_relevant text, smart_timebound text,
  start_date date, due_date date, status objective_status not null default 'not_started',
  boss_max_hp int not null default 100, boss_current_hp int not null default 100,
  created_at timestamptz not null default now());
create table public.projects (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id),
  goal_id uuid references public.goals(id), skill_id uuid references public.skills(id),
  title text not null, description text, start_date date, end_date date,
  urgency urgency_level not null default 'low', status objective_status not null default 'not_started',
  created_at timestamptz not null default now());
create table public.npcs (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id),
  name text not null, avatar_url text, banner_url text, noble_mission text,
  skill_id uuid not null references public.skills(id), frequency npc_frequency not null,
  last_mission_at timestamptz, created_at timestamptz not null default now());
create table public.tasks (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id),
  project_id uuid references public.projects(id), goal_id uuid references public.goals(id),
  skill_id uuid references public.skills(id), npc_id uuid references public.npcs(id),
  parent_task_id uuid references public.tasks(id), title text not null, description text, category text,
  priority urgency_level not null default 'low', due_date timestamptz, estimated_minutes int,
  difficulty difficulty_scale not null default 'medium', status task_status not null default 'pending',
  tags text[] not null default '{}', xp_reward int not null default 0, coin_reward int not null default 0,
  repeat_rule text, delegated_to text, source task_source not null default 'manual',
  completed_at timestamptz, created_at timestamptz not null default now());
create table public.resources (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id),
  npc_id uuid references public.npcs(id), title text not null, file_url text not null,
  created_at timestamptz not null default now());
create table public.calendar_events (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id),
  title text not null, event_date timestamptz not null, priority urgency_level not null default 'low',
  contact text, created_at timestamptz not null default now());
create table public.habits (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id),
  skill_id uuid references public.skills(id), name text not null, type habit_type not null,
  frequency habit_frequency not null default 'daily', specific_days int[],
  xp_reward int not null default 0, coin_reward int not null default 0, hp_penalty int not null default 0,
  created_at timestamptz not null default now());
create table public.habit_records (
  id uuid primary key default gen_random_uuid(), habit_id uuid not null references public.habits(id),
  user_id uuid not null references public.profiles(id), completed_on date not null,
  created_at timestamptz not null default now());
create table public.focus_sessions (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id),
  total_minutes int not null, cycle_minutes int not null, status session_status not null default 'active',
  started_at timestamptz not null default now(), ended_at timestamptz);
create table public.focus_session_tasks (
  session_id uuid not null references public.focus_sessions(id), task_id uuid not null references public.tasks(id),
  primary key (session_id, task_id));
create table public.dungeon_runs (
  id uuid primary key default gen_random_uuid(), session_id uuid not null references public.focus_sessions(id),
  task_id uuid not null references public.tasks(id), cycle_number int not null,
  completed boolean not null default false, xp_awarded int not null default 0, coin_awarded int not null default 0,
  started_at timestamptz not null default now(), ended_at timestamptz);
create table public.quest_log_entries (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id),
  source_type quest_source not null, source_id uuid not null, result quest_result not null,
  xp_awarded int not null default 0, coin_awarded int not null default 0, hp_change int not null default 0,
  occurred_at timestamptz not null default now());
create table public.hero_journal_entries (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id),
  entry_date date not null, narrative_text text not null, created_at timestamptz not null default now());
create table public.achievements (
  id uuid primary key default gen_random_uuid(), code text not null unique, name text not null,
  description text, is_hidden boolean not null default false);
create table public.user_achievements (
  user_id uuid not null references public.profiles(id), achievement_id uuid not null references public.achievements(id),
  unlocked_at timestamptz not null default now(), primary key (user_id, achievement_id));
create table public.inventory_items (
  id uuid primary key default gen_random_uuid(), name text not null, description text, icon_url text);
create table public.user_inventory (
  user_id uuid not null references public.profiles(id), item_id uuid not null references public.inventory_items(id),
  obtained_at timestamptz not null default now(), primary key (user_id, item_id));
create table public.market_items (
  id uuid primary key default gen_random_uuid(), user_id uuid references public.profiles(id),
  category market_category not null, name text not null, description text, coin_cost int not null,
  is_active boolean not null default true);
create table public.purchases (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id),
  market_item_id uuid not null references public.market_items(id), coins_spent int not null,
  purchased_at timestamptz not null default now());
create table public.hp_recovery_purchases (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id),
  hp_restored int not null, coins_spent int not null, purchased_at timestamptz not null default now());
create table public.black_market_items (
  id uuid primary key default gen_random_uuid(), name text not null, coin_cost int not null,
  cooldown_hours int not null, max_uses_per_user int);
create table public.black_market_redemptions (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id),
  item_id uuid not null references public.black_market_items(id), redeemed_at timestamptz not null default now());
create table public.recovery_passes (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id),
  used_at timestamptz not null default now(), cooldown_until timestamptz not null);
create table public.difficulty_levels (
  level difficulty_level primary key, xp_multiplier numeric not null, coin_multiplier numeric not null,
  hp_penalty_multiplier numeric not null);
create table public.game_master_settings (
  user_id uuid not null primary key references public.profiles(id),
  difficulty difficulty_level not null default 'normal', skill_limit int not null default 6,
  notification_daily_limit int, silence_window_start time, silence_window_end time,
  ignore_threshold int not null default 5, short_break_minutes int not null default 5,
  long_break_minutes int not null default 15, long_break_every_n_cycles int not null default 4);
create table public.notifications (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id),
  type notification_type not null, title text not null, message text not null,
  related_entity_type text, related_entity_id uuid, sent_at timestamptz, read_at timestamptz,
  ignored boolean not null default false, created_at timestamptz not null default now());

insert into public.difficulty_levels values ('easy',1.2,1.2,0.8),('normal',1,1,1),('hard',0.8,0.8,1.2);

-- RLS como en el proyecto, antes de 001.
do $$ declare t text; begin
  foreach t in array array['vision_boards','skills','brain_dump_entries','goals','projects','npcs','tasks',
    'resources','calendar_events','habits','habit_records','focus_sessions','purchases','hero_journal_entries',
    'user_achievements','user_inventory','hp_recovery_purchases','black_market_redemptions','recovery_passes',
    'game_master_settings','notifications','character_stats','quest_log_entries'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('create policy "own rows" on public.%I for all using (auth.uid() = user_id) with check (auth.uid() = user_id)', t);
  end loop;
  foreach t in array array['achievements','inventory_items','black_market_items','difficulty_levels'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format($p$create policy "read all" on public.%I for select using (auth.role() = 'authenticated')$p$, t);
  end loop;
  foreach t in array array['focus_session_tasks','dungeon_runs'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('create policy "own rows" on public.%I for all using (exists (select 1 from public.focus_sessions fs where fs.id = %I.session_id and fs.user_id = auth.uid())) with check (exists (select 1 from public.focus_sessions fs where fs.id = %I.session_id and fs.user_id = auth.uid()))', t, t, t);
  end loop;
end $$;
alter table public.profiles enable row level security;
create policy "own rows" on public.profiles for all using (auth.uid() = id) with check (auth.uid() = id);
alter table public.market_items enable row level security;
create policy "read global or own items" on public.market_items for select using ((user_id is null) or (auth.uid() = user_id));
create policy "manage own items" on public.market_items for insert with check (auth.uid() = user_id);
create policy "update own items" on public.market_items for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "delete own items" on public.market_items for delete using (auth.uid() = user_id);

-- Trigger del límite de skills tal como existe (002 reemplaza su cuerpo).
create function public.enforce_skill_limit() returns trigger language plpgsql as $$
begin
  if (select count(*) from public.skills where user_id = new.user_id) >= 6 then
    raise exception 'Skill limit reached';
  end if;
  return new;
end $$;
create trigger trg_enforce_skill_limit before insert on public.skills
  for each row execute function public.enforce_skill_limit();

grant usage on schema public to anon, authenticated;
grant all on all tables in schema public to anon, authenticated;
-- Como Supabase: lo que se cree después también se concede a anon/authenticated.
alter default privileges in schema public grant all on tables to anon, authenticated;
alter default privileges in schema public grant all on functions to anon, authenticated;

-- ===== 001_home.sql =====
-- Migración 001 · Lo que necesita el Home sobre el esquema desplegado
-- (supabase/schema_deployed.sql, v1). Ejecutar una vez en Supabase →
-- SQL Editor. Se puede volver a ejecutar sin romper nada.
--
-- 1. Rachas de hábitos buenos.
-- 2. is_weakened calculado por la base (RF-034).
-- 3. Perfil, estadísticas y Game Master al registrarse.
-- 4. Tablas económicas: el cliente solo lee (CLAUDE.md §8, anti-trampa).
-- 5. RPC complete_habit: registrar un hábito bueno y cobrar la recompensa.
-- 6. RPC home_dashboard: todo el Home en una sola llamada.

begin;

-- 1. Rachas ---------------------------------------------------------------
alter table public.habits
  add column if not exists current_streak integer not null default 0,
  add column if not exists best_streak integer not null default 0;

-- 2. Estado debilitado: HP ≤ 20 % de hp_max (RF-034). Nunca bloquea nada.
do $$
begin
  if not exists (
    select 1 from pg_attribute
    where attrelid = 'public.character_stats'::regclass
      and attname = 'is_weakened' and attgenerated = 's'
  ) then
    alter table public.character_stats drop column if exists is_weakened;
    alter table public.character_stats
      add column is_weakened boolean
      generated always as (hp_current * 5 <= hp_max) stored;
  end if;
end $$;

-- 3. Alta del personaje ---------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, nullif(trim(new.raw_user_meta_data ->> 'username'), ''))
  on conflict (id) do nothing;
  insert into public.character_stats (user_id) values (new.id)
  on conflict (user_id) do nothing;
  insert into public.game_master_settings (user_id) values (new.id)
  on conflict (user_id) do nothing;
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Usuarios que se registraron antes de este trigger.
insert into public.profiles (id, display_name)
select id, nullif(trim(raw_user_meta_data ->> 'username'), '') from auth.users
on conflict (id) do nothing;
insert into public.character_stats (user_id)
select id from public.profiles on conflict (user_id) do nothing;
insert into public.game_master_settings (user_id)
select id from public.profiles on conflict (user_id) do nothing;

-- 4. El cliente ve su oro, pero solo el servidor lo cambia ---------------
drop policy if exists "own rows" on public.character_stats;
drop policy if exists "read own rows" on public.character_stats;
create policy "read own rows" on public.character_stats
  for select using (auth.uid() = user_id);

drop policy if exists "own rows" on public.quest_log_entries;
drop policy if exists "read own rows" on public.quest_log_entries;
create policy "read own rows" on public.quest_log_entries
  for select using (auth.uid() = user_id);

-- Un registro de hábito suma racha y recompensa: solo entra por complete_habit.
drop policy if exists "own rows" on public.habit_records;
drop policy if exists "read own rows" on public.habit_records;
create policy "read own rows" on public.habit_records
  for select using (auth.uid() = user_id);

-- La racha la escribe el servidor; el resto del hábito lo edita su dueño.
revoke update on public.habits from authenticated, anon;
grant update (skill_id, name, type, frequency, specific_days, xp_reward,
              coin_reward, hp_penalty)
  on public.habits to authenticated;

-- 5. Registrar un hábito bueno -------------------------------------------
-- p_day es la fecha local del dispositivo; se acepta hoy ± 1 día (UTC) para
-- cubrir cualquier zona horaria sin permitir rellenar días pasados.
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
  v_xp_mult numeric := 1;
  v_coin_mult numeric := 1;
  v_weakened boolean;
  v_xp integer;
  v_coins integer;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  if p_day is null or abs(p_day - current_date) > 1 then
    raise exception 'invalid_day' using errcode = '22023';
  end if;

  -- for update: dos toques simultáneos no cobran dos veces.
  select * into v_habit from public.habits
  where id = p_habit_id and user_id = v_uid
  for update;
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
  if exists (
    select 1 from public.habit_records
    where habit_id = p_habit_id and completed_on = p_day
  ) then
    raise exception 'already_completed' using errcode = '23505';
  end if;

  -- La racha sigue si se cumplió el día programado anterior.
  v_prev := p_day - 1;
  if v_habit.frequency = 'specific_days' then
    while not (extract(dow from v_prev)::int = any (v_habit.specific_days))
          and v_prev > p_day - 7 loop
      v_prev := v_prev - 1;
    end loop;
  end if;
  v_streak := case
    when exists (
      select 1 from public.habit_records
      where habit_id = p_habit_id and completed_on = v_prev
    ) then v_habit.current_streak + 1
    else 1
  end;

  select dl.xp_multiplier, dl.coin_multiplier
  into v_xp_mult, v_coin_mult
  from public.game_master_settings g
  join public.difficulty_levels dl on dl.level = g.difficulty
  where g.user_id = v_uid;
  v_xp_mult := coalesce(v_xp_mult, 1);
  v_coin_mult := coalesce(v_coin_mult, 1);

  insert into public.character_stats (user_id) values (v_uid)
  on conflict (user_id) do nothing;
  select is_weakened into v_weakened from public.character_stats
  where user_id = v_uid
  for update;

  -- shortcut: xp_reward/coin_reward del hábito los fija el cliente al
  -- crearlo; pasarlos a valores del servidor al cerrar la economía (§11).
  v_xp := floor(v_habit.xp_reward * v_xp_mult
                * case when v_weakened then 0.9 else 1 end);
  v_coins := floor(v_habit.coin_reward * v_coin_mult
                   * case when v_weakened then 0.9 else 1 end);

  insert into public.habit_records (habit_id, user_id, completed_on)
  values (p_habit_id, v_uid, p_day);

  update public.habits
  set current_streak = v_streak,
      best_streak = greatest(best_streak, v_streak)
  where id = p_habit_id;

  -- shortcut: al subir de nivel xp_to_next_level no cambia; la curva de
  -- niveles es una decisión abierta (CLAUDE.md §11).
  update public.character_stats
  set current_xp = (current_xp + v_xp) % xp_to_next_level,
      level = level + (current_xp + v_xp) / xp_to_next_level,
      coins = coins + v_coins,
      updated_at = now()
  where user_id = v_uid;

  if v_habit.skill_id is not null then
    update public.skills
    set current_xp = (current_xp + v_xp) % xp_to_next_level,
        level = level + (current_xp + v_xp) / xp_to_next_level
    where id = v_habit.skill_id and user_id = v_uid;
  end if;

  insert into public.quest_log_entries
    (user_id, source_type, source_id, result, xp_awarded, coin_awarded)
  values (v_uid, 'habit', p_habit_id, 'completed', v_xp, v_coins);
end $$;

revoke all on function public.complete_habit(uuid, date) from public, anon;
grant execute on function public.complete_habit(uuid, date) to authenticated;

-- 6. Datos del Home ------------------------------------------------------
-- security invoker: lee con el RLS del usuario. p_day y p_utc_offset_minutes
-- definen "hoy" en la zona horaria del dispositivo.
-- Misión prioritaria (RF-097): crítica (vencida o vence en < 24 h) →
-- urgencia high > medium > low → fecha límite más próxima.
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

revoke all on function public.home_dashboard(date, integer) from public, anon;
grant execute on function public.home_dashboard(date, integer) to authenticated;

commit;

-- ===== 002_profile.sql =====
-- Migración 002 · Perfil del Personaje (requiere 001_home.sql).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- 1. Skills: el usuario solo elige el nombre; nivel y XP los sube el servidor.
-- 2. Límite de skills con un motivo claro (CLAUDE.md §6, ampliable).
-- 3. Borrar una skill la quita de metas, proyectos, tareas y hábitos
--    (ON DELETE SET NULL); un NPC la exige, así que ahí se impide.
-- 4. Longitudes válidas de nombre e identidad.
-- 5. RPC profile_overview: todo el Perfil en una sola llamada.

begin;

-- 1. Skills: nivel y XP fuera del alcance del cliente --------------------
revoke insert, update on public.skills from authenticated, anon;
grant insert (user_id, name), update (name) on public.skills to authenticated;

-- 2. Límite de skills -----------------------------------------------------
-- Reemplaza el cuerpo de la función que ya usa trg_enforce_skill_limit.
create or replace function public.enforce_skill_limit()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_limit integer;
begin
  select skill_limit into v_limit
  from public.game_master_settings where user_id = new.user_id;
  -- Bloquea las altas simultáneas del mismo usuario mientras cuenta.
  perform pg_advisory_xact_lock(hashtext('skills:' || new.user_id::text));
  if (select count(*) from public.skills where user_id = new.user_id)
     >= coalesce(v_limit, 6) then
    raise exception 'skill_limit_reached' using errcode = 'P0001';
  end if;
  return new;
end $$;

-- 3. Borrar una skill -------------------------------------------------------
alter table public.goals drop constraint if exists goals_skill_id_fkey,
  add constraint goals_skill_id_fkey foreign key (skill_id)
    references public.skills (id) on delete set null;
alter table public.projects drop constraint if exists projects_skill_id_fkey,
  add constraint projects_skill_id_fkey foreign key (skill_id)
    references public.skills (id) on delete set null;
alter table public.tasks drop constraint if exists tasks_skill_id_fkey,
  add constraint tasks_skill_id_fkey foreign key (skill_id)
    references public.skills (id) on delete set null;
alter table public.habits drop constraint if exists habits_skill_id_fkey,
  add constraint habits_skill_id_fkey foreign key (skill_id)
    references public.skills (id) on delete set null;
alter table public.npcs drop constraint if exists npcs_skill_id_fkey,
  add constraint npcs_skill_id_fkey foreign key (skill_id)
    references public.skills (id) on delete restrict;

-- 4. Longitudes -------------------------------------------------------------
-- not valid: no revisa filas antiguas, pero sí todo lo que se escriba.
alter table public.profiles drop constraint if exists profiles_display_name_length;
alter table public.profiles add constraint profiles_display_name_length
  check (char_length(trim(display_name)) between 1 and 40) not valid;
alter table public.profiles drop constraint if exists profiles_identity_length;
alter table public.profiles add constraint profiles_identity_length
  check (char_length(identity_statement) <= 280) not valid;
alter table public.skills drop constraint if exists skills_name_length;
alter table public.skills add constraint skills_name_length
  check (char_length(trim(name)) between 1 and 40) not valid;

-- El alta (001) recorta el nombre: un registro nunca falla por su longitud.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    nullif(left(trim(new.raw_user_meta_data ->> 'username'), 40), '')
  )
  on conflict (id) do nothing;
  insert into public.character_stats (user_id) values (new.id)
  on conflict (user_id) do nothing;
  insert into public.game_master_settings (user_id) values (new.id)
  on conflict (user_id) do nothing;
  return new;
end $$;

-- 5. Datos del Perfil -------------------------------------------------------
-- security invoker: lee con el RLS del usuario.
-- Tasa de finalización: misiones cumplidas / (cumplidas + falladas) en la
-- bitácora (quest_log_entries).
create or replace function public.profile_overview()
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  select jsonb_build_object(
    'display_name', p.display_name,
    'character_class', p.character_class,
    'identity_statement', p.identity_statement,
    'level', s.level,
    'current_xp', s.current_xp,
    'xp_to_next_level', s.xp_to_next_level,
    'coins', s.coins,
    'hp_current', s.hp_current,
    'hp_max', s.hp_max,
    'is_weakened', s.is_weakened,
    'quests_completed', (
      select count(*) from public.quest_log_entries q
      where q.user_id = p.id and q.result = 'completed'
    ),
    'quests_failed', (
      select count(*) from public.quest_log_entries q
      where q.user_id = p.id and q.result = 'failed'
    ),
    'skill_limit', coalesce(g.skill_limit, 6),
    'skills', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', k.id,
          'name', k.name,
          'level', k.level,
          'current_xp', k.current_xp,
          'xp_to_next_level', k.xp_to_next_level
        )
        order by k.created_at
      )
      from public.skills k
      where k.user_id = p.id
    ), '[]'::jsonb)
  )
  from public.profiles p
  left join public.character_stats s on s.user_id = p.id
  left join public.game_master_settings g on g.user_id = p.id
  where p.id = auth.uid()
$$;

revoke all on function public.profile_overview() from public, anon;
grant execute on function public.profile_overview() to authenticated;

commit;

-- ===== 003_security.sql =====
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

-- ===== 004_structure.sql =====
-- Migración 004 · Estructura del cierre del diseño (requiere 003).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
-- Plan: docs/plan-cambios-esquema.md §4 y §5. Decisiones del 2026-10-18:
-- debilitado < 30 de vida y −25 % de XP; 48 h para salvar una racha;
-- dificultad del diseño con Monedas iguales; archivo con archived_at;
-- Hotel dentro de market_items; tasks.category se borra.
--
-- 1. Se borra lo descartado: Diario del Héroe, tiempo estimado, dificultad y
--    categoría de tareas, autorecompensas y hp_recovery_purchases.
-- 2. Catálogo nuevo: Hotel y Mercado (market_items) y Mercado negro.
-- 3. Reglas del juego en una tabla (game_rules): valores de PRODUCT/ideas y
--    los provisionales marcados como tales.
-- 4. Columnas y tablas nuevas: Tesoro, último día activo, debilitado nuevo,
--    rachas de 48 h, pases guardados, Refugio, consumibles, títulos, archivo,
--    vínculo con el Vision Board y skill en la Bitácora.
--
-- ⚠️ Antes de borrar: si hero_journal_entries o hp_recovery_purchases tienen
-- filas, la migración se detiene. Respáldalas y vacíalas para continuar.

begin;

-- 0. Freno si hay datos que se perderían -----------------------------------
do $$
declare
  t text;
  v_has boolean;
begin
  foreach t in array array['hero_journal_entries', 'hp_recovery_purchases'] loop
    if to_regclass('public.' || t) is not null then
      execute format('select exists (select 1 from public.%I)', t) into v_has;
      if v_has then
        raise exception '% tiene filas: respáldalas y vacía la tabla antes de 004', t;
      end if;
    end if;
  end loop;
end $$;

-- 1. Lo descartado ----------------------------------------------------------
drop table if exists public.hero_journal_entries;        -- Diario del Héroe eliminado
drop table if exists public.hp_recovery_purchases;       -- el Hotel va en market_items
alter table public.tasks
  drop column if exists estimated_minutes,               -- RF-022 superado
  drop column if exists difficulty,
  drop column if exists category;
drop type if exists public.difficulty_scale;

-- Autorecompensas (RF-043): sus filas quedan inactivas como historial de compras.
do $$
begin
  if exists (select 1 from information_schema.columns
             where table_schema = 'public' and table_name = 'market_items'
               and column_name = 'user_id') then
    update public.market_items set is_active = false where user_id is not null;
    drop policy if exists "read all" on public.market_items;
    alter table public.market_items drop column user_id;
  end if;
end $$;
drop policy if exists "read all" on public.market_items;
create policy "read all" on public.market_items
  for select using (auth.role() = 'authenticated');

-- 2. Catálogo ----------------------------------------------------------------
-- market_category: descanso/indulgencia/experiencia → hotel/mercado.
do $$
begin
  if not exists (select 1 from pg_enum e join pg_type t on t.oid = e.enumtypid
                 where t.typname = 'market_category' and e.enumlabel = 'hotel') then
    alter type public.market_category rename to market_category_old;
    create type public.market_category as enum ('hotel', 'mercado');
    alter table public.market_items
      alter column category type public.market_category using 'mercado';
    drop type public.market_category_old;
  end if;
end $$;

alter table public.market_items
  add column if not exists code text,
  add column if not exists hp_restore integer,       -- null en Banquete: vida completa
  add column if not exists daily_limit integer,
  add column if not exists active_limit integer;
create unique index if not exists market_items_code_key on public.market_items (code);

insert into public.market_items (code, category, name, description, coin_cost, hp_restore, daily_limit, active_limit) values
  ('siesta',   'hotel',   'Siesta',             'Recupera 10 de vida.',                          30, 10,   null, null),
  ('posada',   'hotel',   'Noche en la posada', 'Recupera 25 de vida.',                          70, 25,   null, null),
  ('banquete', 'hotel',   'Banquete',           'Recupera toda la vida.',                        150, null, null, null),
  ('elixir',   'mercado', 'Elixir de enfoque',  '×1,5 de XP en tu próxima Mazmorra.',           40, null, null, 1),
  ('cofre',    'mercado', 'Cofre misterioso',   'Un consumible al azar; a veces, un título.',   60, null, 1,    null)
on conflict (code) do nothing;

alter table public.black_market_items
  add column if not exists code text,
  add column if not exists monthly_limit integer;
create unique index if not exists black_market_items_code_key on public.black_market_items (code);
insert into public.black_market_items (code, name, coin_cost, cooldown_hours, monthly_limit) values
  ('recuperar_racha',    'Recuperar racha',      150, 0, 1),
  ('pase_recuperacion',  'Pase de Recuperación',  90, 0, 1)
on conflict (code) do nothing;

-- 3. Reglas del juego ------------------------------------------------------
create table if not exists public.game_rules (
  key text primary key,
  value numeric not null,
  provisional boolean not null default false,
  note text
);
alter table public.game_rules enable row level security;
drop policy if exists "read all" on public.game_rules;
create policy "read all" on public.game_rules for select using (auth.role() = 'authenticated');
revoke insert, update, delete on public.game_rules from authenticated, anon;

insert into public.game_rules (key, value, provisional, note) values
  ('task_xp_base',              10,   false, 'XP base de una tarea'),
  ('task_xp_long_title',        10,   false, '+XP si el título tiene ≥ task_long_title_words palabras'),
  ('task_long_title_words',      5,   false, null),
  ('task_xp_priority_high',     10,   false, null),
  ('task_xp_priority_medium',    5,   false, null),
  ('task_xp_goal',              10,   false, 'tarea vinculada a una Meta'),
  ('task_xp_project',            5,   false, 'tarea vinculada a un Proyecto'),
  ('coin_ratio',               0.3,   false, 'Monedas = 30 % de la XP'),
  ('task_min_seconds',         120,   false, 'completar antes da el mínimo y 0 Monedas'),
  ('task_daily_coin_limit',     15,   false, 'tareas con Monedas al día'),
  ('daily_coins_full',          50,   false, 'primeras Monedas del día, completas'),
  ('daily_coins_half',          50,   false, 'siguientes Monedas del día, a la mitad'),
  ('purse_base',               400,   false, null),
  ('purse_per_level',           25,   false, null),
  ('purse_max',               1000,   false, null),
  ('level_base',               100,   false, 'XP para subir: level_base × nivel^level_exp'),
  ('level_exp',                1.5,   false, null),
  ('weakened_xp_factor',      0.75,   true,  '−25 % de XP con is_weakened (vida < 30)'),
  ('hp_deadline_missed',         5,   true,  'plazo incumplido'),
  ('hp_idle_day',                5,   true,  'día sin jugar'),
  ('hp_daily_good_habit',        4,   true,  'día con al menos un hábito bueno'),
  ('hp_huerto_per_level',        1,   true,  null),
  ('habit_good_xp',             10,   true,  'da 3 Monedas (rango del diseño: 2–4)'),
  ('dungeon_cycle_xp',          10,   true,  'da 3 Monedas por ciclo (diseño: 3)'),
  ('elixir_xp_factor',         1.5,   false, null),
  ('daily_chest_coins',         15,   false, null),
  ('daily_chest_min_missions',   3,   false, null),
  ('project_xp',               120,   true,  'da 36 Monedas (diseño: +36)'),
  ('boss_victory_xp',          300,   false, null),
  ('boss_victory_coins',        90,   false, null),
  ('boss_damage_project',       30,   true,  'daño al jefe por proyecto; la tarea daña su XP'),
  ('refuge_base_price',        120,   false, 'precio = base × growth^nivel actual'),
  ('refuge_growth',           1.35,   false, null),
  ('refuge_max_level',           4,   false, null),
  ('npc_base_limit',             3,   false, '+1 por nivel del Estandarte'),
  ('npc_free_hours',             3,   false, 'misión gratis cada 3 h'),
  ('npc_instant_cost',          15,   false, null),
  ('streak_recovery_hours',     48,   true,  null),
  ('recovery_pass_max_stored',   2,   false, null),
  ('dungeon_max_tasks',          5,   false, null)
on conflict (key) do nothing;

-- Dificultad: XP ×1,2 / ×1 / ×0,85; vida ×0,75 / ×1 / ×1,25; Monedas iguales.
update public.difficulty_levels set xp_multiplier = 1.2,  coin_multiplier = 1, hp_penalty_multiplier = 0.75 where level = 'easy';
update public.difficulty_levels set xp_multiplier = 1,    coin_multiplier = 1, hp_penalty_multiplier = 1    where level = 'normal';
update public.difficulty_levels set xp_multiplier = 0.85, coin_multiplier = 1, hp_penalty_multiplier = 1.25 where level = 'hard';

-- 4. Personaje: Tesoro, último día activo y debilitado nuevo ---------------
alter table public.character_stats
  add column if not exists treasury integer not null default 0,
  add column if not exists last_active_on date;
do $$
begin
  if not exists (select 1 from pg_attribute
                 where attrelid = 'public.character_stats'::regclass
                   and attname = 'is_weakened' and attgenerated = 's'
                   and pg_get_expr((select adbin from pg_attrdef
                                    where adrelid = attrelid and adnum = attnum), attrelid)
                       like '%< 30%') then
    alter table public.character_stats drop column if exists is_weakened;
    alter table public.character_stats
      add column is_weakened boolean generated always as (hp_current < 30) stored;
  end if;
end $$;

-- Bitácora: skill para las estadísticas por Área; fuentes nuevas.
alter table public.quest_log_entries
  add column if not exists skill_id uuid references public.skills (id) on delete set null;
alter type public.quest_source add value if not exists 'dungeon';
alter type public.quest_source add value if not exists 'daily_chest';
alter type public.quest_source add value if not exists 'achievement';

-- Hábitos: gravedad del malo, vida por evento, rachas rotas y días recuperados.
alter table public.habits
  add column if not exists broken_streak integer not null default 0,
  add column if not exists broken_on date;
alter table public.habits drop constraint if exists habits_hp_penalty_by_type;
alter table public.habits add constraint habits_hp_penalty_by_type
  check ((type = 'good' and hp_penalty = 0)
         or (type = 'bad' and hp_penalty in (3, 5, 8))) not valid;
alter table public.habit_records
  add column if not exists hp_change integer not null default 0,
  add column if not exists recovered boolean not null default false;

-- Pases: ahora se guardan (acquired_at) y se usan sobre un hábito y un día.
alter table public.recovery_passes
  add column if not exists acquired_at timestamptz not null default now(),
  add column if not exists habit_id uuid references public.habits (id) on delete set null,
  add column if not exists protected_day date;
alter table public.recovery_passes alter column used_at drop not null;
alter table public.recovery_passes alter column used_at drop default;
alter table public.recovery_passes alter column cooldown_until drop not null;

-- Refugio --------------------------------------------------------------------
do $$ begin
  create type public.refuge_building as enum ('huerto', 'biblioteca', 'estandarte');
exception when duplicate_object then null; end $$;
create table if not exists public.refuge_upgrades (
  user_id uuid not null references public.profiles (id) on delete cascade,
  building public.refuge_building not null,
  level integer not null default 0 check (level between 0 and 4),
  updated_at timestamptz not null default now(),
  primary key (user_id, building)
);
alter table public.refuge_upgrades enable row level security;
drop policy if exists "read own rows" on public.refuge_upgrades;
create policy "read own rows" on public.refuge_upgrades for select using (auth.uid() = user_id);

-- Consumibles (Elixir, Cofre) ----------------------------------------------
do $$ begin
  create type public.consumable_kind as enum ('elixir', 'cofre');
exception when duplicate_object then null; end $$;
do $$ begin
  create type public.consumable_status as enum ('stored', 'active', 'used');
exception when duplicate_object then null; end $$;
create table if not exists public.user_consumables (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  kind public.consumable_kind not null,
  status public.consumable_status not null default 'stored',
  session_id uuid references public.focus_sessions (id) on delete set null,
  acquired_at timestamptz not null default now(),
  activated_at timestamptz,
  used_at timestamptz
);
create index if not exists user_consumables_user_idx on public.user_consumables (user_id, kind, status);
alter table public.user_consumables enable row level security;
drop policy if exists "read own rows" on public.user_consumables;
create policy "read own rows" on public.user_consumables for select using (auth.uid() = user_id);

-- Títulos de prestigio (se ganan, no se compran) ---------------------------
create table if not exists public.titles (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  description text
);
alter table public.titles enable row level security;
drop policy if exists "read all" on public.titles;
create policy "read all" on public.titles for select using (auth.role() = 'authenticated');
revoke insert, update, delete on public.titles from authenticated, anon;

create table if not exists public.user_titles (
  user_id uuid not null references public.profiles (id) on delete cascade,
  title_id uuid not null references public.titles (id) on delete cascade,
  earned_at timestamptz not null default now(),
  primary key (user_id, title_id)
);
alter table public.user_titles enable row level security;
drop policy if exists "read own rows" on public.user_titles;
create policy "read own rows" on public.user_titles for select using (auth.uid() = user_id);

alter table public.profiles
  add column if not exists active_title_id uuid references public.titles (id) on delete set null;

-- Solo se luce un título ganado.
create or replace function public.check_active_title()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.active_title_id is not null and not exists (
    select 1 from public.user_titles
    where user_id = new.id and title_id = new.active_title_id) then
    raise exception 'title_not_earned' using errcode = '42501';
  end if;
  return new;
end $$;
drop trigger if exists trg_check_active_title on public.profiles;
create trigger trg_check_active_title before insert or update of active_title_id on public.profiles
  for each row execute function public.check_active_title();

-- Logros con recompensa (50–200 Monedas) y progreso.
alter table public.achievements
  add column if not exists reward_coins integer not null default 0,
  add column if not exists target integer,
  add column if not exists title_id uuid references public.titles (id) on delete set null;

-- Archivo y Vision Board -----------------------------------------------------
alter table public.goals
  add column if not exists archived_at timestamptz,
  add column if not exists linked_to_vision boolean not null default false;
alter table public.projects
  add column if not exists archived_at timestamptz,
  add column if not exists linked_to_vision boolean not null default false;
alter table public.resources add column if not exists archived_at timestamptz;
grant insert (archived_at, linked_to_vision), update (archived_at, linked_to_vision)
  on public.goals to authenticated;
grant insert (archived_at, linked_to_vision), update (archived_at, linked_to_vision)
  on public.projects to authenticated;

commit;

-- ===== 005_rewards.sql =====
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

-- ===== 006_store.sql =====
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

-- ===== 007_daily.sql =====
-- Migración 007 · Job diario, avisos y vistas (requiere 006).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
-- Plan: docs/plan-cambios-esquema.md §5.4, §5.5, §5.7, pasos 5, 8 y 10.
--
-- 1. daily_maintenance(día): vence plazos (−5 de vida, RF-030), rompe rachas
--    (guarda la racha 48 h para salvarla), +4 de vida si hubo hábito bueno
--    (+1 por nivel del Huerto) o −5 si no se jugó. Corre con pg_cron.
-- 2. Notificaciones anti-estrés: event_key único, categoría, digest y
--    frecuencia decreciente al ignorar 5 seguidas (CLAUDE.md §7).
-- 3. Vistas v_daily_highlight (RF-089) y v_user_store (RF-048).
--
-- ⚠️ pg_cron: actívalo en Supabase → Database → Extensions antes de ejecutar;
-- si no está, la migración crea todo menos la programación (aviso en NOTICE).

begin;

-- 1. Job diario -------------------------------------------------------------------
-- Días ya procesados: la vida diaria se aplica una sola vez por día.
create table if not exists public.daily_runs (
  day date primary key,
  ran_at timestamptz not null default now()
);
alter table public.daily_runs enable row level security;
revoke all on public.daily_runs from authenticated, anon;

-- p_day = el día que terminó (UTC). Se puede repetir para un mismo día sin
-- castigar dos veces: cada plazo vence una sola vez y cada racha se rompe una vez.
-- shortcut: los ajustes diarios de vida no van a la Bitácora (no tienen
-- source_id); sumar una fuente 'daily' si el Diario debe mostrarlos.
create or replace function public.daily_maintenance(p_day date default current_date - 1)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_end timestamptz := (p_day + 1)::timestamptz;
  v_hp integer := public.rule('hp_deadline_missed')::integer;
  v_row record;
  v_expired integer := 0;
  v_broken integer := 0;
begin
  perform set_config('lifequest.internal', 'on', true);

  -- Plazos incumplidos: tarea, proyecto o meta (mismo valor, RF-030).
  for v_row in
    update public.tasks set status = 'expired'
    where status in ('pending', 'in_progress') and parent_task_id is null
      and due_date is not null and due_date < v_end
    returning id, user_id, skill_id, 'task'::public.quest_source as src
  loop
    perform public._award(v_row.user_id, v_row.src, v_row.id, 0, 0, v_row.skill_id, 'failed',
      -round(v_hp * public._hp_multiplier(v_row.user_id))::integer);
    v_expired := v_expired + 1;
  end loop;
  for v_row in
    update public.projects set status = 'expired'
    where status in ('not_started', 'in_progress') and archived_at is null
      and end_date is not null and end_date <= p_day
    returning id, user_id, skill_id
  loop
    perform public._award(v_row.user_id, 'project', v_row.id, 0, 0, v_row.skill_id, 'failed',
      -round(v_hp * public._hp_multiplier(v_row.user_id))::integer);
    v_expired := v_expired + 1;
  end loop;
  -- «El jefe escapó… por ahora»: se conserva la XP de cada golpe.
  for v_row in
    update public.goals set status = 'expired'
    where status in ('not_started', 'in_progress') and archived_at is null
      and due_date is not null and due_date <= p_day
    returning id, user_id, skill_id
  loop
    perform public._award(v_row.user_id, 'goal', v_row.id, 0, 0, v_row.skill_id, 'failed',
      -round(v_hp * public._hp_multiplier(v_row.user_id))::integer);
    v_expired := v_expired + 1;
  end loop;

  -- Rachas: las que caducaron su ventana de 48 h se olvidan.
  update public.habits set broken_streak = 0, broken_on = null
  where broken_on is not null
    and (broken_on + 1)::timestamptz
        + make_interval(hours => public.rule('streak_recovery_hours')::integer) <= v_end;

  -- Rachas rotas hoy: hábito bueno programado en p_day sin registro.
  update public.habits h
  set broken_streak = h.current_streak, broken_on = p_day, current_streak = 0
  where h.type = 'good' and h.current_streak > 0
    and (h.frequency = 'daily' or extract(dow from p_day)::int = any (h.specific_days))
    and h.created_at < v_end
    and not exists (select 1 from public.habit_records r
                    where r.habit_id = h.id and r.completed_on = p_day);
  get diagnostics v_broken = row_count;

  -- Vida del día: +4 (+Huerto) con un hábito bueno; −5 si no hubo actividad.
  update public.character_stats s
  set hp_current = least(s.hp_max, greatest(0, s.hp_current + d.delta)), updated_at = now()
  from (
    select p.id as user_id,
      case
        when exists (select 1 from public.habit_records r join public.habits h on h.id = r.habit_id
                     where r.user_id = p.id and r.completed_on = p_day
                       and h.type = 'good' and not r.recovered)
        then (public.rule('hp_daily_good_habit') + public.rule('hp_huerto_per_level')
              * coalesce((select level from public.refuge_upgrades
                          where user_id = p.id and building = 'huerto'), 0))::integer
        when not exists (select 1 from public.quest_log_entries q
                         where q.user_id = p.id and q.result = 'completed'
                           and q.occurred_at >= p_day::timestamptz and q.occurred_at < v_end)
        then -round(public.rule('hp_idle_day') * public._hp_multiplier(p.id))::integer
        else 0
      end as delta
    from public.profiles p
    where p.created_at < p_day::timestamptz
  ) d
  where s.user_id = d.user_id and d.delta <> 0
    -- Una sola vez por día (daily_runs).
    and not exists (select 1 from public.daily_runs dr where dr.day = p_day);

  insert into public.daily_runs (day) values (p_day) on conflict (day) do nothing;
  return jsonb_build_object('day', p_day, 'expired', v_expired, 'streaks_broken', v_broken);
end $$;

revoke all on function public.daily_maintenance(date) from public, anon, authenticated;

do $$
begin
  begin
    create extension if not exists pg_cron;
  exception when others then
    raise notice 'pg_cron no disponible: programa daily_maintenance() a mano (%).', sqlerrm;
  end;
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    perform cron.unschedule(jobid) from cron.job where jobname = 'lifequest_daily';
    perform cron.schedule('lifequest_daily', '5 0 * * *', 'select public.daily_maintenance()');
  end if;
end $$;

-- 2. Notificaciones ------------------------------------------------------------
do $$ begin
  create type public.digest_slot as enum ('morning', 'evening');
exception when duplicate_object then null; end $$;

alter table public.notifications
  add column if not exists event_key text,
  add column if not exists category text,
  add column if not exists digest_slot public.digest_slot;
-- Nunca notificar dos veces el mismo evento: <categoría>:<entidad_id>:<fecha>.
create unique index if not exists notifications_event_key_key
  on public.notifications (user_id, event_key) where event_key is not null;

alter table public.game_master_settings
  add column if not exists critical_bypass_silence boolean not null default false,
  add column if not exists digest_time time;
grant update (critical_bypass_silence, digest_time) on public.game_master_settings to authenticated;

create table if not exists public.notification_category_state (
  user_id uuid not null references public.profiles (id) on delete cascade,
  category text not null,
  consecutive_ignored integer not null default 0,
  reduced boolean not null default false,
  updated_at timestamptz not null default now(),
  primary key (user_id, category)
);
alter table public.notification_category_state enable row level security;
drop policy if exists "read own rows" on public.notification_category_state;
create policy "read own rows" on public.notification_category_state
  for select using (auth.uid() = user_id);

create or replace function public.track_notification_ignored()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare v_threshold integer;
begin
  if new.category is null then
    return new;
  end if;
  select ignore_threshold into v_threshold from public.game_master_settings where user_id = new.user_id;
  if new.ignored and not old.ignored then
    insert into public.notification_category_state as s (user_id, category, consecutive_ignored)
    values (new.user_id, new.category, 1)
    on conflict (user_id, category) do update
    set consecutive_ignored = s.consecutive_ignored + 1,
        reduced = s.consecutive_ignored + 1 >= coalesce(v_threshold, 5),
        updated_at = now();
  elsif new.read_at is not null and old.read_at is null then
    update public.notification_category_state
    set consecutive_ignored = 0, reduced = false, updated_at = now()
    where user_id = new.user_id and category = new.category;
  end if;
  return new;
end $$;
drop trigger if exists trg_track_notification_ignored on public.notifications;
create trigger trg_track_notification_ignored after update of ignored, read_at on public.notifications
  for each row execute function public.track_notification_ignored();

-- 3. Vistas ------------------------------------------------------------------------
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
where t.parent_task_id is null and t.status in ('pending', 'in_progress', 'delegated');

create table if not exists public.user_market_selection (
  user_id uuid not null references public.profiles (id) on delete cascade,
  market_item_id uuid not null references public.market_items (id) on delete cascade,
  primary key (user_id, market_item_id)
);
alter table public.user_market_selection enable row level security;
drop policy if exists "own rows" on public.user_market_selection;
create policy "own rows" on public.user_market_selection
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Sin selección se ve todo el catálogo; con selección, solo lo elegido (RF-048).
create or replace view public.v_user_store with (security_invoker = true) as
select m.id, m.code, m.category, m.name, m.description, m.coin_cost, m.hp_restore,
       m.daily_limit, m.active_limit
from public.market_items m
where m.is_active
  and (not exists (select 1 from public.user_market_selection s where s.user_id = auth.uid())
       or exists (select 1 from public.user_market_selection s
                  where s.user_id = auth.uid() and s.market_item_id = m.id));

grant select on public.v_daily_highlight, public.v_user_store to authenticated;

commit;

-- ===== 008_fix_exploits.sql =====
-- Migración 008 · Corrección de seguridad de la economía (requiere 003–007).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar y se
-- aplica aunque ya haya datos que violen las reglas nuevas (solo las impone
-- desde ahora; lo ya cobrado lo detecta el informe del bloque 5).
-- Spec: specs/002-fix-economy-exploits/.
--
-- 1. guard_server_status: lo completado o vencido no se reabre desde el cliente.
-- 2. Mazmorra: tope de ciclos por sesión, una sesión cerrada no se reabre y
--    una sola sesión abierta (activa o en pausa) por usuario.
-- 3. claim_daily_chest: cuenta solo las misiones de hoy que dieron Monedas.
-- 4. complete_project: exige una tarea completada a task_min_seconds o más.
-- 5. audit_double_rewards(): informe de solo lectura para la service_role.

begin;

-- 1. RF-084: un estado final no se reabre ------------------------------------------
-- Mismo guardia de 003 (triggers trg_guard_status de tasks, projects y goals),
-- que ahora también rechaza salir de completed/expired: reabrir y volver a
-- completar cobraba otra vez (y repetía la victoria del jefe).
create or replace function public.guard_server_status()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if coalesce(current_setting('lifequest.internal', true), '') = 'on' then
    return new;
  end if;
  if tg_op = 'UPDATE' and old.status::text in ('completed', 'expired')
     and new.status is distinct from old.status then
    raise exception 'status_final' using errcode = '42501',
      hint = 'Lo cerrado no se reabre; crea una misión nueva.';
  end if;
  if new.status::text in ('completed', 'expired')
     and (tg_op = 'INSERT' or old.status is distinct from new.status) then
    raise exception 'status_server_only' using errcode = '42501',
      hint = 'Usa la RPC de completar; vencer lo hace el job diario.';
  end if;
  return new;
end $$;

-- 2a. Mazmorra: no se cobran más ciclos de los que caben en la sesión -------------
-- Cuerpo de 006 con el tope floor(total_minutes / cycle_minutes).
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
  if v_cycle > floor(v_session.total_minutes::numeric / v_session.cycle_minutes) then
    raise exception 'session_cycles_exhausted' using errcode = '22023';
  end if;
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

-- 2b. Una sesión terminada o cancelada no se reabre (el cliente sí pausa,
-- reanuda, termina y cancela con su grant update (status, ended_at) de 006).
create or replace function public.guard_session_status()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if coalesce(current_setting('lifequest.internal', true), '') = 'on' then
    return new;
  end if;
  if old.status in ('completed', 'cancelled') and new.status is distinct from old.status then
    raise exception 'session_closed' using errcode = '42501',
      hint = 'Esta sesión ya terminó; empieza una nueva.';
  end if;
  return new;
end $$;
drop trigger if exists trg_guard_session_status on public.focus_sessions;
create trigger trg_guard_session_status before update of status on public.focus_sessions
  for each row execute function public.guard_session_status();

-- 2c. Una sola sesión abierta por usuario. Trigger y no índice único parcial:
-- el índice no se crearía si ya hay duplicados; el candado evita la carrera.
create or replace function public.enforce_one_open_session()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.status in ('active', 'paused') then
    perform pg_advisory_xact_lock(hashtext('session:' || new.user_id::text));
    if exists (select 1 from public.focus_sessions
               where user_id = new.user_id and status in ('active', 'paused')) then
      raise exception 'session_already_open' using errcode = 'P0001',
        hint = 'Termina o cierra la Mazmorra en curso antes de empezar otra.';
    end if;
  end if;
  return new;
end $$;
drop trigger if exists trg_one_open_session on public.focus_sessions;
create trigger trg_one_open_session before insert on public.focus_sessions
  for each row execute function public.enforce_one_open_session();

-- 3. Cofre del día: cuenta solo misiones que dieron Monedas -----------------------
-- Cuerpo de 005; las completadas al instante (0 Monedas) ya no abren el cofre.
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
        and coin_awarded > 0
        and occurred_at >= current_date and occurred_at < current_date + 1)
     < public.rule('daily_chest_min_missions') then
    raise exception 'chest_locked' using errcode = '22023';
  end if;
  return public._award(v_uid, 'daily_chest', v_uid, 0,
    public.rule('daily_chest_coins')::integer);
end $$;

-- 4. Proyecto: exige al menos una tarea hecha con trabajo real --------------------
-- Cuerpo de 005; misma regla de task_min_seconds que complete_task.
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
  if not exists (select 1 from public.tasks
                 where project_id = p_project_id and status = 'completed'
                   and completed_at - created_at >= make_interval(secs => public.rule('task_min_seconds'))) then
    raise exception 'project_no_real_work' using errcode = '22023',
      hint = 'Al menos una tarea del proyecto debe llevar más tiempo que el mínimo.';
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

-- 5. Informe de cobros repetidos (solo lectura, solo service_role) ----------------
-- No corrige nada: lista lo cobrado de más antes de 008 para que el equipo decida.
create or replace function public.audit_double_rewards()
returns table (kind text, user_id uuid, source_type text, source_id uuid,
               times integer, allowed integer, extra_xp integer, extra_coins integer)
language sql
stable
security definer
set search_path = ''
as $$
  -- La misma entidad cobrada más de una vez; de más = total − primer cobro.
  select 'duplicate_award', q.user_id, q.source_type::text, q.source_id, count(*)::integer, 1,
         (sum(q.xp_awarded) - (array_agg(q.xp_awarded order by q.occurred_at, q.id))[1])::integer,
         (sum(q.coin_awarded) - (array_agg(q.coin_awarded order by q.occurred_at, q.id))[1])::integer
  from public.quest_log_entries q
  where q.result = 'completed' and q.source_type::text in ('task', 'project', 'goal', 'npc')
  group by q.user_id, q.source_type, q.source_id
  having count(*) > 1
  union all
  -- Sesiones con más ciclos cobrados de los que caben.
  select 'dungeon_overcycled', s.user_id, 'dungeon', s.id, x.times, x.allowed, x.extra_xp, x.extra_coins
  from public.focus_sessions s
  cross join lateral (
    select count(distinct r.id)::integer as times,
           floor(s.total_minutes::numeric / s.cycle_minutes)::integer as allowed,
           coalesce(sum(q.xp_awarded) filter (
             where r.cycle_number > floor(s.total_minutes::numeric / s.cycle_minutes)), 0)::integer as extra_xp,
           coalesce(sum(q.coin_awarded) filter (
             where r.cycle_number > floor(s.total_minutes::numeric / s.cycle_minutes)), 0)::integer as extra_coins
    from public.dungeon_runs r
    left join public.quest_log_entries q on q.source_type = 'dungeon' and q.source_id = r.id
    where r.session_id = s.id
  ) x
  where x.times > x.allowed
  union all
  -- Usuarios con varias sesiones abiertas a la vez.
  select 'multiple_open_sessions', f.user_id, null::text, null::uuid, count(*)::integer, 1, 0, 0
  from public.focus_sessions f
  where f.status in ('active', 'paused')
  group by f.user_id
  having count(*) > 1
$$;

-- Permisos ---------------------------------------------------------------------
do $$
declare f text;
begin
  foreach f in array array[
    'public.guard_session_status()', 'public.enforce_one_open_session()',
    'public.audit_double_rewards()'] loop
    execute format('revoke all on function %s from public, anon, authenticated', f);
  end loop;
  foreach f in array array[
    'public.complete_dungeon_cycle(uuid, uuid)', 'public.claim_daily_chest()',
    'public.complete_project(uuid)'] loop
    execute format('revoke all on function %s from public, anon', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;

commit;

-- ===== 009_profile_titles.sql =====
-- Migración 009 · Perfil: Tesoro del reino y títulos de prestigio (requiere 001–008).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
-- Spec: specs/004-profile-update/.
--
-- 1. profile_overview: añade el Tesoro, el título activo y los títulos ganados
--    en la misma carga de 002.
-- 2. RPC set_active_title: luce un título ganado o ninguno; el trigger
--    check_active_title de 004 rechaza los no ganados.

begin;

-- 1. Datos del Perfil -------------------------------------------------------
-- Cuerpo de 002 más el Tesoro, el título activo y los ganados (orden de
-- obtención). security invoker: user_titles se lee con su RLS.
create or replace function public.profile_overview()
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  select jsonb_build_object(
    'display_name', p.display_name,
    'character_class', p.character_class,
    'identity_statement', p.identity_statement,
    'level', s.level,
    'current_xp', s.current_xp,
    'xp_to_next_level', s.xp_to_next_level,
    'coins', s.coins,
    'treasury', coalesce(s.treasury, 0),
    'hp_current', s.hp_current,
    'hp_max', s.hp_max,
    'is_weakened', s.is_weakened,
    'quests_completed', (
      select count(*) from public.quest_log_entries q
      where q.user_id = p.id and q.result = 'completed'
    ),
    'quests_failed', (
      select count(*) from public.quest_log_entries q
      where q.user_id = p.id and q.result = 'failed'
    ),
    'skill_limit', coalesce(g.skill_limit, 6),
    'skills', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', k.id,
          'name', k.name,
          'level', k.level,
          'current_xp', k.current_xp,
          'xp_to_next_level', k.xp_to_next_level
        )
        order by k.created_at
      )
      from public.skills k
      where k.user_id = p.id
    ), '[]'::jsonb),
    'active_title', (
      select jsonb_build_object('id', t.id, 'name', t.name, 'description', t.description)
      from public.titles t
      where t.id = p.active_title_id
    ),
    'titles', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', t.id,
          'name', t.name,
          'description', t.description,
          'earned_at', ut.earned_at
        )
        order by ut.earned_at
      )
      from public.user_titles ut
      join public.titles t on t.id = ut.title_id
      where ut.user_id = p.id
    ), '[]'::jsonb)
  )
  from public.profiles p
  left join public.character_stats s on s.user_id = p.id
  left join public.game_master_settings g on g.user_id = p.id
  where p.id = auth.uid()
$$;

-- 2. Elegir el título activo --------------------------------------------------
-- null quita el título. El trigger trg_check_active_title (004) rechaza con
-- title_not_earned lo que el jugador no ganó, también un id inexistente.
create or replace function public.set_active_title(p_title_id uuid)
returns void
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  update public.profiles set active_title_id = p_title_id where id = auth.uid();
end $$;

-- Permisos ---------------------------------------------------------------------
do $$
declare f text;
begin
  foreach f in array array['public.profile_overview()', 'public.set_active_title(uuid)'] loop
    execute format('revoke all on function %s from public, anon', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;

commit;

-- ===== 010_missions.sql =====
-- Migración 010 · Misiones: listar y crear tareas (requiere 001–009).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- 1. missions_overview: misiones abiertas en el orden del Daily Highlight
--    (RF-089, vista v_daily_highlight de 007) y las opciones para vincular
--    (skills, proyectos y metas abiertos) en una sola llamada.
-- 2. RPC create_task: crea la misión y sus subtareas en una transacción
--    (RF-016). La recompensa la pone el trigger trg_set_task_reward de 005.
-- Completar sigue siendo la RPC complete_task de 005.

begin;

-- 1. Datos de la pantalla Misiones -----------------------------------------
-- security invoker: todo se lee con el RLS de cada tabla.
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

-- 2. Crear misión -------------------------------------------------------------
-- security invoker: el insert pasa por el RLS y los grants de columna de 003.
-- Los vínculos se validan aquí porque la FK no comprueba el dueño. Las
-- subtareas no heredan Proyecto ni Meta: así no suman bonus ni golpean al jefe.
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

  foreach v_sub in array coalesce(p_subtasks, '{}') loop
    if trim(v_sub) <> '' then
      insert into public.tasks (user_id, parent_task_id, title, skill_id)
      values (v_uid, v_task.id, left(trim(v_sub), 200), p_skill_id);
    end if;
  end loop;

  return jsonb_build_object('id', v_task.id, 'xp_reward', v_task.xp_reward,
                            'coin_reward', v_task.coin_reward);
end $$;

-- Permisos ---------------------------------------------------------------------
do $$
declare f text;
begin
  foreach f in array array['public.missions_overview()',
    'public.create_task(text, text, public.urgency_level, timestamptz, uuid, uuid, uuid, text[])'] loop
    execute format('revoke all on function %s from public, anon', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;

commit;

-- ===== 011_habits.sql =====
-- Migración 011 · Hábitos: pantalla y alta de hábitos (requiere 001–010).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- 1. habits_overview(p_day): hábitos buenos y malos con su estado de hoy,
--    los últimos 7 días, el resumen semanal y los días del mes con al menos
--    un hábito bueno (mapa de calor), más las skills para vincular.
-- 2. RPC create_habit: valida frecuencia, gravedad (−3/−5/−8, RF-032) y skill.
-- Registrar sigue siendo complete_habit y register_bad_habit (005).
--
-- shortcut: register_bad_habit guarda el día UTC del servidor; cerca de
-- medianoche un evento puede contarse en el día vecino. Pasar p_day a esa
-- RPC si hace falta precisión local.

begin;

-- 1. Datos de la pantalla Hábitos ---------------------------------------------
-- security invoker: todo se lee con el RLS del usuario. p_day es la fecha
-- local del dispositivo.
create or replace function public.habits_overview(p_day date)
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  with week as (
    select generate_series(p_day - 6, p_day, interval '1 day')::date as day
  ),
  h as (
    select h.*,
           h.frequency = 'daily' or extract(dow from p_day)::int = any (h.specific_days) as scheduled_today
    from public.habits h
  ),
  -- Días de la semana en que tocaba cada hábito bueno (desde que existe).
  scheduled as (
    select h.id, w.day
    from h cross join week w
    where h.type = 'good' and w.day >= h.created_at::date
      and (h.frequency = 'daily' or extract(dow from w.day)::int = any (h.specific_days))
  )
  select jsonb_build_object(
    'habits', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', h.id,
        'name', h.name,
        'type', h.type,
        'frequency', h.frequency,
        'specific_days', coalesce(to_jsonb(h.specific_days), '[]'::jsonb),
        'skill_name', s.name,
        'hp_penalty', h.hp_penalty,
        'current_streak', coalesce(h.current_streak, 0),
        'best_streak', coalesce(h.best_streak, 0),
        'scheduled_today', h.scheduled_today,
        'done_today', exists (select 1 from public.habit_records r
                              where r.habit_id = h.id and r.completed_on = p_day),
        'today_count', (select count(*) from public.habit_records r
                        where r.habit_id = h.id and r.completed_on = p_day),
        'week', (select jsonb_agg(exists (select 1 from public.habit_records r
                                          where r.habit_id = h.id and r.completed_on = w.day)
                                  order by w.day)
                 from week w)
      ) order by h.type, h.created_at)
      from h left join public.skills s on s.id = h.skill_id
    ), '[]'::jsonb),
    'week_xp', (
      select coalesce(sum(q.xp_awarded), 0) from public.quest_log_entries q
      where q.source_type = 'habit' and q.occurred_at >= (p_day - 6)::timestamptz
    ),
    'week_done', (
      select count(*) from scheduled sc
      where exists (select 1 from public.habit_records r
                    where r.habit_id = sc.id and r.completed_on = sc.day)
    ),
    'week_scheduled', (select count(*) from scheduled),
    'bad_free_days', (
      select count(*) from week w
      where not exists (select 1 from public.habit_records r join h on h.id = r.habit_id
                        where h.type = 'bad' and r.completed_on = w.day)
    ),
    'month_days', coalesce((
      select jsonb_agg(distinct extract(day from r.completed_on)::int)
      from public.habit_records r join h on h.id = r.habit_id
      where h.type = 'good'
        and r.completed_on >= date_trunc('month', p_day)::date and r.completed_on <= p_day
    ), '[]'::jsonb),
    'skills', coalesce((
      select jsonb_agg(jsonb_build_object('id', id, 'name', name) order by created_at)
      from public.skills
    ), '[]'::jsonb)
  )
$$;

-- 2. Crear hábito -----------------------------------------------------------------
-- security invoker: el insert pasa por el RLS y los grants de columna de 003.
-- Un hábito malo se registra por evento: siempre es diario.
create or replace function public.create_habit(
  p_name text,
  p_type public.habit_type,
  p_frequency public.habit_frequency default 'daily',
  p_specific_days integer[] default null,
  p_hp_penalty integer default 0,
  p_skill_id uuid default null
)
returns uuid
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_name text := trim(coalesce(p_name, ''));
  v_days integer[];
  v_id uuid;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  if v_name = '' or length(v_name) > 100 then
    raise exception 'invalid_name' using errcode = '22023';
  end if;
  if p_type = 'bad' and coalesce(p_hp_penalty, 0) not in (3, 5, 8) then
    raise exception 'invalid_severity' using errcode = '22023';
  end if;
  if p_type = 'good' and p_frequency = 'specific_days' then
    select array_agg(distinct d order by d) into v_days
    from unnest(coalesce(p_specific_days, '{}')) d;
    if v_days is null or exists (select 1 from unnest(v_days) d where d not between 0 and 6) then
      raise exception 'invalid_days' using errcode = '22023';
    end if;
  end if;
  if p_skill_id is not null
     and not exists (select 1 from public.skills where id = p_skill_id and user_id = v_uid) then
    raise exception 'skill_not_found' using errcode = 'P0002';
  end if;

  insert into public.habits (user_id, skill_id, name, type, frequency, specific_days, hp_penalty)
  values (v_uid, p_skill_id, v_name, p_type,
          case when v_days is null then 'daily'::public.habit_frequency else 'specific_days' end,
          v_days, case when p_type = 'bad' then p_hp_penalty else 0 end)
  returning id into v_id;
  return v_id;
end $$;

-- Permisos ---------------------------------------------------------------------
do $$
declare f text;
begin
  foreach f in array array['public.habits_overview(date)',
    'public.create_habit(text, public.habit_type, public.habit_frequency, integer[], integer, uuid)'] loop
    execute format('revoke all on function %s from public, anon', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;

commit;

-- ===== 012_dungeon.sql =====
-- Migración 012 · Mazmorra (Deep Working): leer, iniciar y terminar la sesión
-- (requiere 001–011). Ejecutar una vez en Supabase → SQL Editor. Se puede
-- volver a ejecutar.
--
-- 1. dungeon_overview: la sesión abierta (si hay) con sus tareas, ciclos y lo
--    ganado, más las misiones abiertas para la mochila (máx. 5, §13).
-- 2. RPC start_dungeon: crea la sesión y su mochila en una transacción.
-- 3. RPC end_dungeon: cierra la sesión sin perder lo ganado y da el resumen.
-- Cobrar cada ciclo sigue siendo complete_dungeon_cycle (008), que valida el
-- tiempo transcurrido, el tope de ciclos y que la tarea esté en la sesión.
--
-- shortcut: RF-031 (vida perdida al cerrar con tareas sin completar) no se
-- aplica; su valor sigue abierto (docs/plan-cambios-esquema.md §7).

begin;

-- 1. Datos de la pantalla Mazmorra --------------------------------------------
-- security invoker: todo se lee con el RLS del usuario.
create or replace function public.dungeon_overview()
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  with s as (
    select * from public.focus_sessions
    where user_id = auth.uid() and status in ('active', 'paused')
    order by started_at desc limit 1
  ),
  runs as (
    select r.* from public.dungeon_runs r join s on s.id = r.session_id
  )
  select jsonb_build_object(
    'session', (
      select jsonb_build_object(
        'id', s.id,
        'total_minutes', s.total_minutes,
        'cycle_minutes', s.cycle_minutes,
        'started_at', s.started_at,
        'cycles_done', (select count(*) from runs),
        'xp_earned', (select coalesce(sum(q.xp_awarded), 0) from public.quest_log_entries q
                      where q.source_type = 'dungeon' and q.source_id in (select id from runs)),
        'coins_earned', (select coalesce(sum(q.coin_awarded), 0) from public.quest_log_entries q
                         where q.source_type = 'dungeon' and q.source_id in (select id from runs)),
        'tasks', coalesce((
          select jsonb_agg(jsonb_build_object(
            'id', t.id,
            'title', t.title,
            'done', t.status = 'completed',
            'cycles', (select count(*) from runs where runs.task_id = t.id)
          ) order by t.created_at)
          from public.focus_session_tasks f join public.tasks t on t.id = f.task_id
          where f.session_id = s.id
        ), '[]'::jsonb)
      )
      from s
    ),
    'candidates', coalesce((
      select jsonb_agg(jsonb_build_object('id', c.id, 'title', c.title, 'bucket', c.bucket)
                       order by c.bucket_order, c.due_date nulls last)
      from (select * from public.v_daily_highlight
            order by bucket_order, due_date nulls last limit 30) c
    ), '[]'::jsonb),
    'max_tasks', public.rule('dungeon_max_tasks')::integer,
    'cycle_xp', public.rule('dungeon_cycle_xp')::integer
  )
$$;

-- 2. Iniciar --------------------------------------------------------------------
-- security invoker: el insert pasa por el RLS, los grants de columna de 006
-- (started_at lo pone el servidor) y los triggers de una sola sesión abierta
-- y del tope de tareas.
create or replace function public.start_dungeon(
  p_total_minutes integer,
  p_cycle_minutes integer,
  p_task_ids uuid[]
)
returns uuid
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_tasks uuid[];
  v_session uuid;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  if p_cycle_minutes is null or p_cycle_minutes not in (25, 30, 45)
     or p_total_minutes is null or p_total_minutes % 30 <> 0
     or p_total_minutes < p_cycle_minutes or p_total_minutes > 480 then
    raise exception 'invalid_duration' using errcode = '22023';
  end if;
  select array_agg(distinct x) into v_tasks from unnest(coalesce(p_task_ids, '{}')) x;
  if v_tasks is null then
    raise exception 'no_tasks' using errcode = '22023';
  end if;
  if cardinality(v_tasks) > public.rule('dungeon_max_tasks') then
    raise exception 'session_task_limit' using errcode = 'P0001';
  end if;
  if (select count(*) from public.tasks
      where id = any (v_tasks) and user_id = v_uid
        and status in ('pending', 'in_progress', 'delegated')) <> cardinality(v_tasks) then
    raise exception 'task_not_found' using errcode = 'P0002';
  end if;

  insert into public.focus_sessions (user_id, total_minutes, cycle_minutes)
  values (v_uid, p_total_minutes, p_cycle_minutes)
  returning id into v_session;
  insert into public.focus_session_tasks (session_id, task_id)
  select v_session, unnest(v_tasks);
  return v_session;
end $$;

-- 3. Terminar ---------------------------------------------------------------------
create or replace function public.end_dungeon(p_session_id uuid)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_session public.focus_sessions;
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
  return (
    select jsonb_build_object(
      'cycles', count(r.id),
      'xp', coalesce(sum(q.xp_awarded), 0),
      'coins', coalesce(sum(q.coin_awarded), 0),
      'minutes', least(v_session.total_minutes,
                       floor(extract(epoch from v_session.ended_at - v_session.started_at) / 60)::integer)
    )
    from public.dungeon_runs r
    left join public.quest_log_entries q on q.source_type = 'dungeon' and q.source_id = r.id
    where r.session_id = p_session_id
  );
end $$;

-- Permisos ---------------------------------------------------------------------
do $$
declare f text;
begin
  foreach f in array array['public.dungeon_overview()',
    'public.start_dungeon(integer, integer, uuid[])', 'public.end_dungeon(uuid)'] loop
    execute format('revoke all on function %s from public, anon', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;

commit;

-- ===== 013_stage.sql =====
-- Migración 013 · Stage · P.A.R.A. (requiere 001–012).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- Stage es una vista: no tiene tablas propias. Lee tasks, projects, skills,
-- resources y lo archivado.
-- 1. stage_overview(p_day): Daily Highlight (RF-089), Proyectos con su
--    urgencia automática (RF-019/020, derivada, no se guarda), Áreas
--    (skills), Recursos y Archivo, en una sola llamada.
-- 2. RPC create_project y create_resource (Quick Add, RF-014: Proyecto y
--    Recurso se crean directo; la Tarea va por Misiones).
-- 3. RPC archive_item: manda un proyecto o recurso al Archivo.
-- Completar un proyecto sigue siendo complete_project (008).
--
-- shortcut: Quick Add no pasa por el Diagnosis G.T.D. ni por S.M.A.R.T.;
-- sumarlos cuando exista el Brain Dump. RF-021 (avisar cada cambio de
-- urgencia) queda para cuando haya notificaciones.

begin;

-- 1. Datos de la pantalla Stage ---------------------------------------------------
-- Urgencia: ritmo_necesario = restante / días_restantes y ritmo_actual =
-- hechas / días_transcurridos; > ×1,5 → high, > ×1,2 → medium, si no low.
-- Sin fecha de fin o sin tareas: low. Vencido con trabajo pendiente: high.
create or replace function public._project_urgency(
  p_total integer, p_done integer, p_start date, p_end date, p_day date)
returns public.urgency_level
language sql
immutable
set search_path = ''
as $$
  select case
    when p_end is null or p_total = 0 or p_done >= p_total then 'low'
    when p_end <= p_day then 'high'
    else (
      select case
        when needed > current_pace * 1.5 then 'high'
        when needed > current_pace * 1.2 then 'medium'
        else 'low' end
      from (select (p_total - p_done)::numeric / (p_end - p_day) as needed,
                   p_done::numeric / greatest(p_day - p_start, 1) as current_pace) r
    )
  end::public.urgency_level
$$;

create or replace function public.stage_overview(p_day date)
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  with p as (
    select p.*,
      (select count(*) from public.tasks t where t.project_id = p.id and t.parent_task_id is null)::int as total,
      (select count(*) from public.tasks t where t.project_id = p.id and t.parent_task_id is null
         and t.status = 'completed')::int as done
    from public.projects p
  )
  select jsonb_build_object(
    'highlight', coalesce((
      select jsonb_agg(jsonb_build_object('id', h.id, 'title', h.title, 'bucket', h.bucket,
                                          'due_date', h.due_date) order by h.n)
      -- Mismo orden que missions_overview (010): empata por antigüedad.
      from (select v.*, row_number() over (order by v.bucket_order, v.due_date nulls last,
                                                    t.created_at) n
            from public.v_daily_highlight v join public.tasks t on t.id = v.id) h
      where h.n <= 5
    ), '[]'::jsonb),
    'highlight_total', (select count(*) from public.v_daily_highlight),
    'projects', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', p.id,
        'title', p.title,
        'skill_name', s.name,
        'goal_title', g.title,
        'end_date', p.end_date,
        'tasks_total', p.total,
        'tasks_done', p.done,
        'urgency', public._project_urgency(p.total, p.done,
                     coalesce(p.start_date, p.created_at::date), p.end_date, p_day)
      ) order by p.end_date nulls last, p.created_at)
      from p
      left join public.skills s on s.id = p.skill_id
      left join public.goals g on g.id = p.goal_id
      where p.status in ('not_started', 'in_progress') and p.archived_at is null
    ), '[]'::jsonb),
    'areas', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', s.id,
        'name', s.name,
        'level', s.level,
        'open_tasks', (select count(*) from public.tasks t where t.skill_id = s.id
                         and t.parent_task_id is null
                         and t.status in ('pending', 'in_progress', 'delegated')),
        'projects', (select count(*) from public.projects pr where pr.skill_id = s.id
                       and pr.status in ('not_started', 'in_progress') and pr.archived_at is null),
        'habits', (select count(*) from public.habits hb where hb.skill_id = s.id)
      ) order by s.created_at)
      from public.skills s
    ), '[]'::jsonb),
    'resources', coalesce((
      select jsonb_agg(jsonb_build_object('id', r.id, 'title', r.title, 'url', r.file_url)
                       order by r.created_at desc)
      from public.resources r
      where r.archived_at is null
    ), '[]'::jsonb),
    'archive', jsonb_build_object(
      'projects', (select count(*) from public.projects
                   where archived_at is not null or status in ('completed', 'expired')),
      'goals', (select count(*) from public.goals
                where archived_at is not null or status in ('completed', 'expired')),
      'resources', (select count(*) from public.resources where archived_at is not null)
    ),
    'skills', coalesce((
      select jsonb_agg(jsonb_build_object('id', id, 'name', name) order by created_at)
      from public.skills
    ), '[]'::jsonb),
    'goals', coalesce((
      select jsonb_agg(jsonb_build_object('id', id, 'title', title) order by created_at)
      from public.goals
      where status in ('not_started', 'in_progress') and archived_at is null
    ), '[]'::jsonb)
  )
$$;

-- 2. Quick Add ---------------------------------------------------------------------
-- security invoker: los insert pasan por el RLS y los grants de columna de 003.
create or replace function public.create_project(
  p_title text,
  p_description text default null,
  p_end_date date default null,
  p_skill_id uuid default null,
  p_goal_id uuid default null
)
returns uuid
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_title text := trim(coalesce(p_title, ''));
  v_id uuid;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  if v_title = '' or length(v_title) > 200 then
    raise exception 'invalid_title' using errcode = '22023';
  end if;
  if p_end_date is not null and p_end_date < current_date - 1 then
    raise exception 'invalid_end_date' using errcode = '22023';
  end if;
  if p_skill_id is not null
     and not exists (select 1 from public.skills where id = p_skill_id and user_id = v_uid) then
    raise exception 'skill_not_found' using errcode = 'P0002';
  end if;
  if p_goal_id is not null and not exists (
    select 1 from public.goals where id = p_goal_id and user_id = v_uid
      and status in ('not_started', 'in_progress') and archived_at is null) then
    raise exception 'goal_not_found' using errcode = 'P0002';
  end if;
  insert into public.projects (user_id, title, description, start_date, end_date, skill_id, goal_id)
  values (v_uid, v_title, nullif(trim(coalesce(p_description, '')), ''), current_date,
          p_end_date, p_skill_id, p_goal_id)
  returning id into v_id;
  return v_id;
end $$;

create or replace function public.create_resource(p_title text, p_url text)
returns uuid
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_title text := trim(coalesce(p_title, ''));
  v_url text := trim(coalesce(p_url, ''));
  v_id uuid;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  if v_title = '' or length(v_title) > 200 then
    raise exception 'invalid_title' using errcode = '22023';
  end if;
  if v_url !~* '^https?://[^\s]+$' or length(v_url) > 2000 then
    raise exception 'invalid_url' using errcode = '22023';
  end if;
  insert into public.resources (user_id, title, file_url)
  values (v_uid, v_title, v_url)
  returning id into v_id;
  return v_id;
end $$;

-- 3. Archivo ---------------------------------------------------------------------
-- security definer: resources no tiene grant de update para el cliente; aquí
-- solo se toca archived_at de una fila propia.
create or replace function public.archive_item(p_kind text, p_id uuid)
returns void
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
  if p_kind = 'project' then
    update public.projects set archived_at = now()
    where id = p_id and user_id = v_uid and archived_at is null;
  elsif p_kind = 'resource' then
    update public.resources set archived_at = now()
    where id = p_id and user_id = v_uid and archived_at is null;
  else
    raise exception 'invalid_kind' using errcode = '22023';
  end if;
  if not found then
    raise exception 'item_not_found' using errcode = 'P0002';
  end if;
end $$;

-- Permisos ---------------------------------------------------------------------
revoke all on function public._project_urgency(integer, integer, date, date, date) from public, anon;
grant execute on function public._project_urgency(integer, integer, date, date, date) to authenticated;
do $$
declare f text;
begin
  foreach f in array array['public.stage_overview(date)',
    'public.create_project(text, text, date, uuid, uuid)',
    'public.create_resource(text, text)',
    'public.archive_item(text, uuid)'] loop
    execute format('revoke all on function %s from public, anon', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;

commit;

-- ===== 014_goals.sql =====
-- Migración 014 · Metas (Boss) en Stage · P.A.R.A. (requiere 001–013).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- 1. RPC create_goal: crea una Meta con el formulario S.M.A.R.T. (RF-014:
--    en Quick Add la Meta pasa por S.M.A.R.T.). La vida del jefe es la de
--    la columna (boss_max_hp, 100 por defecto).
-- 2. stage_overview: cuerpo de 013 más la sección Metas (vida del jefe,
--    fecha, proyectos y misiones vinculadas) y las misiones de cada proyecto.
-- 3. archive_item: también archiva metas.
--
-- shortcut: la vida del jefe es fija (100); el diseño no fija cómo escala
-- con el tamaño de la meta (docs/plan-cambios-esquema.md §7).

begin;

-- 1. Crear Meta --------------------------------------------------------------------
-- security invoker: el insert pasa por el RLS y los grants de columna de 003.
create or replace function public.create_goal(
  p_title text,
  p_specific text,
  p_measurable text,
  p_achievable text,
  p_relevant text,
  p_due_date date,
  p_timebound text default null,
  p_skill_id uuid default null
)
returns uuid
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_title text := trim(coalesce(p_title, ''));
  v_id uuid;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  if v_title = '' or length(v_title) > 200 then
    raise exception 'invalid_title' using errcode = '22023';
  end if;
  if trim(coalesce(p_specific, '')) = '' or trim(coalesce(p_measurable, '')) = ''
     or trim(coalesce(p_achievable, '')) = '' or trim(coalesce(p_relevant, '')) = '' then
    raise exception 'smart_incomplete' using errcode = '22023';
  end if;
  if p_due_date is null or p_due_date < current_date then
    raise exception 'invalid_due_date' using errcode = '22023';
  end if;
  if p_skill_id is not null
     and not exists (select 1 from public.skills where id = p_skill_id and user_id = v_uid) then
    raise exception 'skill_not_found' using errcode = 'P0002';
  end if;
  insert into public.goals (user_id, skill_id, title, smart_specific, smart_measurable,
                            smart_achievable, smart_relevant, smart_timebound,
                            start_date, due_date)
  values (v_uid, p_skill_id, v_title, trim(p_specific), trim(p_measurable),
          trim(p_achievable), trim(p_relevant), nullif(trim(coalesce(p_timebound, '')), ''),
          current_date, p_due_date)
  returning id into v_id;
  return v_id;
end $$;

-- 2. Datos de la pantalla Stage ---------------------------------------------------
-- Cuerpo de 013 con: 'goals' ampliado (vida del jefe, fecha, vínculos) y
-- 'tasks' dentro de cada proyecto (misiones sin subtareas, abiertas primero).
create or replace function public.stage_overview(p_day date)
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  with p as (
    select p.*,
      (select count(*) from public.tasks t where t.project_id = p.id and t.parent_task_id is null)::int as total,
      (select count(*) from public.tasks t where t.project_id = p.id and t.parent_task_id is null
         and t.status = 'completed')::int as done
    from public.projects p
  )
  select jsonb_build_object(
    'highlight', coalesce((
      select jsonb_agg(jsonb_build_object('id', h.id, 'title', h.title, 'bucket', h.bucket,
                                          'due_date', h.due_date) order by h.n)
      -- Mismo orden que missions_overview (010): empata por antigüedad.
      from (select v.*, row_number() over (order by v.bucket_order, v.due_date nulls last,
                                                    t.created_at) n
            from public.v_daily_highlight v join public.tasks t on t.id = v.id) h
      where h.n <= 5
    ), '[]'::jsonb),
    'highlight_total', (select count(*) from public.v_daily_highlight),
    'projects', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', p.id,
        'title', p.title,
        'skill_name', s.name,
        'goal_title', g.title,
        'end_date', p.end_date,
        'tasks_total', p.total,
        'tasks_done', p.done,
        'urgency', public._project_urgency(p.total, p.done,
                     coalesce(p.start_date, p.created_at::date), p.end_date, p_day),
        'tasks', coalesce((
          select jsonb_agg(jsonb_build_object('id', t.id, 'title', t.title,
                                              'done', t.status = 'completed')
                           order by t.status = 'completed', t.created_at)
          from public.tasks t
          where t.project_id = p.id and t.parent_task_id is null
            and t.status in ('pending', 'in_progress', 'delegated', 'completed')
        ), '[]'::jsonb)
      ) order by p.end_date nulls last, p.created_at)
      from p
      left join public.skills s on s.id = p.skill_id
      left join public.goals g on g.id = p.goal_id
      where p.status in ('not_started', 'in_progress') and p.archived_at is null
    ), '[]'::jsonb),
    'areas', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', s.id,
        'name', s.name,
        'level', s.level,
        'open_tasks', (select count(*) from public.tasks t where t.skill_id = s.id
                         and t.parent_task_id is null
                         and t.status in ('pending', 'in_progress', 'delegated')),
        'projects', (select count(*) from public.projects pr where pr.skill_id = s.id
                       and pr.status in ('not_started', 'in_progress') and pr.archived_at is null),
        'habits', (select count(*) from public.habits hb where hb.skill_id = s.id)
      ) order by s.created_at)
      from public.skills s
    ), '[]'::jsonb),
    'resources', coalesce((
      select jsonb_agg(jsonb_build_object('id', r.id, 'title', r.title, 'url', r.file_url)
                       order by r.created_at desc)
      from public.resources r
      where r.archived_at is null
    ), '[]'::jsonb),
    'archive', jsonb_build_object(
      'projects', (select count(*) from public.projects
                   where archived_at is not null or status in ('completed', 'expired')),
      'goals', (select count(*) from public.goals
                where archived_at is not null or status in ('completed', 'expired')),
      'resources', (select count(*) from public.resources where archived_at is not null)
    ),
    'skills', coalesce((
      select jsonb_agg(jsonb_build_object('id', id, 'name', name) order by created_at)
      from public.skills
    ), '[]'::jsonb),
    'goals', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', g.id,
        'title', g.title,
        'skill_name', s.name,
        'due_date', g.due_date,
        'boss_hp', g.boss_current_hp,
        'boss_max_hp', g.boss_max_hp,
        'projects', (select count(*) from public.projects pr where pr.goal_id = g.id
                       and pr.status in ('not_started', 'in_progress') and pr.archived_at is null),
        'open_tasks', (select count(*) from public.tasks t where t.goal_id = g.id
                         and t.parent_task_id is null
                         and t.status in ('pending', 'in_progress', 'delegated'))
      ) order by g.due_date nulls last, g.created_at)
      from public.goals g
      left join public.skills s on s.id = g.skill_id
      where g.status in ('not_started', 'in_progress') and g.archived_at is null
    ), '[]'::jsonb)
  )
$$;

-- 3. Archivo (cuerpo de 013 más las metas) ---------------------------------------
create or replace function public.archive_item(p_kind text, p_id uuid)
returns void
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
  if p_kind = 'project' then
    update public.projects set archived_at = now()
    where id = p_id and user_id = v_uid and archived_at is null;
  elsif p_kind = 'resource' then
    update public.resources set archived_at = now()
    where id = p_id and user_id = v_uid and archived_at is null;
  elsif p_kind = 'goal' then
    update public.goals set archived_at = now()
    where id = p_id and user_id = v_uid and archived_at is null;
  else
    raise exception 'invalid_kind' using errcode = '22023';
  end if;
  if not found then
    raise exception 'item_not_found' using errcode = 'P0002';
  end if;
end $$;

-- Permisos ---------------------------------------------------------------------
do $$
declare f text;
begin
  foreach f in array array[
    'public.create_goal(text, text, text, text, text, date, text, uuid)',
    'public.stage_overview(date)', 'public.archive_item(text, uuid)'] loop
    execute format('revoke all on function %s from public, anon', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;

commit;

-- ===== 015_onboarding.sql =====
-- Migración 015 · Onboarding de 5 pasos (requiere 001–014).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
-- Spec: specs/003-onboarding/.
--
-- 1. profiles.onboarded_at: fecha en que el jugador terminó o saltó el
--    Onboarding. Solo pasa de null a now(); después no cambia ni se borra.
-- 2. RPC onboarding_overview: si toca mostrarlo y los multiplicadores
--    vigentes de difficulty_levels (no se escriben a mano en la app).
-- 3. RPC complete_onboarding: guarda identidad, primera skill y dificultad
--    de una vez, al terminar o saltar. No da XP ni Monedas.

begin;

-- 1. Marca de Onboarding visto ------------------------------------------------
alter table public.profiles add column if not exists onboarded_at timestamptz;

-- profiles tiene grant update amplio (el Perfil edita la identidad directo):
-- el trigger es quien impide fijar otra fecha o borrar la marca.
create or replace function public.guard_onboarded_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if old.onboarded_at is not null then
    if new.onboarded_at is distinct from old.onboarded_at then
      raise exception 'onboarding_locked' using errcode = '42501';
    end if;
  elsif new.onboarded_at is not null then
    new.onboarded_at := now();
  end if;
  return new;
end $$;

drop trigger if exists trg_guard_onboarded_at on public.profiles;
create trigger trg_guard_onboarded_at before update of onboarded_at on public.profiles
  for each row execute function public.guard_onboarded_at();

-- 2. ¿Toca el Onboarding? -------------------------------------------------------
-- Un jugador con identidad o alguna skill (anterior a esta función) no lo ve.
create or replace function public.onboarding_overview()
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  select jsonb_build_object(
    'pending', p.onboarded_at is null
      and p.identity_statement is null
      and not exists (select 1 from public.skills s where s.user_id = p.id),
    'difficulties', (
      select coalesce(jsonb_agg(jsonb_build_object(
        'level', dl.level,
        'xp_multiplier', dl.xp_multiplier,
        'hp_penalty_multiplier', dl.hp_penalty_multiplier,
        'coin_multiplier', dl.coin_multiplier
      ) order by dl.level), '[]'::jsonb)
      from public.difficulty_levels dl
    )
  )
  from public.profiles p
  where p.id = auth.uid()
$$;

-- 3. Terminar o saltar ------------------------------------------------------------
-- security invoker: valen el RLS, los checks de longitud (002), el límite de
-- skills y el grant de columna de game_master_settings (003).
create or replace function public.complete_onboarding(
  p_identity text,
  p_skill text,
  p_difficulty public.difficulty_level
)
returns void
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_identity text := nullif(trim(p_identity), '');
  v_skill text := nullif(trim(p_skill), '');
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  -- for update: dos dispositivos a la vez no guardan dos veces.
  if (select onboarded_at from public.profiles where id = v_uid for update) is not null then
    raise exception 'onboarding_done' using errcode = '42501';
  end if;

  if v_identity is not null then
    update public.profiles set identity_statement = v_identity where id = v_uid;
  end if;
  if v_skill is not null then
    if exists (select 1 from public.skills
               where user_id = v_uid and lower(trim(name)) = lower(v_skill)) then
      raise exception 'skill_exists' using errcode = '23505';
    end if;
    insert into public.skills (user_id, name) values (v_uid, v_skill);
  end if;
  update public.game_master_settings
    set difficulty = coalesce(p_difficulty, 'normal') where user_id = v_uid;
  update public.profiles set onboarded_at = now() where id = v_uid;
end $$;

-- Permisos -----------------------------------------------------------------------
do $$
declare f text;
begin
  foreach f in array array['public.onboarding_overview()',
    'public.complete_onboarding(text, text, public.difficulty_level)'] loop
    execute format('revoke all on function %s from public, anon', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;

commit;

-- ===== 016_settings.sql =====
-- Migración 016 · Configuración (Game Master) (requiere 001–015).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- 1. Rangos de game_master_settings: el cliente ya puede escribir estas
--    columnas (grants de 003 y 007); los checks evitan valores sin sentido.
-- 2. RPC settings_overview: nivel y XP del personaje, reglas del jugador y
--    multiplicadores vigentes de difficulty_levels, en una sola carga.
--
-- El guardado es un update directo (RLS + grants de columna): no toca la
-- economía.

begin;

-- 1. Rangos ------------------------------------------------------------------------
-- shortcut: rangos provisionales, no vienen del documento de diseño; ajustar
-- si el equipo fija otros. not valid: no revisa filas antiguas.
alter table public.game_master_settings
  drop constraint if exists game_master_settings_daily_limit_range,
  add constraint game_master_settings_daily_limit_range
    check (notification_daily_limit is null or notification_daily_limit between 1 and 50) not valid,
  -- RF-067: la ventana de silencio va completa o no va.
  drop constraint if exists game_master_settings_silence_pair,
  add constraint game_master_settings_silence_pair
    check ((silence_window_start is null) = (silence_window_end is null)) not valid,
  drop constraint if exists game_master_settings_breaks_range,
  add constraint game_master_settings_breaks_range
    check (short_break_minutes between 1 and 30
       and long_break_minutes between 5 and 60
       and long_break_every_n_cycles between 2 and 8) not valid;

-- 2. Datos de Configuración ---------------------------------------------------------
create or replace function public.settings_overview()
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  select jsonb_build_object(
    'level', s.level,
    'current_xp', s.current_xp,
    'xp_to_next_level', s.xp_to_next_level,
    'difficulty', g.difficulty,
    'notification_daily_limit', g.notification_daily_limit,
    'silence_window_start', to_char(g.silence_window_start, 'HH24:MI'),
    'silence_window_end', to_char(g.silence_window_end, 'HH24:MI'),
    'critical_bypass_silence', g.critical_bypass_silence,
    'short_break_minutes', g.short_break_minutes,
    'long_break_minutes', g.long_break_minutes,
    'long_break_every_n_cycles', g.long_break_every_n_cycles,
    'difficulties', (
      select coalesce(jsonb_agg(jsonb_build_object(
        'level', dl.level,
        'xp_multiplier', dl.xp_multiplier,
        'hp_penalty_multiplier', dl.hp_penalty_multiplier,
        'coin_multiplier', dl.coin_multiplier
      ) order by dl.level), '[]'::jsonb)
      from public.difficulty_levels dl
    )
  )
  from public.profiles p
  left join public.character_stats s on s.user_id = p.id
  left join public.game_master_settings g on g.user_id = p.id
  where p.id = auth.uid()
$$;

revoke all on function public.settings_overview() from public, anon;
grant execute on function public.settings_overview() to authenticated;

commit;

-- ===== 017_dungeon_breaks.sql =====
-- Migración 017 · La Mazmorra usa los descansos de Configuración (requiere 001–016).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- dungeon_overview: cuerpo de 012 más `breaks` (RF-067: descanso corto, largo
-- y cada cuántos ciclos toca el largo), leídos de game_master_settings.

begin;

create or replace function public.dungeon_overview()
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  with s as (
    select * from public.focus_sessions
    where user_id = auth.uid() and status in ('active', 'paused')
    order by started_at desc limit 1
  ),
  runs as (
    select r.* from public.dungeon_runs r join s on s.id = r.session_id
  )
  select jsonb_build_object(
    'session', (
      select jsonb_build_object(
        'id', s.id,
        'total_minutes', s.total_minutes,
        'cycle_minutes', s.cycle_minutes,
        'started_at', s.started_at,
        'cycles_done', (select count(*) from runs),
        'xp_earned', (select coalesce(sum(q.xp_awarded), 0) from public.quest_log_entries q
                      where q.source_type = 'dungeon' and q.source_id in (select id from runs)),
        'coins_earned', (select coalesce(sum(q.coin_awarded), 0) from public.quest_log_entries q
                         where q.source_type = 'dungeon' and q.source_id in (select id from runs)),
        'tasks', coalesce((
          select jsonb_agg(jsonb_build_object(
            'id', t.id,
            'title', t.title,
            'done', t.status = 'completed',
            'cycles', (select count(*) from runs where runs.task_id = t.id)
          ) order by t.created_at)
          from public.focus_session_tasks f join public.tasks t on t.id = f.task_id
          where f.session_id = s.id
        ), '[]'::jsonb)
      )
      from s
    ),
    'candidates', coalesce((
      select jsonb_agg(jsonb_build_object('id', c.id, 'title', c.title, 'bucket', c.bucket)
                       order by c.bucket_order, c.due_date nulls last)
      from (select * from public.v_daily_highlight
            order by bucket_order, due_date nulls last limit 30) c
    ), '[]'::jsonb),
    'max_tasks', public.rule('dungeon_max_tasks')::integer,
    'cycle_xp', public.rule('dungeon_cycle_xp')::integer,
    -- RF-067: descansos que el jugador eligió en Configuración (016).
    'breaks', (
      select jsonb_build_object(
        'short_minutes', g.short_break_minutes,
        'long_minutes', g.long_break_minutes,
        'long_every_n_cycles', g.long_break_every_n_cycles
      )
      from public.game_master_settings g where g.user_id = auth.uid()
    )
  )
$$;

commit;

-- ===== 018_marketplace.sql =====
-- Migración 018 · Marketplace: lectura de la Tienda (requiere 001–017).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- market_overview(): bolsa, vida, Hotel y Mercado con su disponibilidad,
-- Mercado negro con su uso del mes, Elixires y Pases guardados, rachas que
-- aún se pueden salvar (48 h) y el Refugio con el precio del siguiente nivel.
-- Comprar sigue siendo purchase, buy_black_market, use_recovery_pass,
-- upgrade_refuge y activate_elixir (006).
--
-- shortcut: el Cofre no se muestra porque aún no hay RPC para abrirlo ni
-- catálogo de premios (plan-cambios-esquema §7); mostrarlo cuando exista.

begin;

-- security invoker: todo se lee con el RLS del usuario.
create or replace function public.market_overview()
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  select jsonb_build_object(
    'coins', coalesce(cs.coins, 0),
    'treasury', coalesce(cs.treasury, 0),
    'hp_current', coalesce(cs.hp_current, 100),
    'hp_max', coalesce(cs.hp_max, 100),
    'items', coalesce((
      select jsonb_agg(jsonb_build_object(
        'code', m.code,
        'category', m.category,
        'name', m.name,
        'description', m.description,
        'cost', m.coin_cost,
        'available', not (
          (m.daily_limit is not null and (
            select count(*) from public.purchases p
            where p.market_item_id = m.id
              and p.purchased_at >= current_date and p.purchased_at < current_date + 1
          ) >= m.daily_limit)
          or (m.code = 'elixir' and (
            select count(*) from public.user_consumables c
            where c.kind = 'elixir' and c.status in ('stored', 'active')
          ) >= coalesce(m.active_limit, 1)))
      ) order by m.category, m.coin_cost)
      from public.market_items m
      where m.is_active and m.code is not null and m.code <> 'cofre'
    ), '[]'::jsonb),
    'black_market', coalesce((
      select jsonb_agg(jsonb_build_object(
        'code', b.code,
        'name', b.name,
        'cost', b.coin_cost,
        'available', b.monthly_limit is null or (
          select count(*) from public.black_market_redemptions r
          where r.item_id = b.id and r.redeemed_at >= date_trunc('month', now())
        ) < b.monthly_limit
      ) order by b.coin_cost)
      from public.black_market_items b where b.code is not null
    ), '[]'::jsonb),
    'elixirs_stored', (select count(*) from public.user_consumables
                       where kind = 'elixir' and status = 'stored'),
    'elixir_active', exists (select 1 from public.user_consumables
                             where kind = 'elixir' and status = 'active'),
    'passes', (select count(*) from public.recovery_passes where used_at is null),
    'broken_streaks', coalesce((
      select jsonb_agg(jsonb_build_object(
        'habit_id', h.id,
        'name', h.name,
        'streak', h.broken_streak,
        'deadline', (h.broken_on + 1)::timestamptz
                    + make_interval(hours => public.rule('streak_recovery_hours')::integer)
      ) order by h.broken_on)
      from public.habits h
      where h.broken_on is not null and h.broken_streak > 0
        and now() <= (h.broken_on + 1)::timestamptz
                     + make_interval(hours => public.rule('streak_recovery_hours')::integer)
    ), '[]'::jsonb),
    'refuge', (
      select jsonb_agg(jsonb_build_object(
        'building', b,
        'level', coalesce(u.level, 0),
        'max_level', public.rule('refuge_max_level'),
        'price', case when coalesce(u.level, 0) < public.rule('refuge_max_level')
                      then round(public.rule('refuge_base_price')
                                 * power(public.rule('refuge_growth'), coalesce(u.level, 0))) end
      ) order by b)
      from unnest(enum_range(null::public.refuge_building)) b
      left join public.refuge_upgrades u on u.building = b
    )
  )
  from (select 1) one
  left join public.character_stats cs on true
$$;

revoke all on function public.market_overview() from public, anon;
grant execute on function public.market_overview() to authenticated;

commit;

-- ===== 018_social_login.sql =====
-- 018 · Inicio de sesión con Google y Apple
-- El registro con correo guarda el nombre en `username`; Google y Apple lo
-- traen en `full_name` o `name`. Sin esto, el perfil de esas cuentas nace
-- sin nombre visible. Igual que en 002, el nombre se recorta a 40 caracteres
-- para que el alta nunca falle por su longitud.

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    nullif(left(trim(coalesce(
      nullif(trim(new.raw_user_meta_data ->> 'username'), ''),
      nullif(trim(new.raw_user_meta_data ->> 'full_name'), ''),
      new.raw_user_meta_data ->> 'name'
    )), 40), '')
  )
  on conflict (id) do nothing;
  insert into public.character_stats (user_id) values (new.id)
  on conflict (user_id) do nothing;
  insert into public.game_master_settings (user_id) values (new.id)
  on conflict (user_id) do nothing;
  return new;
end $$;

-- ===== 019_tavern.sql =====
-- Migración 019 · Taverna: NPCs y sus misiones (requiere 001–018).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- 1. tavern_overview(): NPCs con su skill, su misión abierta y cuándo vuelve
--    a ser gratis pedirle otra; límite de NPCs (3 + Estandarte) y skills.
-- 2. create_npc: nombre, skill obligatoria (CLAUDE.md §6), frecuencia y
--    noble misión. El límite lo aplica el trigger de 006.
-- 3. accept_npc_mission: cobra el atajo con request_npc_mission (006) y crea
--    la misión como una tarea real (source = 'npc'). Se completa con
--    complete_task, que ya paga como 'npc'.
--
-- RPGenie sugiere el título con la Edge Function npc-mission (Gemini); el
-- usuario lo edita o acepta y la misión entra siempre por aquí.

begin;

-- 1. Datos de la Taverna ---------------------------------------------------------
create or replace function public.tavern_overview()
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  select jsonb_build_object(
    'npcs', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', n.id,
        'name', n.name,
        'noble_mission', n.noble_mission,
        'frequency', n.frequency,
        'skill_name', s.name,
        'free_at', case when n.last_mission_at is not null
                        then n.last_mission_at
                             + make_interval(hours => public.rule('npc_free_hours')::integer) end,
        'open_mission', (
          select jsonb_build_object('id', t.id, 'title', t.title, 'xp_reward', t.xp_reward)
          from public.tasks t
          where t.npc_id = n.id and t.status in ('pending', 'in_progress')
          order by t.created_at desc limit 1),
        'completed', (select count(*) from public.tasks t
                      where t.npc_id = n.id and t.status = 'completed')
      ) order by n.created_at)
      from public.npcs n join public.skills s on s.id = n.skill_id
    ), '[]'::jsonb),
    'npc_limit', public.rule('npc_base_limit') + coalesce((
      select level from public.refuge_upgrades where building = 'estandarte'), 0),
    'instant_cost', public.rule('npc_instant_cost'),
    'coins', coalesce((select coins from public.character_stats), 0),
    'skills', coalesce((
      select jsonb_agg(jsonb_build_object('id', id, 'name', name) order by created_at)
      from public.skills
    ), '[]'::jsonb)
  )
$$;

-- 2. Crear NPC ------------------------------------------------------------------
-- security invoker: el insert pasa por el RLS y los grants de columna de 003.
create or replace function public.create_npc(
  p_name text,
  p_skill_id uuid,
  p_frequency public.npc_frequency default 'weekly',
  p_noble_mission text default null
)
returns uuid
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_name text := trim(coalesce(p_name, ''));
  v_id uuid;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  if v_name = '' or length(v_name) > 60 then
    raise exception 'invalid_name' using errcode = '22023';
  end if;
  if p_skill_id is null
     or not exists (select 1 from public.skills where id = p_skill_id and user_id = v_uid) then
    raise exception 'skill_not_found' using errcode = 'P0002';
  end if;
  insert into public.npcs (user_id, name, skill_id, frequency, noble_mission)
  values (v_uid, v_name, p_skill_id, coalesce(p_frequency, 'weekly'),
          nullif(left(trim(coalesce(p_noble_mission, '')), 300), ''))
  returning id into v_id;
  return v_id;
end $$;

-- 3. Aceptar misión ----------------------------------------------------------------
-- Una misión abierta por NPC: así el atajo de pago no se acumula.
create or replace function public.accept_npc_mission(p_npc_id uuid, p_title text)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_title text := trim(coalesce(p_title, ''));
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
  select skill_id into v_skill from public.npcs where id = p_npc_id and user_id = v_uid;
  if not found then
    raise exception 'npc_not_found' using errcode = 'P0002';
  end if;
  if exists (select 1 from public.tasks where npc_id = p_npc_id
             and status in ('pending', 'in_progress')) then
    raise exception 'npc_mission_open' using errcode = 'P0001';
  end if;
  v_paid := public.request_npc_mission(p_npc_id);
  insert into public.tasks (user_id, npc_id, skill_id, title, source)
  values (v_uid, p_npc_id, v_skill, v_title, 'npc')
  returning id into v_task;
  return v_paid || jsonb_build_object('task_id', v_task);
end $$;

-- Permisos ---------------------------------------------------------------------
do $$
declare f text;
begin
  foreach f in array array['public.tavern_overview()',
    'public.create_npc(text, uuid, public.npc_frequency, text)',
    'public.accept_npc_mission(uuid, text)'] loop
    execute format('revoke all on function %s from public, anon', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;

commit;

-- ===== 020_journal.sql =====
-- Migración 020 · Diario: la Bitácora (requiere 001–019).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- journal_overview(p_day): resumen de los últimos 7 días comparado con los 7
-- anteriores y las últimas 150 entradas de quest_log_entries (60 días) con el
-- nombre de lo que las produjo. Sin Diario del Héroe (CLAUDE.md §13).
-- source_id es polimórfico: el nombre se busca según source_type.

begin;

create or replace function public.journal_overview(p_day date)
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  with q as (
    select q.*, (q.occurred_at >= (p_day - 6)::timestamptz) as this_week
    from public.quest_log_entries q
    where q.occurred_at >= (p_day - 13)::timestamptz
      and q.occurred_at < (p_day + 1)::timestamptz
  ),
  week as (
    select this_week,
           sum(xp_awarded) as xp,
           count(*) filter (where result = 'completed'
                            and source_type::text in ('task', 'npc', 'project')) as missions,
           count(*) filter (where source_type::text = 'dungeon') as cycles
    from q group by this_week
  )
  select jsonb_build_object(
    'summary', jsonb_build_object(
      'xp', coalesce((select xp from week where this_week), 0),
      'xp_prev', coalesce((select xp from week where not this_week), 0),
      'missions', coalesce((select missions from week where this_week), 0),
      'missions_prev', coalesce((select missions from week where not this_week), 0),
      'cycles', coalesce((select cycles from week where this_week), 0),
      'cycles_prev', coalesce((select cycles from week where not this_week), 0),
      'best_streak', coalesce((select max(current_streak) from public.habits where type = 'good'), 0)
    ),
    'entries', coalesce((
      select jsonb_agg(e order by e->>'occurred_at' desc)
      from (
        select jsonb_build_object(
          'id', l.id,
          'source', l.source_type,
          'result', l.result,
          'xp', l.xp_awarded,
          'coins', l.coin_awarded,
          'hp', l.hp_change,
          'occurred_at', l.occurred_at,
          'title', case l.source_type::text
            when 'task' then (select title from public.tasks where id = l.source_id)
            when 'npc' then (select title from public.tasks where id = l.source_id)
            when 'project' then (select title from public.projects where id = l.source_id)
            when 'goal' then (select title from public.goals where id = l.source_id)
            when 'habit' then (select name from public.habits where id = l.source_id)
            when 'dungeon' then (select t.title from public.dungeon_runs r
                                 join public.tasks t on t.id = r.task_id where r.id = l.source_id)
            when 'achievement' then (select name from public.achievements where id = l.source_id)
            else null end
        ) as e
        from public.quest_log_entries l
        where l.occurred_at >= (p_day - 59)::timestamptz
        order by l.occurred_at desc
        limit 150
      ) x
    ), '[]'::jsonb)
  )
$$;

revoke all on function public.journal_overview(date) from public, anon;
grant execute on function public.journal_overview(date) to authenticated;

commit;

-- ===== 021_boss_fight.sql =====
-- Migración 021 · Objetivos: Boss Fight (requiere 001–020).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- goals_overview(): cada Meta sin archivar como un jefe, con su vida, su
-- ficha S.M.A.R.T., los ataques disponibles (tareas y proyectos abiertos
-- vinculados, con su daño) y los últimos golpes. Atacar es complete_task o
-- complete_project (005/008); el daño lo pone _damage_boss. Archivar es
-- archive_item('goal', id) (014). Estado único: objective_status (RF-084).

begin;

create or replace function public.goals_overview()
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  select jsonb_build_object(
    'goals', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', g.id,
        'title', g.title,
        'status', g.status,
        'due_date', g.due_date,
        'skill_name', s.name,
        'boss_max_hp', g.boss_max_hp,
        'boss_current_hp', g.boss_current_hp,
        'smart', jsonb_build_object(
          'specific', g.smart_specific, 'measurable', g.smart_measurable,
          'achievable', g.smart_achievable, 'relevant', g.smart_relevant,
          'timebound', g.smart_timebound),
        'attacks', coalesce((
          select jsonb_agg(a order by a->>'kind' desc, a->>'title')
          from (
            select jsonb_build_object('kind', 'task', 'id', t.id, 'title', t.title,
                                      'damage', t.xp_reward) a
            from public.tasks t
            where t.goal_id = g.id and t.parent_task_id is null
              and t.status in ('pending', 'in_progress', 'delegated')
            union all
            select jsonb_build_object('kind', 'project', 'id', p.id, 'title', p.title,
                                      'damage', public.rule('boss_damage_project'))
            from public.projects p
            where p.goal_id = g.id and p.archived_at is null
              and p.status in ('not_started', 'in_progress')
          ) x
        ), '[]'::jsonb),
        'hits', coalesce((
          select jsonb_agg(jsonb_build_object('title', y.title, 'damage', y.damage, 'at', y.at)
                           order by y.at desc)
          from (
            select t.title, t.xp_reward::numeric as damage, t.completed_at as at
            from public.tasks t
            where t.goal_id = g.id and t.status = 'completed'
            union all
            select p.title, public.rule('boss_damage_project'), q.occurred_at
            from public.projects p
            join public.quest_log_entries q
              on q.source_id = p.id and q.source_type = 'project' and q.result = 'completed'
            where p.goal_id = g.id
            order by at desc
            limit 5
          ) y
        ), '[]'::jsonb)
      ) order by case when g.status in ('not_started', 'in_progress') then 0 else 1 end,
                 g.due_date nulls last, g.created_at)
      from public.goals g left join public.skills s on s.id = g.skill_id
      where g.archived_at is null
    ), '[]'::jsonb),
    'victory_xp', public.rule('boss_victory_xp'),
    'victory_coins', public.rule('boss_victory_coins')
  )
$$;

revoke all on function public.goals_overview() from public, anon;
grant execute on function public.goals_overview() to authenticated;

commit;

-- ===== 022_rpgenie.sql =====
-- Migración 022 · RPGenie v1: Misión actual por reglas (requiere 001–021).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- current_mission(p_skip): la tarea abierta (sin subtareas) que toca ahora,
-- según RF-097: crítica (vence en < 24 h o ya venció) → prioridad alta >
-- media > baja → fecha límite más próxima → la más antigua. p_skip son las
-- que el usuario apartó con "Ahora no" (sin castigo; la app las recuerda
-- mientras dure la sesión). Completarla es complete_task (005).
-- La propuesta del cierre del diseño (§13: daño a jefes, "estoy cansado")
-- sigue abierta (CLAUDE.md §11): no se aplica todavía.

begin;

create or replace function public.current_mission(p_skip uuid[] default '{}')
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  with cand as (
    select t.*, t.due_date is not null and t.due_date < now() + interval '24 hours' as critical
    from public.tasks t
    where t.parent_task_id is null
      and t.status in ('pending', 'in_progress')
  ),
  pick as (
    select o.* from cand o
    where not (o.id = any (coalesce(p_skip, '{}')))
    order by o.critical desc,
             case o.priority when 'high' then 0 when 'medium' then 1 else 2 end,
             o.due_date nulls last, o.created_at
    limit 1
  )
  select jsonb_build_object(
    'mission', (
      select jsonb_build_object(
        'id', p.id,
        'title', p.title,
        'priority', p.priority,
        'due_date', p.due_date,
        'xp_reward', p.xp_reward,
        'coin_reward', p.coin_reward,
        'skill_name', s.name,
        'goal_title', g.title,
        'project_title', pr.title,
        'reason', case when p.critical then 'critical'
                       when p.priority = 'high' then 'high'
                       when p.due_date is not null then 'due'
                       else 'next' end)
      from pick p
      left join public.skills s on s.id = p.skill_id
      left join public.goals g on g.id = p.goal_id
      left join public.projects pr on pr.id = p.project_id),
    'open_count', (select count(*) from cand),
    'skipped_count', (select count(*) from cand where id = any (coalesce(p_skip, '{}')))
  )
$$;

revoke all on function public.current_mission(uuid[]) from public, anon;
grant execute on function public.current_mission(uuid[]) to authenticated;

commit;

-- ===== 023_brain_dump.sql =====
-- Migración 023 · Brain Dump y Diagnosis G.T.D. (requiere 001–022).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- 1. brain_dump_overview(): bandeja (pending), Algún día y Referencia.
-- 2. capture_thought: captura con la mínima fricción (Modelo de Fogg).
-- 3. file_thought: el paso 1 del G.T.D. (no accionable → reference/someday)
--    o devolverlo a la bandeja.
-- 4. convert_thought: resultado del G.T.D. (CLAUDE.md §5). 'task' crea una
--    tarea con source = 'gtd_diagnosis'; 'delegated' la crea delegada con
--    «¿a quién?» (RF-011); 'done' la crea y la completa al instante (regla de
--    los 2 min: complete_task paga el mínimo, sin Monedas); 'project' usa
--    create_project. Las Metas pasan por S.M.A.R.T. en Stage (RF-014).
-- 5. delete_thought.

begin;

-- 1. Lectura ---------------------------------------------------------------------
create or replace function public.brain_dump_overview()
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  select jsonb_build_object(
    'inbox', coalesce((
      select jsonb_agg(jsonb_build_object('id', id, 'content', content, 'created_at', created_at)
                       order by created_at desc)
      from public.brain_dump_entries where status = 'pending'
    ), '[]'::jsonb),
    'someday', coalesce((
      select jsonb_agg(jsonb_build_object('id', id, 'content', content, 'created_at', created_at)
                       order by created_at desc)
      from public.brain_dump_entries where status = 'someday'
    ), '[]'::jsonb),
    'reference', coalesce((
      select jsonb_agg(jsonb_build_object('id', id, 'content', content, 'created_at', created_at)
                       order by created_at desc)
      from public.brain_dump_entries where status = 'reference'
    ), '[]'::jsonb),
    'converted_today', (
      select count(*) from public.brain_dump_entries
      where status = 'converted' and created_at >= current_date
    )
  )
$$;

-- 2. Capturar ---------------------------------------------------------------------
create or replace function public.capture_thought(p_content text)
returns uuid
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_content text := trim(coalesce(p_content, ''));
  v_id uuid;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  if v_content = '' or length(v_content) > 500 then
    raise exception 'invalid_content' using errcode = '22023';
  end if;
  insert into public.brain_dump_entries (user_id, content)
  values (v_uid, v_content) returning id into v_id;
  return v_id;
end $$;

-- 3. Archivar en Algún día / Referencia, o volver a la bandeja ----------------------
create or replace function public.file_thought(p_id uuid, p_status public.brain_dump_status)
returns void
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  if p_status = 'converted' then
    raise exception 'invalid_status' using errcode = '22023';
  end if;
  update public.brain_dump_entries set status = p_status
  where id = p_id and user_id = auth.uid() and status <> 'converted';
  if not found then
    raise exception 'thought_not_found' using errcode = 'P0002';
  end if;
end $$;

-- 4. Convertir (resultado del G.T.D.) -------------------------------------------------
create or replace function public.convert_thought(
  p_id uuid,
  p_kind text,
  p_title text,
  p_priority public.urgency_level default 'low',
  p_due_date timestamptz default null,
  p_delegated_to text default null
)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_title text := trim(coalesce(p_title, ''));
  v_id uuid;
  v_type public.entity_type := 'task';
  v_reward jsonb;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  perform 1 from public.brain_dump_entries
  where id = p_id and user_id = v_uid and status <> 'converted' for update;
  if not found then
    raise exception 'thought_not_found' using errcode = 'P0002';
  end if;
  if v_title = '' or length(v_title) > 200 then
    raise exception 'invalid_title' using errcode = '22023';
  end if;

  if p_kind in ('task', 'done') then
    insert into public.tasks (user_id, title, priority, due_date, source)
    values (v_uid, v_title, coalesce(p_priority, 'low'), p_due_date, 'gtd_diagnosis')
    returning id into v_id;
    if p_kind = 'done' then
      v_reward := public.complete_task(v_id);
    end if;
  elsif p_kind = 'delegated' then
    insert into public.tasks (user_id, title, priority, due_date, source, status, delegated_to)
    values (v_uid, v_title, coalesce(p_priority, 'low'), p_due_date, 'gtd_diagnosis', 'delegated',
            nullif(left(trim(coalesce(p_delegated_to, '')), 100), ''))
    returning id into v_id;
  elsif p_kind = 'project' then
    v_id := public.create_project(v_title, null, p_due_date::date);
    v_type := 'project';
  else
    raise exception 'invalid_kind' using errcode = '22023';
  end if;

  update public.brain_dump_entries
  set status = 'converted', converted_to_type = v_type, converted_to_id = v_id
  where id = p_id;
  return jsonb_build_object('id', v_id, 'type', v_type, 'reward', v_reward);
end $$;

-- 5. Borrar ---------------------------------------------------------------------------
create or replace function public.delete_thought(p_id uuid)
returns void
language plpgsql
security invoker
set search_path = ''
as $$
begin
  delete from public.brain_dump_entries where id = p_id and user_id = auth.uid();
  if not found then
    raise exception 'thought_not_found' using errcode = 'P0002';
  end if;
end $$;

-- Permisos ---------------------------------------------------------------------
do $$
declare f text;
begin
  foreach f in array array['public.brain_dump_overview()', 'public.capture_thought(text)',
    'public.file_thought(uuid, public.brain_dump_status)',
    'public.convert_thought(uuid, text, text, public.urgency_level, timestamptz, text)',
    'public.delete_thought(uuid)'] loop
    execute format('revoke all on function %s from public, anon', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;

commit;

-- ===== 024_vision_board.sql =====
-- Migración 024 · Vision Board (requiere 001–023).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- 1. vision_overview(): el texto de la visión (1 por usuario), la identidad
--    del perfil y las Metas y Proyectos abiertos con su vínculo a la visión.
-- 2. save_vision: guarda el texto (upsert).
-- 3. set_vision_link: marca o desmarca una Meta o un Proyecto como parte de
--    la visión (goals/projects.linked_to_vision, 004).

begin;

create or replace function public.vision_overview()
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  select jsonb_build_object(
    'content', (select content from public.vision_boards),
    'updated_at', (select updated_at from public.vision_boards),
    'identity', (select identity_statement from public.profiles where id = auth.uid()),
    'items', coalesce((
      select jsonb_agg(x order by (x->>'linked')::boolean desc, x->>'kind', x->>'title')
      from (
        select jsonb_build_object('kind', 'goal', 'id', id, 'title', title,
                                  'linked', linked_to_vision) x
        from public.goals
        where archived_at is null and status in ('not_started', 'in_progress')
        union all
        select jsonb_build_object('kind', 'project', 'id', id, 'title', title,
                                  'linked', linked_to_vision)
        from public.projects
        where archived_at is null and status in ('not_started', 'in_progress')
      ) i
    ), '[]'::jsonb)
  )
$$;

create or replace function public.save_vision(p_content text)
returns void
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_content text := nullif(trim(coalesce(p_content, '')), '');
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  if length(v_content) > 2000 then
    raise exception 'invalid_content' using errcode = '22023';
  end if;
  insert into public.vision_boards (user_id, content, updated_at)
  values (v_uid, v_content, now())
  on conflict (user_id) do update set content = excluded.content, updated_at = now();
end $$;

create or replace function public.set_vision_link(p_kind text, p_id uuid, p_linked boolean)
returns void
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  if p_kind = 'goal' then
    update public.goals set linked_to_vision = coalesce(p_linked, false)
    where id = p_id and user_id = auth.uid();
  elsif p_kind = 'project' then
    update public.projects set linked_to_vision = coalesce(p_linked, false)
    where id = p_id and user_id = auth.uid();
  else
    raise exception 'invalid_kind' using errcode = '22023';
  end if;
  if not found then
    raise exception 'item_not_found' using errcode = 'P0002';
  end if;
end $$;

do $$
declare f text;
begin
  foreach f in array array['public.vision_overview()', 'public.save_vision(text)',
    'public.set_vision_link(text, uuid, boolean)'] loop
    execute format('revoke all on function %s from public, anon', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;

commit;

-- ===== 025_stats.sql =====
-- Migración 025 · Estadísticas (requiere 001–024).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- stats_overview(p_day): últimos 7 días frente a los 7 anteriores (XP,
-- misiones, minutos de Mazmorra, mejor racha), XP por día, XP por Área
-- (skill) y los hábitos buenos más constantes de los últimos 30 días.
-- Las 3 observaciones de RPGenie (CLAUDE.md §13) se arman en la app con
-- estos números. Pantalla de lectura: no guarda datos propios.

begin;

create or replace function public.stats_overview(p_day date)
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  with q as (
    select q.*, q.occurred_at >= (p_day - 6)::timestamptz as this_week,
           (q.occurred_at at time zone 'UTC')::date as day
    from public.quest_log_entries q
    where q.occurred_at >= (p_day - 13)::timestamptz
      and q.occurred_at < (p_day + 1)::timestamptz
  ),
  runs as (
    select r.ended_at >= (p_day - 6)::timestamptz as this_week, s.cycle_minutes
    from public.dungeon_runs r join public.focus_sessions s on s.id = r.session_id
    where r.completed and r.ended_at >= (p_day - 13)::timestamptz
      and r.ended_at < (p_day + 1)::timestamptz
  )
  select jsonb_build_object(
    'xp', coalesce((select sum(xp_awarded) from q where this_week), 0),
    'xp_prev', coalesce((select sum(xp_awarded) from q where not this_week), 0),
    'missions', (select count(*) from q where this_week and result = 'completed'
                 and source_type::text in ('task', 'npc', 'project')),
    'missions_prev', (select count(*) from q where not this_week and result = 'completed'
                      and source_type::text in ('task', 'npc', 'project')),
    'focus_minutes', coalesce((select sum(cycle_minutes) from runs where this_week), 0),
    'focus_minutes_prev', coalesce((select sum(cycle_minutes) from runs where not this_week), 0),
    'best_streak', coalesce((select max(current_streak) from public.habits where type = 'good'), 0),
    'record_streak', coalesce((select max(best_streak) from public.habits where type = 'good'), 0),
    'xp_by_day', (
      select jsonb_agg(jsonb_build_object('day', d,
               'xp', coalesce((select sum(xp_awarded) from q where q.day = d), 0)) order by d)
      from (select g::date as d from generate_series(p_day - 6, p_day, interval '1 day') g) days
    ),
    'xp_by_skill', coalesce((
      select jsonb_agg(jsonb_build_object('name', s.name, 'xp', t.xp) order by t.xp desc)
      from (select skill_id, sum(xp_awarded) xp from q
            where this_week and skill_id is not null group by skill_id) t
      join public.skills s on s.id = t.skill_id
      where t.xp > 0
    ), '[]'::jsonb),
    'top_habits', coalesce((
      select jsonb_agg(jsonb_build_object('name', name, 'days', days, 'streak', current_streak)
                       order by days desc, name)
      from (
        select h.name, h.current_streak, count(r.id) days
        from public.habits h
        join public.habit_records r on r.habit_id = h.id
          and r.completed_on > p_day - 30 and r.completed_on <= p_day
        where h.type = 'good'
        group by h.id
        order by days desc
        limit 3
      ) t
    ), '[]'::jsonb)
  )
$$;

revoke all on function public.stats_overview(date) from public, anon;
grant execute on function public.stats_overview(date) to authenticated;

commit;

-- ===== 026_inventory.sql =====
-- Migración 026 · Inventario y logros (requiere 001–025).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- inventory_overview(): pestaña Objetos (Elixires, Cofres, Pases de
-- Recuperación) y pestaña Logros (catálogo visible con lo desbloqueado) y
-- títulos de prestigio ganados (CLAUDE.md §13: se ganan, no se compran).
--
-- shortcut: el catálogo de logros y títulos sigue abierto
-- (plan-cambios-esquema §7); con el catálogo vacío la pestaña Logros solo
-- muestra los títulos. Nada se desbloquea desde aquí.

begin;

create or replace function public.inventory_overview()
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  select jsonb_build_object(
    'elixirs', (select count(*) from public.user_consumables
                where kind = 'elixir' and status = 'stored'),
    'elixir_active', exists (select 1 from public.user_consumables
                             where kind = 'elixir' and status = 'active'),
    'chests', (select count(*) from public.user_consumables
               where kind = 'cofre' and status = 'stored'),
    'passes', (select count(*) from public.recovery_passes where used_at is null),
    'achievements', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', a.id, 'name', a.name, 'description', a.description,
        'reward_coins', a.reward_coins, 'unlocked_at', ua.unlocked_at)
        order by ua.unlocked_at desc nulls last, a.name)
      from public.achievements a
      left join public.user_achievements ua on ua.achievement_id = a.id
      where not a.is_hidden or ua.unlocked_at is not null
    ), '[]'::jsonb),
    'titles', coalesce((
      select jsonb_agg(jsonb_build_object('id', t.id, 'name', t.name,
                                          'description', t.description, 'earned_at', ut.earned_at)
                       order by ut.earned_at desc)
      from public.user_titles ut join public.titles t on t.id = ut.title_id
    ), '[]'::jsonb)
  )
$$;

revoke all on function public.inventory_overview() from public, anon;
grant execute on function public.inventory_overview() to authenticated;

commit;

-- ===== 027_daily_chest.sql =====
-- Migración 027 · Cofre del día en el Inicio (requiere 001–026).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- daily_chest_status(): progreso del cofre de hoy con la misma regla de
-- claim_daily_chest (008): misiones (tarea o NPC) que dieron Monedas hoy,
-- cuántas hacen falta, cuántas Monedas da y si ya se reclamó. Cobrar sigue
-- siendo claim_daily_chest.
--
-- shortcut: "hoy" es el día UTC del servidor, igual que claim_daily_chest.

begin;

create or replace function public.daily_chest_status()
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  select jsonb_build_object(
    'progress', (
      select count(*) from public.quest_log_entries
      where source_type::text in ('task', 'npc') and result = 'completed' and coin_awarded > 0
        and occurred_at >= current_date and occurred_at < current_date + 1),
    'required', public.rule('daily_chest_min_missions'),
    'coins', public.rule('daily_chest_coins'),
    'claimed', exists (
      select 1 from public.quest_log_entries
      where source_type::text = 'daily_chest'
        and occurred_at >= current_date and occurred_at < current_date + 1)
  )
$$;

revoke all on function public.daily_chest_status() from public, anon;
grant execute on function public.daily_chest_status() to authenticated;

commit;

-- ===== 028_edit_delete.sql =====
-- Migración 028 · Editar y borrar misiones, hábitos y NPCs (requiere 001–027).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- 1. rename_task / delete_task: solo misiones abiertas. Renombrar no
--    recalcula la recompensa (RF-112: set_task_reward es solo al insertar).
--    Borrar quita también sus subtareas y su asignación a sesiones de
--    Mazmorra; si ya tiene ciclos jugados, no se borra (task_in_use).
--    Lo completado no se borra: su historia vive en la Bitácora.
-- 2. rename_habit / delete_habit: borrar quita también sus registros.
-- 3. rename_npc / delete_npc: las misiones del NPC se conservan como
--    misiones sueltas (npc_id = null; la FK es RESTRICT, CLAUDE.md §8).
--
-- security definer: las tablas de registros son de solo lectura para el
-- cliente (003); cada función comprueba que la fila es del usuario.

begin;

-- 1. Misiones -----------------------------------------------------------------------
create or replace function public.rename_task(p_task_id uuid, p_title text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare v_title text := trim(coalesce(p_title, ''));
begin
  if auth.uid() is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  if v_title = '' or length(v_title) > 200 then
    raise exception 'invalid_title' using errcode = '22023';
  end if;
  update public.tasks set title = v_title
  where id = p_task_id and user_id = auth.uid()
    and status in ('pending', 'in_progress', 'delegated');
  if not found then
    raise exception 'task_not_open' using errcode = 'P0002';
  end if;
end $$;

create or replace function public.delete_task(p_task_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  perform 1 from public.tasks
  where id = p_task_id and user_id = auth.uid()
    and status in ('pending', 'in_progress', 'delegated')
  for update;
  if not found then
    raise exception 'task_not_open' using errcode = 'P0002';
  end if;
  if exists (select 1 from public.dungeon_runs r join public.tasks t on t.id = r.task_id
             where t.id = p_task_id or t.parent_task_id = p_task_id) then
    raise exception 'task_in_use' using errcode = 'P0001';
  end if;
  delete from public.focus_session_tasks
  where task_id in (select id from public.tasks where id = p_task_id or parent_task_id = p_task_id);
  delete from public.tasks where parent_task_id = p_task_id;
  delete from public.tasks where id = p_task_id;
end $$;

-- 2. Hábitos --------------------------------------------------------------------------
create or replace function public.rename_habit(p_habit_id uuid, p_name text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare v_name text := trim(coalesce(p_name, ''));
begin
  if auth.uid() is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  if v_name = '' or length(v_name) > 100 then
    raise exception 'invalid_name' using errcode = '22023';
  end if;
  update public.habits set name = v_name where id = p_habit_id and user_id = auth.uid();
  if not found then
    raise exception 'habit_not_found' using errcode = 'P0002';
  end if;
end $$;

create or replace function public.delete_habit(p_habit_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  perform 1 from public.habits where id = p_habit_id and user_id = auth.uid() for update;
  if not found then
    raise exception 'habit_not_found' using errcode = 'P0002';
  end if;
  delete from public.habit_records where habit_id = p_habit_id;
  delete from public.habits where id = p_habit_id;
end $$;

-- 3. NPCs -------------------------------------------------------------------------------
create or replace function public.rename_npc(p_npc_id uuid, p_name text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare v_name text := trim(coalesce(p_name, ''));
begin
  if auth.uid() is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  if v_name = '' or length(v_name) > 60 then
    raise exception 'invalid_name' using errcode = '22023';
  end if;
  update public.npcs set name = v_name where id = p_npc_id and user_id = auth.uid();
  if not found then
    raise exception 'npc_not_found' using errcode = 'P0002';
  end if;
end $$;

create or replace function public.delete_npc(p_npc_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  perform 1 from public.npcs where id = p_npc_id and user_id = auth.uid() for update;
  if not found then
    raise exception 'npc_not_found' using errcode = 'P0002';
  end if;
  update public.tasks set npc_id = null where npc_id = p_npc_id;
  update public.resources set npc_id = null where npc_id = p_npc_id;
  delete from public.npcs where id = p_npc_id;
end $$;

-- Permisos ---------------------------------------------------------------------
do $$
declare f text;
begin
  foreach f in array array['public.rename_task(uuid, text)', 'public.delete_task(uuid)',
    'public.rename_habit(uuid, text)', 'public.delete_habit(uuid)',
    'public.rename_npc(uuid, text)', 'public.delete_npc(uuid)'] loop
    execute format('revoke all on function %s from public, anon', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;

commit;

-- ===== 029_notifications.sql =====
-- Migración 029 · Centro de avisos (requiere 001–028).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- 1. notifications_overview(p_day): genera los avisos del día que falten y
--    devuelve los últimos 50. Cada evento tiene event_key único
--    (<categoría>:<entidad_id>:<fecha>), así que nunca se repite (CLAUDE.md §7).
--      ▲ crítico       streak  racha en curso de un hábito que toca hoy y no se ha cumplido
--                      project proyecto con urgencia 🔴 (_project_urgency, 013)
--      ● motivacional  level   a ≤ 10 % de XP de subir de nivel
--                      chest   cofre del día listo para abrir (027)
--      ○ informativo   due     misiones que vencen hoy
--    Si una categoría no crítica se ignoró 5 veces seguidas
--    (notification_category_state.reduced, 007), deja de generarse.
-- 2. mark_notifications_read(p_ids): marca leídas las indicadas, o todas si
--    p_ids es null; el trigger de 007 reinicia el contador de ignoradas.
--
-- shortcut: solo el centro de avisos dentro de la app. Las notificaciones
-- push, el digest y la ventana de silencio necesitan Edge Functions.

begin;

create or replace function public.notifications_overview(p_day date)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_reduced text[];
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  select coalesce(array_agg(category), '{}') into v_reduced
  from public.notification_category_state where user_id = v_uid and reduced;

  insert into public.notifications (user_id, type, category, event_key, title, message,
                                    related_entity_type, related_entity_id, sent_at)
  select v_uid, x.type::public.notification_type, x.category, x.key, x.title, x.message,
         x.entity_type, x.entity_id, now()
  from (
    -- ▲ Racha en riesgo (tono de invitación, nunca de amenaza).
    select 'critical' type, 'streak' category,
           'streak:' || h.id || ':' || p_day key,
           'Tu racha te está esperando 🔥' title,
           'Llevas ' || h.current_streak || ' días con «' || h.name || '». Hoy puedes sumar uno más.' message,
           'habit' entity_type, h.id entity_id
    from public.habits h
    where h.user_id = v_uid and h.type = 'good' and coalesce(h.current_streak, 0) > 0
      and (h.frequency = 'daily' or extract(dow from p_day)::int = any (h.specific_days))
      and not exists (select 1 from public.habit_records r
                      where r.habit_id = h.id and r.completed_on = p_day)
    union all
    -- ▲ Proyecto en 🔴.
    select 'critical', 'project', 'project:' || p.id || ':' || p_day,
           'Un proyecto necesita tu atención',
           '«' || p.title || '» va con el tiempo justo. Una misión hoy lo pone al día.',
           'project', p.id
    from public.projects p
    cross join lateral (
      select count(*)::int total, count(*) filter (where t.status = 'completed')::int done
      from public.tasks t where t.project_id = p.id and t.parent_task_id is null) c
    where p.user_id = v_uid and p.archived_at is null and p.status in ('not_started', 'in_progress')
      and public._project_urgency(c.total, c.done, coalesce(p.start_date, p.created_at::date),
                                  p.end_date, p_day) = 'high'
    union all
    -- ● Cerca de subir de nivel.
    select 'motivational', 'level', 'level:' || v_uid || ':' || s.level,
           'Estás a un paso del nivel ' || (s.level + 1),
           'Te faltan ' || (s.xp_to_next_level - s.current_xp) || ' XP. Una misión más y lo logras.',
           null, null
    from public.character_stats s
    where s.user_id = v_uid and s.current_xp >= s.xp_to_next_level * 0.9
      and not ('level' = any (v_reduced))
    union all
    -- ● Cofre del día listo (misma regla que claim_daily_chest).
    select 'motivational', 'chest', 'chest:' || v_uid || ':' || p_day,
           'Tu cofre del día está listo',
           'Cumpliste tus misiones de hoy. Ábrelo en el Inicio.',
           null, null
    where (select count(*) from public.quest_log_entries
           where user_id = v_uid and source_type::text in ('task', 'npc') and result = 'completed'
             and coin_awarded > 0 and occurred_at >= current_date and occurred_at < current_date + 1)
          >= public.rule('daily_chest_min_missions')
      and not exists (select 1 from public.quest_log_entries
                      where user_id = v_uid and source_type::text = 'daily_chest'
                        and occurred_at >= current_date and occurred_at < current_date + 1)
      and not ('chest' = any (v_reduced))
    union all
    -- ○ Lo que vence hoy.
    select 'informational', 'due', 'due:' || v_uid || ':' || p_day,
           'Tu día de hoy',
           case when n = 1 then 'Hoy vence 1 misión. Tú decides cuándo.'
                else 'Hoy vencen ' || n || ' misiones. Tú decides el orden.' end,
           null, null
    from (select count(*) n from public.tasks
          where user_id = v_uid and parent_task_id is null
            and status in ('pending', 'in_progress')
            and due_date >= p_day::timestamptz and due_date < (p_day + 1)::timestamptz) d
    where n > 0 and not ('due' = any (v_reduced))
  ) x
  on conflict (user_id, event_key) where event_key is not null do nothing;

  return jsonb_build_object(
    'items', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', n.id, 'type', n.type, 'title', n.title, 'message', n.message,
        'created_at', n.created_at, 'read', n.read_at is not null)
        order by n.created_at desc)
      from (select * from public.notifications where user_id = v_uid
            order by created_at desc limit 50) n
    ), '[]'::jsonb),
    'unread', (select count(*) from public.notifications
               where user_id = v_uid and read_at is null)
  );
end $$;

create or replace function public.mark_notifications_read(p_ids uuid[] default null)
returns void
language sql
security invoker
set search_path = ''
as $$
  update public.notifications set read_at = now()
  where user_id = auth.uid() and read_at is null
    and (p_ids is null or id = any (p_ids))
$$;

do $$
declare f text;
begin
  foreach f in array array['public.notifications_overview(date)',
    'public.mark_notifications_read(uuid[])'] loop
    execute format('revoke all on function %s from public, anon', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;

commit;

-- ===== 030_npc_noble_mission.sql =====
-- Migración 030 · La noble misión del NPC pasa a ser obligatoria (requiere 001–029).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- La noble misión es el tema que la Edge Function npc-mission envía a la IA
-- para proponer misiones (p. ej. «fundamentos de diseño gráfico»). create_npc
-- la exige; los NPC antiguos sin ella siguen funcionando (la IA usa la skill).

begin;

create or replace function public.create_npc(
  p_name text,
  p_skill_id uuid,
  p_frequency public.npc_frequency default 'weekly',
  p_noble_mission text default null
)
returns uuid
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_name text := trim(coalesce(p_name, ''));
  v_mission text := trim(coalesce(p_noble_mission, ''));
  v_id uuid;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  if v_name = '' or length(v_name) > 60 then
    raise exception 'invalid_name' using errcode = '22023';
  end if;
  if v_mission = '' or length(v_mission) > 300 then
    raise exception 'invalid_noble_mission' using errcode = '22023';
  end if;
  if p_skill_id is null
     or not exists (select 1 from public.skills where id = p_skill_id and user_id = v_uid) then
    raise exception 'skill_not_found' using errcode = 'P0002';
  end if;
  insert into public.npcs (user_id, name, skill_id, frequency, noble_mission)
  values (v_uid, v_name, p_skill_id, coalesce(p_frequency, 'weekly'), v_mission)
  returning id into v_id;
  return v_id;
end $$;

revoke all on function public.create_npc(text, uuid, public.npc_frequency, text) from public, anon;
grant execute on function public.create_npc(text, uuid, public.npc_frequency, text) to authenticated;

commit;

-- ===== 031_npc_mission_guide.sql =====
  -- Migración 031 · Guía de la misión del NPC (requiere 001–030).
  -- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
  --
  -- RPGenie (Edge Function npc-mission) ya no da solo un título: añade una guía
  -- con objetivo, pasos o ejercicios concretos y pistas, para quien no domina el
  -- tema. La guía se guarda en tasks.description (no hace falta columna nueva).
  --
  -- 1. accept_npc_mission(p_npc_id, p_title, p_description): la descripción es
  --    opcional (máx. 4000 caracteres). Las llamadas con dos argumentos siguen
  --    funcionando.
  -- 2. tavern_overview: la misión abierta devuelve su descripción.

  begin;

  -- 1. Aceptar misión con guía -------------------------------------------------------
  -- La firma cambia: se borra la de dos argumentos para no dejar dos versiones.
  drop function if exists public.accept_npc_mission(uuid, text);

  create or replace function public.accept_npc_mission(
    p_npc_id uuid,
    p_title text,
    p_description text default null
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
    select skill_id into v_skill from public.npcs where id = p_npc_id and user_id = v_uid;
    if not found then
      raise exception 'npc_not_found' using errcode = 'P0002';
    end if;
    if exists (select 1 from public.tasks where npc_id = p_npc_id
              and status in ('pending', 'in_progress')) then
      raise exception 'npc_mission_open' using errcode = 'P0001';
    end if;
    v_paid := public.request_npc_mission(p_npc_id);
    insert into public.tasks (user_id, npc_id, skill_id, title, description, source)
    values (v_uid, p_npc_id, v_skill, v_title, v_description, 'npc')
    returning id into v_task;
    return v_paid || jsonb_build_object('task_id', v_task);
  end $$;

  -- 2. Taverna con la guía de la misión abierta ----------------------------------------
  create or replace function public.tavern_overview()
  returns jsonb
  language sql
  stable
  security invoker
  set search_path = ''
  as $$
    select jsonb_build_object(
      'npcs', coalesce((
        select jsonb_agg(jsonb_build_object(
          'id', n.id,
          'name', n.name,
          'noble_mission', n.noble_mission,
          'frequency', n.frequency,
          'skill_name', s.name,
          'free_at', case when n.last_mission_at is not null
                          then n.last_mission_at
                              + make_interval(hours => public.rule('npc_free_hours')::integer) end,
          'open_mission', (
            select jsonb_build_object('id', t.id, 'title', t.title,
                                      'description', t.description, 'xp_reward', t.xp_reward)
            from public.tasks t
            where t.npc_id = n.id and t.status in ('pending', 'in_progress')
            order by t.created_at desc limit 1),
          'completed', (select count(*) from public.tasks t
                        where t.npc_id = n.id and t.status = 'completed')
        ) order by n.created_at)
        from public.npcs n join public.skills s on s.id = n.skill_id
      ), '[]'::jsonb),
      'npc_limit', public.rule('npc_base_limit') + coalesce((
        select level from public.refuge_upgrades where building = 'estandarte'), 0),
      'instant_cost', public.rule('npc_instant_cost'),
      'coins', coalesce((select coins from public.character_stats), 0),
      'skills', coalesce((
        select jsonb_agg(jsonb_build_object('id', id, 'name', name) order by created_at)
        from public.skills
      ), '[]'::jsonb)
    )
  $$;

  -- Permisos ---------------------------------------------------------------------
  revoke all on function public.accept_npc_mission(uuid, text, text) from public, anon;
  grant execute on function public.accept_npc_mission(uuid, text, text) to authenticated;
  revoke all on function public.tavern_overview() from public, anon;
  grant execute on function public.tavern_overview() to authenticated;

  commit;

-- ===== 032_npc_documents.sql =====
-- Migración 032 · Documentos de contexto del NPC (requiere 001–031).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- El usuario adjunta al NPC un documento (p. ej. el plan de la asignatura) en
-- PDF, Word (.docx) o Markdown. La Edge Function npc-context lo resume UNA vez
-- con Gemini (temas, unidades, objetivos) y npc-mission usa ese resumen para
-- proponer misiones en el orden del documento (PLAN-REDISENO §13, prioridad 1).
--
-- 1. Bucket privado `npc-context` (máx. 10 MB; ruta <user_id>/<npc_id>/<archivo>)
--    con políticas de Storage: cada usuario solo ve, sube y borra su carpeta.
-- 2. resources.ai_summary: el resumen. El documento es un Recurso de P.A.R.A.
--    con npc_id (CLAUDE.md §4) y file_url = ruta en el bucket.
-- 3. add_npc_document: la llama npc-context con el JWT del usuario tras resumir.
--    Máx. 3 documentos por NPC.
-- 4. remove_npc_document: borra la fila y devuelve la ruta para quitar el archivo.
-- 5. tavern_overview: cada NPC lista sus documentos.

begin;

-- 1. Bucket y políticas de Storage ---------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('npc-context', 'npc-context', false, 10485760, array[
  'application/pdf',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'text/markdown', 'text/plain'])
on conflict (id) do update
  set public = false,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "npc-context: leer lo propio" on storage.objects;
create policy "npc-context: leer lo propio" on storage.objects
  for select to authenticated
  using (bucket_id = 'npc-context' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "npc-context: subir a lo propio" on storage.objects;
create policy "npc-context: subir a lo propio" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'npc-context' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "npc-context: borrar lo propio" on storage.objects;
create policy "npc-context: borrar lo propio" on storage.objects
  for delete to authenticated
  using (bucket_id = 'npc-context' and (storage.foldername(name))[1] = auth.uid()::text);

-- 2. Resumen del documento -------------------------------------------------------------
alter table public.resources add column if not exists ai_summary text;

-- 3. Guardar el documento ya resumido ----------------------------------------------------
create or replace function public.add_npc_document(
  p_npc_id uuid,
  p_title text,
  p_path text,
  p_summary text
)
returns uuid
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_title text := trim(coalesce(p_title, ''));
  v_summary text := trim(coalesce(p_summary, ''));
  v_id uuid;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  perform 1 from public.npcs where id = p_npc_id and user_id = v_uid;
  if not found then
    raise exception 'npc_not_found' using errcode = 'P0002';
  end if;
  if v_title = '' or length(v_title) > 120 then
    raise exception 'invalid_title' using errcode = '22023';
  end if;
  -- El archivo tiene que estar en la carpeta del usuario y del NPC.
  if p_path is null or p_path not like v_uid::text || '/' || p_npc_id::text || '/%' then
    raise exception 'invalid_path' using errcode = '22023';
  end if;
  if v_summary = '' or length(v_summary) > 8000 then
    raise exception 'invalid_summary' using errcode = '22023';
  end if;
  if (select count(*) from public.resources
      where npc_id = p_npc_id and archived_at is null) >= 3 then
    raise exception 'npc_document_limit' using errcode = 'P0001';
  end if;
  insert into public.resources (user_id, npc_id, title, file_url, ai_summary)
  values (v_uid, p_npc_id, v_title, p_path, v_summary)
  returning id into v_id;
  return v_id;
end $$;

-- 4. Quitar un documento ----------------------------------------------------------------
-- Devuelve la ruta en el bucket para que la app borre también el archivo.
create or replace function public.remove_npc_document(p_id uuid)
returns text
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_path text;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  delete from public.resources
  where id = p_id and user_id = auth.uid() and npc_id is not null
  returning file_url into v_path;
  if v_path is null then
    raise exception 'document_not_found' using errcode = 'P0002';
  end if;
  return v_path;
end $$;

-- 5. Taverna con los documentos de cada NPC ------------------------------------------
create or replace function public.tavern_overview()
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  select jsonb_build_object(
    'npcs', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', n.id,
        'name', n.name,
        'noble_mission', n.noble_mission,
        'frequency', n.frequency,
        'skill_name', s.name,
        'free_at', case when n.last_mission_at is not null
                        then n.last_mission_at
                             + make_interval(hours => public.rule('npc_free_hours')::integer) end,
        'open_mission', (
          select jsonb_build_object('id', t.id, 'title', t.title,
                                    'description', t.description, 'xp_reward', t.xp_reward)
          from public.tasks t
          where t.npc_id = n.id and t.status in ('pending', 'in_progress')
          order by t.created_at desc limit 1),
        'completed', (select count(*) from public.tasks t
                      where t.npc_id = n.id and t.status = 'completed'),
        'documents', coalesce((
          select jsonb_agg(jsonb_build_object('id', r.id, 'title', r.title)
                           order by r.created_at)
          from public.resources r
          where r.npc_id = n.id and r.archived_at is null
        ), '[]'::jsonb)
      ) order by n.created_at)
      from public.npcs n join public.skills s on s.id = n.skill_id
    ), '[]'::jsonb),
    'npc_limit', public.rule('npc_base_limit') + coalesce((
      select level from public.refuge_upgrades where building = 'estandarte'), 0),
    'instant_cost', public.rule('npc_instant_cost'),
    'coins', coalesce((select coins from public.character_stats), 0),
    'skills', coalesce((
      select jsonb_agg(jsonb_build_object('id', id, 'name', name) order by created_at)
      from public.skills
    ), '[]'::jsonb)
  )
$$;

-- Permisos ---------------------------------------------------------------------
do $$
declare f text;
begin
  foreach f in array array['public.add_npc_document(uuid, text, text, text)',
    'public.remove_npc_document(uuid)', 'public.tavern_overview()'] loop
    execute format('revoke all on function %s from public, anon', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;

commit;

-- ===== 033_dungeon_rewards.sql =====
-- Migración 033 · Botín y tiempo efectivo de la Mazmorra (requiere 001–032).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- 1. Lo ganado en la sesión suma los ciclos Y las misiones de la mochila
--    completadas durante la sesión (antes solo los ciclos: completar una misión
--    dentro de la Mazmorra no cambiaba la tarjeta de recompensas).
-- 2. Tiempo efectivo = ciclos completados × duración del ciclo: solo el tiempo
--    de concentración que el servidor validó y pagó. end_dungeon devolvía el
--    tiempo de reloj desde el inicio, con descansos y pausas incluidos.
--
-- dungeon_overview: cuerpo de 017 + `missions_done` y `focus_minutes`.
-- end_dungeon: cuerpo de 012 + `missions` y `minutes` efectivos.

begin;

-- Recompensas de una sesión: ciclos (source 'dungeon') y misiones de su mochila
-- completadas desde que empezó (source 'task' o 'npc', ver complete_task 005).
create or replace function public._dungeon_loot(p_session_id uuid)
returns table (xp bigint, coins bigint, missions bigint)
language sql
stable
security invoker
set search_path = ''
as $$
  with s as (
    select * from public.focus_sessions where id = p_session_id
  ),
  q as (
    select q.xp_awarded, q.coin_awarded, q.source_type
    from public.quest_log_entries q, s
    where q.user_id = s.user_id
      and (
        (q.source_type = 'dungeon'
         and q.source_id in (select r.id from public.dungeon_runs r where r.session_id = s.id))
        or
        (q.source_type in ('task', 'npc')
         and q.result = 'completed'
         and q.occurred_at >= s.started_at
         and q.occurred_at <= coalesce(s.ended_at, now())
         and q.source_id in (select f.task_id from public.focus_session_tasks f
                             where f.session_id = s.id))
      )
  )
  select coalesce(sum(xp_awarded), 0),
         coalesce(sum(coin_awarded), 0),
         count(*) filter (where source_type in ('task', 'npc'))
  from q
$$;

-- 1. Datos de la pantalla Mazmorra ----------------------------------------------
create or replace function public.dungeon_overview()
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  with s as (
    select * from public.focus_sessions
    where user_id = auth.uid() and status in ('active', 'paused')
    order by started_at desc limit 1
  ),
  runs as (
    select r.* from public.dungeon_runs r join s on s.id = r.session_id
  )
  select jsonb_build_object(
    'session', (
      select jsonb_build_object(
        'id', s.id,
        'total_minutes', s.total_minutes,
        'cycle_minutes', s.cycle_minutes,
        'started_at', s.started_at,
        'cycles_done', (select count(*) from runs),
        'xp_earned', l.xp,
        'coins_earned', l.coins,
        'missions_done', l.missions,
        'focus_minutes', (select count(*) from runs) * s.cycle_minutes,
        'tasks', coalesce((
          select jsonb_agg(jsonb_build_object(
            'id', t.id,
            'title', t.title,
            'done', t.status = 'completed',
            'cycles', (select count(*) from runs where runs.task_id = t.id)
          ) order by t.created_at)
          from public.focus_session_tasks f join public.tasks t on t.id = f.task_id
          where f.session_id = s.id
        ), '[]'::jsonb)
      )
      from s, public._dungeon_loot(s.id) l
    ),
    'candidates', coalesce((
      select jsonb_agg(jsonb_build_object('id', c.id, 'title', c.title, 'bucket', c.bucket)
                       order by c.bucket_order, c.due_date nulls last)
      from (select * from public.v_daily_highlight
            order by bucket_order, due_date nulls last limit 30) c
    ), '[]'::jsonb),
    'max_tasks', public.rule('dungeon_max_tasks')::integer,
    'cycle_xp', public.rule('dungeon_cycle_xp')::integer,
    -- RF-067: descansos que el jugador eligió en Configuración (016).
    'breaks', (
      select jsonb_build_object(
        'short_minutes', g.short_break_minutes,
        'long_minutes', g.long_break_minutes,
        'long_every_n_cycles', g.long_break_every_n_cycles
      )
      from public.game_master_settings g where g.user_id = auth.uid()
    )
  )
$$;

-- 2. Terminar la sesión con el botín completo -------------------------------------
create or replace function public.end_dungeon(p_session_id uuid)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_session public.focus_sessions;
  v_cycles integer;
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
  select count(*) into v_cycles from public.dungeon_runs where session_id = p_session_id;
  return (
    select jsonb_build_object(
      'cycles', v_cycles,
      'xp', l.xp,
      'coins', l.coins,
      'missions', l.missions,
      -- Tiempo efectivo: solo los ciclos de concentración cobrados.
      'minutes', v_cycles * v_session.cycle_minutes
    )
    from public._dungeon_loot(p_session_id) l
  );
end $$;

-- Permisos ---------------------------------------------------------------------
revoke all on function public._dungeon_loot(uuid) from public, anon;
grant execute on function public._dungeon_loot(uuid) to authenticated;
do $$
declare f text;
begin
  foreach f in array array['public.dungeon_overview()', 'public.end_dungeon(uuid)'] loop
    execute format('revoke all on function %s from public, anon', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;

commit;

-- ===== 034_brain_dump_goal.sql =====
-- Migración 034 · Del Brain Dump a una Meta S.M.A.R.T. (requiere 001–033).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- Antes, el G.T.D. del Brain Dump mandaba a Stage cuando la idea era «un
-- resultado de meses» y no creaba nada: la idea seguía en la bandeja y había
-- que volver a escribirla. Ahora el formulario S.M.A.R.T. se abre en el propio
-- Brain Dump (RF-014: Goal pasa por S.M.A.R.T.) y:
--
-- 1. convert_thought_to_goal: crea la Meta con create_goal (014, mismas
--    validaciones) y marca la idea como convertida, en una transacción.
-- 2. brain_dump_overview: añade `skills` para vincular la Meta a un Área.

begin;

-- 1. Convertir en Meta ------------------------------------------------------------------
create or replace function public.convert_thought_to_goal(
  p_id uuid,
  p_title text,
  p_specific text,
  p_measurable text,
  p_achievable text,
  p_relevant text,
  p_due_date date,
  p_timebound text default null,
  p_skill_id uuid default null
)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_id uuid;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  perform 1 from public.brain_dump_entries
  where id = p_id and user_id = v_uid and status <> 'converted' for update;
  if not found then
    raise exception 'thought_not_found' using errcode = 'P0002';
  end if;
  v_id := public.create_goal(p_title, p_specific, p_measurable, p_achievable, p_relevant,
                             p_due_date, p_timebound, p_skill_id);
  update public.brain_dump_entries
  set status = 'converted', converted_to_type = 'goal', converted_to_id = v_id
  where id = p_id;
  return jsonb_build_object('id', v_id, 'type', 'goal');
end $$;

-- 2. Bandeja con las skills del jugador -------------------------------------------------
create or replace function public.brain_dump_overview()
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  select jsonb_build_object(
    'inbox', coalesce((
      select jsonb_agg(jsonb_build_object('id', id, 'content', content, 'created_at', created_at)
                       order by created_at desc)
      from public.brain_dump_entries where status = 'pending'
    ), '[]'::jsonb),
    'someday', coalesce((
      select jsonb_agg(jsonb_build_object('id', id, 'content', content, 'created_at', created_at)
                       order by created_at desc)
      from public.brain_dump_entries where status = 'someday'
    ), '[]'::jsonb),
    'reference', coalesce((
      select jsonb_agg(jsonb_build_object('id', id, 'content', content, 'created_at', created_at)
                       order by created_at desc)
      from public.brain_dump_entries where status = 'reference'
    ), '[]'::jsonb),
    'converted_today', (
      select count(*) from public.brain_dump_entries
      where status = 'converted' and created_at >= current_date
    ),
    'skills', coalesce((
      select jsonb_agg(jsonb_build_object('id', id, 'name', name) order by created_at)
      from public.skills
    ), '[]'::jsonb)
  )
$$;

-- Permisos ---------------------------------------------------------------------
do $$
declare f text;
begin
  foreach f in array array['public.brain_dump_overview()',
    'public.convert_thought_to_goal(uuid, text, text, text, text, text, date, text, uuid)'] loop
    execute format('revoke all on function %s from public, anon', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;

commit;

-- ===== 035_resources.sql =====
-- Migración 035 · Recursos: enlaces, notas y documentos, con vínculos
-- (requiere 001–034). Ejecutar una vez en Supabase → SQL Editor. Se puede volver
-- a ejecutar.
--
-- Un Recurso de P.A.R.A. ya no es solo un enlace:
-- 1. resources.kind: 'link' (file_url = URL), 'note' (content) o 'document'
--    (file_url = ruta en Storage y storage_bucket). Vínculos opcionales a un
--    Proyecto, una Meta o una Skill (Área), con ON DELETE SET NULL (§8).
--    Los documentos de contexto de los NPC (032) pasan a ser 'document' del
--    bucket `npc-context`.
-- 2. Bucket privado `resources` (máx. 10 MB; ruta <user_id>/<archivo>) con las
--    mismas políticas por carpeta que `npc-context`.
-- 3. create_resource(título, tipo, enlace, nota, ruta, proyecto, meta, skill).
--    La llamada antigua create_resource(p_title, p_url) sigue valiendo.
-- 4. add_npc_document (032) guarda sus documentos como 'document'.
-- 5. stage_overview (014) devuelve el tipo, la nota, la ruta y los vínculos.

begin;

-- 1. Tipos y vínculos -----------------------------------------------------------------
do $$
begin
  if not exists (select 1 from pg_type where typname = 'resource_kind') then
    create type public.resource_kind as enum ('link', 'note', 'document');
  end if;
end $$;

alter table public.resources
  add column if not exists kind public.resource_kind not null default 'link',
  add column if not exists content text,
  add column if not exists storage_bucket text,
  add column if not exists project_id uuid references public.projects(id) on delete set null,
  add column if not exists goal_id uuid references public.goals(id) on delete set null,
  add column if not exists skill_id uuid references public.skills(id) on delete set null;
alter table public.resources alter column file_url drop not null;

-- Documentos de los NPC guardados antes de esta migración.
update public.resources
set kind = 'document', storage_bucket = 'npc-context'
where npc_id is not null and storage_bucket is null;

alter table public.resources drop constraint if exists resources_kind_fields;
alter table public.resources add constraint resources_kind_fields check (
  (kind = 'link' and file_url is not null)
  or (kind = 'note' and content is not null)
  or (kind = 'document' and file_url is not null and storage_bucket is not null)
);

-- 2. Bucket de documentos ---------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('resources', 'resources', false, 10485760, array[
  'application/pdf',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  'application/vnd.openxmlformats-officedocument.presentationml.presentation',
  'text/markdown', 'text/plain', 'image/png', 'image/jpeg'])
on conflict (id) do update
  set public = false,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "resources: leer lo propio" on storage.objects;
create policy "resources: leer lo propio" on storage.objects
  for select to authenticated
  using (bucket_id = 'resources' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "resources: subir a lo propio" on storage.objects;
create policy "resources: subir a lo propio" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'resources' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "resources: borrar lo propio" on storage.objects;
create policy "resources: borrar lo propio" on storage.objects
  for delete to authenticated
  using (bucket_id = 'resources' and (storage.foldername(name))[1] = auth.uid()::text);

-- 3. Crear un recurso ---------------------------------------------------------------------
drop function if exists public.create_resource(text, text);

create or replace function public.create_resource(
  p_title text,
  p_url text default null,
  p_kind public.resource_kind default 'link',
  p_content text default null,
  p_path text default null,
  p_project_id uuid default null,
  p_goal_id uuid default null,
  p_skill_id uuid default null
)
returns uuid
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_title text := trim(coalesce(p_title, ''));
  v_url text := nullif(trim(coalesce(p_url, '')), '');
  v_content text := nullif(trim(coalesce(p_content, '')), '');
  v_path text := nullif(trim(coalesce(p_path, '')), '');
  v_kind public.resource_kind := coalesce(p_kind, 'link');
  v_id uuid;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  if v_title = '' or length(v_title) > 200 then
    raise exception 'invalid_title' using errcode = '22023';
  end if;
  if v_kind = 'link' and (v_url is null or v_url !~* '^https?://[^\s]+$' or length(v_url) > 2000) then
    raise exception 'invalid_url' using errcode = '22023';
  end if;
  if v_kind = 'note' and (v_content is null or length(v_content) > 10000) then
    raise exception 'invalid_content' using errcode = '22023';
  end if;
  -- El archivo tiene que estar en la carpeta del usuario dentro del bucket.
  if v_kind = 'document'
     and (v_path is null or length(v_path) > 500 or v_path not like v_uid::text || '/%') then
    raise exception 'invalid_path' using errcode = '22023';
  end if;
  if p_project_id is not null and not exists (
       select 1 from public.projects where id = p_project_id and user_id = v_uid
       and archived_at is null) then
    raise exception 'project_not_found' using errcode = 'P0002';
  end if;
  if p_goal_id is not null and not exists (
       select 1 from public.goals where id = p_goal_id and user_id = v_uid
       and archived_at is null) then
    raise exception 'goal_not_found' using errcode = 'P0002';
  end if;
  if p_skill_id is not null and not exists (
       select 1 from public.skills where id = p_skill_id and user_id = v_uid) then
    raise exception 'skill_not_found' using errcode = 'P0002';
  end if;
  insert into public.resources (user_id, title, kind, file_url, content, storage_bucket,
                                project_id, goal_id, skill_id)
  values (v_uid, v_title, v_kind,
          case v_kind when 'link' then v_url when 'document' then v_path end,
          case when v_kind = 'note' then v_content end,
          case when v_kind = 'document' then 'resources' end,
          p_project_id, p_goal_id, p_skill_id)
  returning id into v_id;
  return v_id;
end $$;

-- 4. Documentos de los NPC como 'document' (cuerpo de 032) ------------------------------
create or replace function public.add_npc_document(
  p_npc_id uuid,
  p_title text,
  p_path text,
  p_summary text
)
returns uuid
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_title text := trim(coalesce(p_title, ''));
  v_summary text := trim(coalesce(p_summary, ''));
  v_id uuid;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  perform 1 from public.npcs where id = p_npc_id and user_id = v_uid;
  if not found then
    raise exception 'npc_not_found' using errcode = 'P0002';
  end if;
  if v_title = '' or length(v_title) > 120 then
    raise exception 'invalid_title' using errcode = '22023';
  end if;
  if p_path is null or p_path not like v_uid::text || '/' || p_npc_id::text || '/%' then
    raise exception 'invalid_path' using errcode = '22023';
  end if;
  if v_summary = '' or length(v_summary) > 8000 then
    raise exception 'invalid_summary' using errcode = '22023';
  end if;
  if (select count(*) from public.resources
      where npc_id = p_npc_id and archived_at is null) >= 3 then
    raise exception 'npc_document_limit' using errcode = 'P0001';
  end if;
  insert into public.resources (user_id, npc_id, title, kind, file_url, storage_bucket, ai_summary)
  values (v_uid, p_npc_id, v_title, 'document', p_path, 'npc-context', v_summary)
  returning id into v_id;
  return v_id;
end $$;

-- 5. Stage con los recursos completos (cuerpo de 014) -----------------------------------
create or replace function public.stage_overview(p_day date)
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  with p as (
    select p.*,
      (select count(*) from public.tasks t where t.project_id = p.id and t.parent_task_id is null)::int as total,
      (select count(*) from public.tasks t where t.project_id = p.id and t.parent_task_id is null
         and t.status = 'completed')::int as done
    from public.projects p
  )
  select jsonb_build_object(
    'highlight', coalesce((
      select jsonb_agg(jsonb_build_object('id', h.id, 'title', h.title, 'bucket', h.bucket,
                                          'due_date', h.due_date) order by h.n)
      -- Mismo orden que missions_overview (010): empata por antigüedad.
      from (select v.*, row_number() over (order by v.bucket_order, v.due_date nulls last,
                                                    t.created_at) n
            from public.v_daily_highlight v join public.tasks t on t.id = v.id) h
      where h.n <= 5
    ), '[]'::jsonb),
    'highlight_total', (select count(*) from public.v_daily_highlight),
    'projects', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', p.id,
        'title', p.title,
        'skill_name', s.name,
        'goal_title', g.title,
        'end_date', p.end_date,
        'tasks_total', p.total,
        'tasks_done', p.done,
        'urgency', public._project_urgency(p.total, p.done,
                     coalesce(p.start_date, p.created_at::date), p.end_date, p_day),
        'tasks', coalesce((
          select jsonb_agg(jsonb_build_object('id', t.id, 'title', t.title,
                                              'done', t.status = 'completed')
                           order by t.status = 'completed', t.created_at)
          from public.tasks t
          where t.project_id = p.id and t.parent_task_id is null
            and t.status in ('pending', 'in_progress', 'delegated', 'completed')
        ), '[]'::jsonb)
      ) order by p.end_date nulls last, p.created_at)
      from p
      left join public.skills s on s.id = p.skill_id
      left join public.goals g on g.id = p.goal_id
      where p.status in ('not_started', 'in_progress') and p.archived_at is null
    ), '[]'::jsonb),
    'areas', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', s.id,
        'name', s.name,
        'level', s.level,
        'open_tasks', (select count(*) from public.tasks t where t.skill_id = s.id
                         and t.parent_task_id is null
                         and t.status in ('pending', 'in_progress', 'delegated')),
        'projects', (select count(*) from public.projects pr where pr.skill_id = s.id
                       and pr.status in ('not_started', 'in_progress') and pr.archived_at is null),
        'habits', (select count(*) from public.habits hb where hb.skill_id = s.id)
      ) order by s.created_at)
      from public.skills s
    ), '[]'::jsonb),
    'resources', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', r.id,
        'title', r.title,
        'kind', r.kind,
        'url', case when r.kind = 'link' then r.file_url end,
        'content', r.content,
        'path', case when r.kind = 'document' then r.file_url end,
        'bucket', r.storage_bucket,
        'project_id', r.project_id,
        'project_title', pr.title,
        'goal_id', r.goal_id,
        'goal_title', g.title,
        'skill_id', r.skill_id,
        'skill_name', s.name,
        'npc_name', n.name
      ) order by r.created_at desc)
      from public.resources r
      left join public.projects pr on pr.id = r.project_id
      left join public.goals g on g.id = r.goal_id
      left join public.skills s on s.id = r.skill_id
      left join public.npcs n on n.id = r.npc_id
      where r.archived_at is null
    ), '[]'::jsonb),
    'archive', jsonb_build_object(
      'projects', (select count(*) from public.projects
                   where archived_at is not null or status in ('completed', 'expired')),
      'goals', (select count(*) from public.goals
                where archived_at is not null or status in ('completed', 'expired')),
      'resources', (select count(*) from public.resources where archived_at is not null)
    ),
    'skills', coalesce((
      select jsonb_agg(jsonb_build_object('id', id, 'name', name) order by created_at)
      from public.skills
    ), '[]'::jsonb),
    'goals', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', g.id,
        'title', g.title,
        'skill_name', s.name,
        'due_date', g.due_date,
        'boss_hp', g.boss_current_hp,
        'boss_max_hp', g.boss_max_hp,
        'projects', (select count(*) from public.projects pr where pr.goal_id = g.id
                       and pr.status in ('not_started', 'in_progress') and pr.archived_at is null),
        'open_tasks', (select count(*) from public.tasks t where t.goal_id = g.id
                         and t.parent_task_id is null
                         and t.status in ('pending', 'in_progress', 'delegated'))
      ) order by g.due_date nulls last, g.created_at)
      from public.goals g
      left join public.skills s on s.id = g.skill_id
      where g.status in ('not_started', 'in_progress') and g.archived_at is null
    ), '[]'::jsonb)
  )
$$;

-- Permisos ---------------------------------------------------------------------
do $$
declare f text;
begin
  foreach f in array array['public.stage_overview(date)',
    'public.create_resource(text, text, public.resource_kind, text, text, uuid, uuid, uuid)',
    'public.add_npc_document(uuid, text, text, text)'] loop
    execute format('revoke all on function %s from public, anon', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;

commit;

-- ===== 036_device_notifications.sql =====
-- Migración 036 · Avisos en el dispositivo (requiere 001–029; no depende de 030–035).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- El móvil revisa cada ~15 min en segundo plano (workmanager) y muestra como
-- notificación local lo que esta migración le entrega. Las reglas anti-estrés
-- de CLAUDE.md §7 se aplican aquí, en el servidor:
--   ▲ crítico       uno por uno y al momento. Respeta la ventana de silencio
--                   salvo critical_bypass_silence. La racha solo se avisa desde
--                   las notify_streak_hour (últimas horas del día).
--   ● motivacional  al momento, sin repetirse nunca.
--   ○ informativo   agrupado en un digest desde digest_time (o notify_digest_hour).
--   Lo no crítico espera mientras dure la ventana de silencio o una sesión de
--   Mazmorra, y cuenta para notification_daily_limit (un digest cuenta 1).
--   Un aviso entregado y sin leer en notify_ignored_after_hours queda como
--   ignorado: el trigger de 007 baja la frecuencia de su categoría tras 5.
--
-- 1. device_registrations: un código aleatorio por dispositivo (solo se guarda
--    su hash). El proceso de fondo no usa la sesión de Supabase: si refrescara
--    el token a la vez que la app abierta, una de las dos perdería la sesión.
-- 2. register_device() / unregister_device(token).
-- 3. _generate_notifications(uid, día): la generación de 029, ahora reutilizable;
--    notifications_overview la llama y devuelve lo mismo que antes.
-- 4. device_notifications(token, día, hora): genera, aplica las reglas, marca
--    delivered_at y devuelve lo que hay que mostrar.

begin;

alter table public.notifications add column if not exists delivered_at timestamptz;

insert into public.game_rules (key, value, provisional, note) values
  ('notify_streak_hour',         18, true, 'hora local desde la que se avisa una racha en riesgo'),
  ('notify_digest_hour',          8, true, 'hora local del digest si el usuario no eligió digest_time'),
  ('notify_ignored_after_hours', 24, true, 'horas sin leer tras las que un aviso entregado cuenta como ignorado')
on conflict (key) do nothing;

-- 1. Dispositivos ------------------------------------------------------------
create table if not exists public.device_registrations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  token_hash bytea not null unique,
  created_at timestamptz not null default now(),
  last_seen_at timestamptz
);
-- Sin políticas: solo se toca con las funciones de abajo.
alter table public.device_registrations enable row level security;
revoke all on public.device_registrations from anon, authenticated;

-- 2. Registro ----------------------------------------------------------------
create or replace function public.register_device()
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_token text := replace(gen_random_uuid()::text || gen_random_uuid()::text, '-', '');
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  insert into public.device_registrations (user_id, token_hash)
  values (v_uid, sha256(convert_to(v_token, 'UTF8')));
  -- Como mucho 5 dispositivos por jugador: se olvidan los más viejos.
  delete from public.device_registrations
  where user_id = v_uid and id not in (
    select id from public.device_registrations where user_id = v_uid
    order by created_at desc limit 5);
  return v_token;
end $$;

-- Quien tiene el código puede darlo de baja (también tras cerrar sesión).
create or replace function public.unregister_device(p_token text)
returns void
language sql
security definer
set search_path = ''
as $$
  delete from public.device_registrations
  where token_hash = sha256(convert_to(coalesce(p_token, ''), 'UTF8'))
$$;

-- 3. Generación (antes dentro de notifications_overview, 029) -----------------
create or replace function public._generate_notifications(p_uid uuid, p_day date)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_reduced text[];
begin
  select coalesce(array_agg(category), '{}') into v_reduced
  from public.notification_category_state where user_id = p_uid and reduced;

  insert into public.notifications (user_id, type, category, event_key, title, message,
                                    related_entity_type, related_entity_id, sent_at)
  select p_uid, x.type::public.notification_type, x.category, x.key, x.title, x.message,
         x.entity_type, x.entity_id, now()
  from (
    -- ▲ Racha en riesgo (tono de invitación, nunca de amenaza).
    select 'critical' type, 'streak' category,
           'streak:' || h.id || ':' || p_day key,
           'Tu racha te está esperando 🔥' title,
           'Llevas ' || h.current_streak || ' días con «' || h.name || '». Hoy puedes sumar uno más.' message,
           'habit' entity_type, h.id entity_id
    from public.habits h
    where h.user_id = p_uid and h.type = 'good' and coalesce(h.current_streak, 0) > 0
      and (h.frequency = 'daily' or extract(dow from p_day)::int = any (h.specific_days))
      and not exists (select 1 from public.habit_records r
                      where r.habit_id = h.id and r.completed_on = p_day)
    union all
    -- ▲ Proyecto en 🔴.
    select 'critical', 'project', 'project:' || p.id || ':' || p_day,
           'Un proyecto necesita tu atención',
           '«' || p.title || '» va con el tiempo justo. Una misión hoy lo pone al día.',
           'project', p.id
    from public.projects p
    cross join lateral (
      select count(*)::int total, count(*) filter (where t.status = 'completed')::int done
      from public.tasks t where t.project_id = p.id and t.parent_task_id is null) c
    where p.user_id = p_uid and p.archived_at is null and p.status in ('not_started', 'in_progress')
      and public._project_urgency(c.total, c.done, coalesce(p.start_date, p.created_at::date),
                                  p.end_date, p_day) = 'high'
    union all
    -- ● Cerca de subir de nivel.
    select 'motivational', 'level', 'level:' || p_uid || ':' || s.level,
           'Estás a un paso del nivel ' || (s.level + 1),
           'Te faltan ' || (s.xp_to_next_level - s.current_xp) || ' XP. Una misión más y lo logras.',
           null, null
    from public.character_stats s
    where s.user_id = p_uid and s.current_xp >= s.xp_to_next_level * 0.9
      and not ('level' = any (v_reduced))
    union all
    -- ● Cofre del día listo (misma regla que claim_daily_chest).
    select 'motivational', 'chest', 'chest:' || p_uid || ':' || p_day,
           'Tu cofre del día está listo',
           'Cumpliste tus misiones de hoy. Ábrelo en el Inicio.',
           null, null
    where (select count(*) from public.quest_log_entries
           where user_id = p_uid and source_type::text in ('task', 'npc') and result = 'completed'
             and coin_awarded > 0 and occurred_at >= current_date and occurred_at < current_date + 1)
          >= public.rule('daily_chest_min_missions')
      and not exists (select 1 from public.quest_log_entries
                      where user_id = p_uid and source_type::text = 'daily_chest'
                        and occurred_at >= current_date and occurred_at < current_date + 1)
      and not ('chest' = any (v_reduced))
    union all
    -- ○ Lo que vence hoy.
    select 'informational', 'due', 'due:' || p_uid || ':' || p_day,
           'Tu día de hoy',
           case when n = 1 then 'Hoy vence 1 misión. Tú decides cuándo.'
                else 'Hoy vencen ' || n || ' misiones. Tú decides el orden.' end,
           null, null
    from (select count(*) n from public.tasks
          where user_id = p_uid and parent_task_id is null
            and status in ('pending', 'in_progress')
            and due_date >= p_day::timestamptz and due_date < (p_day + 1)::timestamptz) d
    where n > 0 and not ('due' = any (v_reduced))
  ) x
  on conflict (user_id, event_key) where event_key is not null do nothing;
end $$;

create or replace function public.notifications_overview(p_day date)
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
  perform public._generate_notifications(v_uid, p_day);

  return jsonb_build_object(
    'items', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', n.id, 'type', n.type, 'title', n.title, 'message', n.message,
        'created_at', n.created_at, 'read', n.read_at is not null)
        order by n.created_at desc)
      from (select * from public.notifications where user_id = v_uid
            order by created_at desc limit 50) n
    ), '[]'::jsonb),
    'unread', (select count(*) from public.notifications
               where user_id = v_uid and read_at is null)
  );
end $$;

-- 4. Entrega al dispositivo --------------------------------------------------
-- p_day y p_time son la fecha y la hora local del móvil.
create or replace function public.device_notifications(p_token text, p_day date, p_time time)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
  v_now timestamptz := now();
  g public.game_master_settings;
  v_silent boolean;
  v_quiet boolean;
  v_left integer;
  v_count integer;
  v_items jsonb;
  v_digest jsonb;
begin
  update public.device_registrations set last_seen_at = v_now
  where token_hash = sha256(convert_to(coalesce(p_token, ''), 'UTF8'))
  returning user_id into v_uid;
  if v_uid is null then
    raise exception 'device_not_registered' using errcode = '28000';
  end if;

  -- Frecuencia decreciente: lo entregado y no leído a tiempo cuenta como ignorado.
  update public.notifications set ignored = true
  where user_id = v_uid and type <> 'critical' and not ignored and read_at is null
    and delivered_at < v_now - make_interval(hours => public.rule('notify_ignored_after_hours')::int);

  perform public._generate_notifications(v_uid, p_day);

  select * into g from public.game_master_settings where user_id = v_uid;
  v_silent := coalesce(case
    when g.silence_window_start <= g.silence_window_end
      then p_time >= g.silence_window_start and p_time < g.silence_window_end
    else p_time >= g.silence_window_start or p_time < g.silence_window_end end, false);
  v_quiet := v_silent or exists (select 1 from public.focus_sessions
                                 where user_id = v_uid and status in ('active', 'paused'));
  -- Entregas no críticas desde la medianoche local (un digest cuenta 1).
  select coalesce(g.notification_daily_limit - (
           count(*) filter (where digest_slot is null)
           + count(distinct delivered_at) filter (where digest_slot is not null))::int,
         2147483647)
  into v_left
  from public.notifications
  where user_id = v_uid and type <> 'critical'
    and delivered_at >= v_now - (p_time - time '00:00');

  -- ▲ Críticos.
  with sent as (
    update public.notifications n set delivered_at = v_now
    where n.user_id = v_uid and n.delivered_at is null and n.read_at is null
      and n.created_at >= v_now - interval '24 hours' and n.type = 'critical'
      and (not v_silent or coalesce(g.critical_bypass_silence, false))
      and (n.category is distinct from 'streak'
           or p_time >= make_time(public.rule('notify_streak_hour')::int, 0, 0))
    returning n.id, n.type, n.title, n.message, n.created_at)
  select coalesce(jsonb_agg(jsonb_build_object('id', id, 'type', type, 'title', title,
           'message', message, 'created_at', created_at) order by created_at), '[]'::jsonb)
  into v_items from sent;

  -- ● Motivacionales, hasta el límite del día.
  if not v_quiet and v_left > 0 then
    with sent as (
      update public.notifications n set delivered_at = v_now
      where n.id in (select id from public.notifications
                     where user_id = v_uid and delivered_at is null and read_at is null
                       and created_at >= v_now - interval '24 hours' and type = 'motivational'
                     order by created_at limit v_left)
      returning n.id, n.type, n.title, n.message, n.created_at)
    select v_items || coalesce(jsonb_agg(jsonb_build_object('id', id, 'type', type,
             'title', title, 'message', message, 'created_at', created_at)
             order by created_at), '[]'::jsonb), count(*)
    into v_items, v_count from sent;
    v_left := v_left - v_count;
  end if;

  -- ○ Informativos, juntos en un digest.
  if not v_quiet and v_left > 0
     and p_time >= coalesce(g.digest_time, make_time(public.rule('notify_digest_hour')::int, 0, 0)) then
    with sent as (
      update public.notifications n set delivered_at = v_now,
        digest_slot = case when p_time < time '14:00' then 'morning' else 'evening' end::public.digest_slot
      where n.user_id = v_uid and n.delivered_at is null and n.read_at is null
        and n.created_at >= v_now - interval '24 hours' and n.type = 'informational'
      returning n.id, n.title, n.message, n.created_at)
    select case
      when count(*) = 1 then jsonb_build_object('id', min(id::text), 'type', 'informational',
        'title', min(title), 'message', min(message), 'created_at', min(created_at))
      when count(*) > 1 then jsonb_build_object('id', min(id::text), 'type', 'informational',
        'title', 'Tu resumen del día',
        'message', 'Tienes ' || count(*) || ' avisos: ' || string_agg(title, ' · ' order by created_at) || '.',
        'created_at', min(created_at))
      end
    into v_digest from sent;
    if v_digest is not null then
      v_items := v_items || jsonb_build_array(v_digest);
    end if;
  end if;

  return jsonb_build_object('items', v_items);
end $$;

do $$
declare f text;
begin
  foreach f in array array['public.register_device()', 'public.notifications_overview(date)',
    'public._generate_notifications(uuid, date)'] loop
    execute format('revoke all on function %s from public, anon', f);
  end loop;
  revoke all on function public._generate_notifications(uuid, date) from authenticated;
  grant execute on function public.register_device() to authenticated;
  grant execute on function public.notifications_overview(date) to authenticated;
  -- El proceso de fondo llama sin sesión: lo protege el código del dispositivo.
  foreach f in array array['public.unregister_device(text)',
    'public.device_notifications(text, date, time)'] loop
    execute format('revoke all on function %s from public', f);
    execute format('grant execute on function %s to anon, authenticated', f);
  end loop;
end $$;

commit;

-- ===== 037_reward_feedback.sql =====
-- Migración 037 · Respuesta de recompensa para el «momento de recompensa» (requiere 001–036).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- Plan: docs/plan-funcionalidades-asistente.md A1–A2 y A5. La app muestra lo
-- que ganó el usuario leyendo esta respuesta; nunca calcula recompensas.
--
-- 1. _award (005) devuelve además el área (skill_name, skill_level y
--    skill_level_up) y la barra de nivel (current_xp, xp_to_next_level). El
--    cálculo no cambia: misma copia de 005 con esos campos añadidos.
-- 2. complete_habit devuelve jsonb (antes void): la respuesta de _award más la
--    racha (streak, best_streak). Cambiar el tipo obliga a borrarla y crearla
--    de nuevo; se vuelven a dar los mismos permisos que en 005.

begin;

-- 1. _award ----------------------------------------------------------------------
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
  v_skill_name text;
  v_skill_before integer;
  v_skill_after integer;
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

  select name, level into v_skill_name, v_skill_before
  from public.skills where id = p_skill_id and user_id = p_uid;
  v_skill_after := v_skill_before;

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
    where s.id = p_skill_id and s.user_id = p_uid
    returning s.level into v_skill_after;
  end if;

  insert into public.quest_log_entries
    (user_id, source_type, source_id, result, xp_awarded, coin_awarded, hp_change, skill_id)
  values (p_uid, p_source, p_source_id, p_result, v_xp, v_coins, p_hp, p_skill_id);

  return jsonb_build_object(
    'xp', v_xp, 'coins', v_wallet, 'treasury', v_treasury, 'hp_change', p_hp,
    'level', v_level, 'level_up', v_level > v_stats.level,
    'current_xp', v_cur, 'xp_to_next_level', v_next,
    'skill_name', v_skill_name, 'skill_level', v_skill_after,
    'skill_level_up', coalesce(v_skill_after > v_skill_before, false));
end $$;


-- 2. complete_habit --------------------------------------------------------------
drop function if exists public.complete_habit(uuid, date);

create or replace function public.complete_habit(p_habit_id uuid, p_day date)
returns jsonb
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
  return public._award(v_uid, 'habit', p_habit_id, v_xp,
    round(v_xp * public.rule('coin_ratio'))::integer, v_habit.skill_id)
    || jsonb_build_object('streak', v_streak,
                          'best_streak', greatest(v_habit.best_streak, v_streak));
end $$;


revoke all on function public._award(uuid, public.quest_source, uuid, integer, integer, uuid, public.quest_result, integer)
  from public, anon, authenticated;
revoke all on function public.complete_habit(uuid, date) from public, anon;
grant execute on function public.complete_habit(uuid, date) to authenticated;

commit;

-- ===== 038_home_today.sql =====
-- Migración 038 · Lista «Hoy» en el Inicio (requiere 001–037).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- Plan: docs/plan-funcionalidades-asistente.md S2 (Inicio = Hoy).
-- home_dashboard (001) devuelve además today_tasks: hasta 6 tareas abiertas
-- (sin subtareas) que vencen hoy, ya vencieron o tienen prioridad alta. El
-- resto de la función es la misma copia de 001. Completar una sigue siendo
-- complete_task (005), que paga en el servidor.

begin;

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
    -- 038: lista «Hoy» del Inicio (plan S2). Vencen hoy, vencidas o de
    -- prioridad alta; la app quita la que ya muestra como Siguiente paso.
    'today_tasks', coalesce((
      select jsonb_agg(jsonb_build_object(
               'id', t.id,
               'title', t.title,
               'priority', t.priority,
               'due_date', t.due_date,
               'xp_reward', t.xp_reward,
               'overdue', coalesce(t.due_date < now(), false))
             order by t.due_date nulls last, t.created_at)
      from (
        select t.* from public.tasks t, day
        where t.user_id = auth.uid()
          and t.parent_task_id is null
          and t.status in ('pending', 'in_progress')
          and (t.due_date < day.end_at or t.priority = 'high')
        order by t.due_date nulls last, t.created_at
        limit 6
      ) t
    ), '[]'::jsonb),
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
revoke all on function public.home_dashboard(date, integer) from public, anon;
grant execute on function public.home_dashboard(date, integer) to authenticated;

commit;

-- ===== 039_task_steps.sql =====
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

-- ===== 040_focus_required.sql =====
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

-- ===== 041_home_extras.sql =====
-- Migración 041 · Tarjetas del Inicio de Main.dc.html (requiere 001–040).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- home_dashboard (038) devuelve además:
--   mentor_task  la última tarea abierta de un mentor (título, XP y mentor);
--   inbox_count  ideas sin ordenar en la Bandeja;
--   top_goal     la meta activa que vence antes (vida para el % de avance).
-- El resto de la función es la misma copia de 038.

begin;

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
    -- 038: lista «Hoy» del Inicio (plan S2). Vencen hoy, vencidas o de
    -- prioridad alta; la app quita la que ya muestra como Siguiente paso.
    'today_tasks', coalesce((
      select jsonb_agg(jsonb_build_object(
               'id', t.id,
               'title', t.title,
               'priority', t.priority,
               'due_date', t.due_date,
               'xp_reward', t.xp_reward,
               'overdue', coalesce(t.due_date < now(), false))
             order by t.due_date nulls last, t.created_at)
      from (
        select t.* from public.tasks t, day
        where t.user_id = auth.uid()
          and t.parent_task_id is null
          and t.status in ('pending', 'in_progress')
          and (t.due_date < day.end_at or t.priority = 'high')
        order by t.due_date nulls last, t.created_at
        limit 6
      ) t
    ), '[]'::jsonb),
    -- 041: tarjetas del Inicio de Main.dc.html (Mentores, Bandeja y Meta).
    'mentor_task', (
      select jsonb_build_object('id', t.id, 'title', t.title,
                                'xp_reward', t.xp_reward, 'mentor', n.name)
      from public.tasks t join public.npcs n on n.id = t.npc_id
      where t.user_id = auth.uid() and t.status in ('pending', 'in_progress')
      order by t.created_at desc
      limit 1
    ),
    'inbox_count', (
      select count(*) from public.brain_dump_entries
      where user_id = auth.uid() and status = 'pending'
    ),
    'top_goal', (
      select jsonb_build_object('id', g.id, 'title', g.title, 'due_date', g.due_date,
                                'hp', g.boss_current_hp, 'max_hp', g.boss_max_hp)
      from public.goals g
      where g.user_id = auth.uid() and g.status in ('not_started', 'in_progress')
        and g.archived_at is null
      order by g.due_date nulls last, g.created_at
      limit 1
    ),
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
revoke all on function public.home_dashboard(date, integer) from public, anon;
grant execute on function public.home_dashboard(date, integer) to authenticated;

commit;

-- ===== 042_habits_growth.sql =====
-- Migración 042 · Estadísticas de crecimiento de Hábitos (requiere 001–041).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- habits_overview (011) devuelve además, para Habitos.dc.html:
--   month_heat  {día: registros de hábitos buenos} del mes (mapa de calor);
--   month_done  registros de hábitos buenos del mes;
--   year_done   registros de hábitos buenos del año.
-- El resto de la función es la misma copia de 011.

begin;

create or replace function public.habits_overview(p_day date)
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  with week as (
    select generate_series(p_day - 6, p_day, interval '1 day')::date as day
  ),
  h as (
    select h.*,
           h.frequency = 'daily' or extract(dow from p_day)::int = any (h.specific_days) as scheduled_today
    from public.habits h
  ),
  -- Días de la semana en que tocaba cada hábito bueno (desde que existe).
  scheduled as (
    select h.id, w.day
    from h cross join week w
    where h.type = 'good' and w.day >= h.created_at::date
      and (h.frequency = 'daily' or extract(dow from w.day)::int = any (h.specific_days))
  )
  select jsonb_build_object(
    'habits', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', h.id,
        'name', h.name,
        'type', h.type,
        'frequency', h.frequency,
        'specific_days', coalesce(to_jsonb(h.specific_days), '[]'::jsonb),
        'skill_name', s.name,
        'hp_penalty', h.hp_penalty,
        'current_streak', coalesce(h.current_streak, 0),
        'best_streak', coalesce(h.best_streak, 0),
        'scheduled_today', h.scheduled_today,
        'done_today', exists (select 1 from public.habit_records r
                              where r.habit_id = h.id and r.completed_on = p_day),
        'today_count', (select count(*) from public.habit_records r
                        where r.habit_id = h.id and r.completed_on = p_day),
        'week', (select jsonb_agg(exists (select 1 from public.habit_records r
                                          where r.habit_id = h.id and r.completed_on = w.day)
                                  order by w.day)
                 from week w)
      ) order by h.type, h.created_at)
      from h left join public.skills s on s.id = h.skill_id
    ), '[]'::jsonb),
    'week_xp', (
      select coalesce(sum(q.xp_awarded), 0) from public.quest_log_entries q
      where q.source_type = 'habit' and q.occurred_at >= (p_day - 6)::timestamptz
    ),
    'week_done', (
      select count(*) from scheduled sc
      where exists (select 1 from public.habit_records r
                    where r.habit_id = sc.id and r.completed_on = sc.day)
    ),
    'week_scheduled', (select count(*) from scheduled),
    'bad_free_days', (
      select count(*) from week w
      where not exists (select 1 from public.habit_records r join h on h.id = r.habit_id
                        where h.type = 'bad' and r.completed_on = w.day)
    ),
    'month_days', coalesce((
      select jsonb_agg(distinct extract(day from r.completed_on)::int)
      from public.habit_records r join h on h.id = r.habit_id
      where h.type = 'good'
        and r.completed_on >= date_trunc('month', p_day)::date and r.completed_on <= p_day
    ), '[]'::jsonb),
    -- 042: Estadísticas de crecimiento y mapa de calor de Habitos.dc.html.
    'month_heat', coalesce((
      select jsonb_object_agg(d, n) from (
        select extract(day from r.completed_on)::int as d, count(*) as n
        from public.habit_records r join h on h.id = r.habit_id
        where h.type = 'good'
          and r.completed_on >= date_trunc('month', p_day)::date and r.completed_on <= p_day
        group by 1) x
    ), '{}'::jsonb),
    'month_done', (
      select count(*) from public.habit_records r join h on h.id = r.habit_id
      where h.type = 'good'
        and r.completed_on >= date_trunc('month', p_day)::date and r.completed_on <= p_day
    ),
    'year_done', (
      select count(*) from public.habit_records r join h on h.id = r.habit_id
      where h.type = 'good'
        and r.completed_on >= date_trunc('year', p_day)::date and r.completed_on <= p_day
    ),
    'skills', coalesce((
      select jsonb_agg(jsonb_build_object('id', id, 'name', name) order by created_at)
      from public.skills
    ), '[]'::jsonb)
  )
$$;
revoke all on function public.habits_overview(date) from public, anon;
grant execute on function public.habits_overview(date) to authenticated;

commit;

-- ===== 043_settings_digest.sql =====
-- Migración 043 · Resumen diario en Ajustes (requiere 001–042).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- settings_overview (016) devuelve además digest_time (HH:MI), la hora del
-- resumen de avisos informativos que entrega device_notifications (036). El
-- usuario ya podía escribirla (grant de 007). Resto: misma copia de 016.

begin;

create or replace function public.settings_overview()
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  select jsonb_build_object(
    'level', s.level,
    'current_xp', s.current_xp,
    'xp_to_next_level', s.xp_to_next_level,
    'difficulty', g.difficulty,
    'notification_daily_limit', g.notification_daily_limit,
    'silence_window_start', to_char(g.silence_window_start, 'HH24:MI'),
    -- 043: hora del resumen diario (null = la de notify_digest_hour).
    'digest_time', to_char(g.digest_time, 'HH24:MI'),
    'silence_window_end', to_char(g.silence_window_end, 'HH24:MI'),
    'critical_bypass_silence', g.critical_bypass_silence,
    'short_break_minutes', g.short_break_minutes,
    'long_break_minutes', g.long_break_minutes,
    'long_break_every_n_cycles', g.long_break_every_n_cycles,
    'difficulties', (
      select coalesce(jsonb_agg(jsonb_build_object(
        'level', dl.level,
        'xp_multiplier', dl.xp_multiplier,
        'hp_penalty_multiplier', dl.hp_penalty_multiplier,
        'coin_multiplier', dl.coin_multiplier
      ) order by dl.level), '[]'::jsonb)
      from public.difficulty_levels dl
    )
  )
  from public.profiles p
  left join public.character_stats s on s.user_id = p.id
  left join public.game_master_settings g on g.user_id = p.id
  where p.id = auth.uid()
$$;
revoke all on function public.settings_overview() from public, anon;
grant execute on function public.settings_overview() to authenticated;

commit;

-- ===== 044_guided_step_order_and_assignment.sql =====
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

-- ===== 045_more_reminders.sql =====
-- Migración 045 · Más recordatorios en el teléfono (requiere 036).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- _generate_notifications suma dos avisos críticos (salen arriba con sonido):
--   ▲ hábitos de hoy pendientes que aún no tienen racha (uno que los agrupa,
--     desde notify_streak_hour como los de racha);
--   ▲ tareas vencidas sin terminar (uno por día).
-- El resto de la función es igual a la de 036.

begin;

create or replace function public._generate_notifications(p_uid uuid, p_day date)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_reduced text[];
begin
  select coalesce(array_agg(category), '{}') into v_reduced
  from public.notification_category_state where user_id = p_uid and reduced;

  insert into public.notifications (user_id, type, category, event_key, title, message,
                                    related_entity_type, related_entity_id, sent_at)
  select p_uid, x.type::public.notification_type, x.category, x.key, x.title, x.message,
         x.entity_type, x.entity_id, now()
  from (
    -- ▲ Racha en riesgo (tono de invitación, nunca de amenaza).
    select 'critical' type, 'streak' category,
           'streak:' || h.id || ':' || p_day key,
           'Tu racha te está esperando 🔥' title,
           'Llevas ' || h.current_streak || ' días con «' || h.name || '». Hoy puedes sumar uno más.' message,
           'habit' entity_type, h.id entity_id
    from public.habits h
    where h.user_id = p_uid and h.type = 'good' and coalesce(h.current_streak, 0) > 0
      and (h.frequency = 'daily' or extract(dow from p_day)::int = any (h.specific_days))
      and not exists (select 1 from public.habit_records r
                      where r.habit_id = h.id and r.completed_on = p_day)
    union all
    -- ▲ Proyecto en 🔴.
    select 'critical', 'project', 'project:' || p.id || ':' || p_day,
           'Un proyecto necesita tu atención',
           '«' || p.title || '» va con el tiempo justo. Una misión hoy lo pone al día.',
           'project', p.id
    from public.projects p
    cross join lateral (
      select count(*)::int total, count(*) filter (where t.status = 'completed')::int done
      from public.tasks t where t.project_id = p.id and t.parent_task_id is null) c
    where p.user_id = p_uid and p.archived_at is null and p.status in ('not_started', 'in_progress')
      and public._project_urgency(c.total, c.done, coalesce(p.start_date, p.created_at::date),
                                  p.end_date, p_day) = 'high'
    union all
    -- ● Cerca de subir de nivel.
    select 'motivational', 'level', 'level:' || p_uid || ':' || s.level,
           'Estás a un paso del nivel ' || (s.level + 1),
           'Te faltan ' || (s.xp_to_next_level - s.current_xp) || ' XP. Una misión más y lo logras.',
           null, null
    from public.character_stats s
    where s.user_id = p_uid and s.current_xp >= s.xp_to_next_level * 0.9
      and not ('level' = any (v_reduced))
    union all
    -- ● Cofre del día listo (misma regla que claim_daily_chest).
    select 'motivational', 'chest', 'chest:' || p_uid || ':' || p_day,
           'Tu cofre del día está listo',
           'Cumpliste tus misiones de hoy. Ábrelo en el Inicio.',
           null, null
    where (select count(*) from public.quest_log_entries
           where user_id = p_uid and source_type::text in ('task', 'npc') and result = 'completed'
             and coin_awarded > 0 and occurred_at >= current_date and occurred_at < current_date + 1)
          >= public.rule('daily_chest_min_missions')
      and not exists (select 1 from public.quest_log_entries
                      where user_id = p_uid and source_type::text = 'daily_chest'
                        and occurred_at >= current_date and occurred_at < current_date + 1)
      and not ('chest' = any (v_reduced))
    union all
    -- ▲ Hábitos de hoy sin hacer y aún sin racha: un solo aviso que los junta
    --   (los que tienen racha ya avisan arriba). Categoría streak: misma hora.
    select 'critical', 'streak', 'habits_pending:' || p_uid || ':' || p_day,
           'Tienes hábitos pendientes hoy',
           case when count(*) = 1 then 'Te falta «' || min(h.name) || '». Un paso pequeño también cuenta.'
                else 'Te faltan ' || count(*) || ' hábitos: ' || string_agg(h.name, ', ' order by h.name) || '.' end,
           null, null
    from public.habits h
    where h.user_id = p_uid and h.type = 'good' and coalesce(h.current_streak, 0) = 0
      and (h.frequency = 'daily' or extract(dow from p_day)::int = any (h.specific_days))
      and not exists (select 1 from public.habit_records r
                      where r.habit_id = h.id and r.completed_on = p_day)
    having count(*) > 0
    union all
    -- ▲ Tareas vencidas que siguen abiertas.
    select 'critical', 'overdue', 'overdue:' || p_uid || ':' || p_day,
           'Tienes tareas pendientes',
           case when n = 1 then '1 tarea ya pasó su fecha. Retómala cuando puedas.'
                else n || ' tareas ya pasaron su fecha. Elige una y empieza por ahí.' end,
           null, null
    from (select count(*) n from public.tasks
          where user_id = p_uid and parent_task_id is null
            and status in ('pending', 'in_progress')
            and due_date < p_day::timestamptz) o
    where n > 0
    union all
    -- ○ Lo que vence hoy.
    select 'informational', 'due', 'due:' || p_uid || ':' || p_day,
           'Tu día de hoy',
           case when n = 1 then 'Hoy vence 1 misión. Tú decides cuándo.'
                else 'Hoy vencen ' || n || ' misiones. Tú decides el orden.' end,
           null, null
    from (select count(*) n from public.tasks
          where user_id = p_uid and parent_task_id is null
            and status in ('pending', 'in_progress')
            and due_date >= p_day::timestamptz and due_date < (p_day + 1)::timestamptz) d
    where n > 0 and not ('due' = any (v_reduced))
  ) x
  on conflict (user_id, event_key) where event_key is not null do nothing;
end $$;

commit;

-- ===== 046_documents.sql =====
-- Migración 046 · Taller de documentos (requiere 001–045).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- Documentos que el usuario redacta en la app (RF-117…RF-122, specs/006):
--   · El contenido es Markdown. El móvil guarda primero en el dispositivo y
--     sincroniza aquí: el id lo genera el cliente y gana el updated_at más nuevo.
--   · Borrar deja deleted_at (una marca) para que el borrado llegue a los demás
--     dispositivos; nunca se borra la fila desde el cliente.
--   · task_id vincula el documento a una tarea (ON DELETE SET NULL).
-- No toca la economía: el cliente escribe directo en la tabla, protegida por RLS.

begin;

create table if not exists public.documents (
  id uuid primary key,
  user_id uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  task_id uuid references public.tasks (id) on delete set null,
  title text not null default 'Sin título',
  content text not null default '',
  template text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  constraint documents_title_length check (char_length(title) between 1 and 120),
  -- ~1 MB de texto: de sobra para un trabajo, y evita filas enormes.
  constraint documents_content_length check (char_length(content) <= 1000000)
);

create index if not exists documents_user_updated_idx
  on public.documents (user_id, updated_at desc);

alter table public.documents enable row level security;

drop policy if exists "documents: leer lo propio" on public.documents;
create policy "documents: leer lo propio" on public.documents
  for select to authenticated using (user_id = auth.uid());

drop policy if exists "documents: crear lo propio" on public.documents;
create policy "documents: crear lo propio" on public.documents
  for insert to authenticated with check (user_id = auth.uid());

drop policy if exists "documents: editar lo propio" on public.documents;
create policy "documents: editar lo propio" on public.documents
  for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Sin política de DELETE: el borrado es la marca deleted_at.
revoke delete on public.documents from authenticated, anon;
grant select, insert, update on public.documents to authenticated;

commit;

-- ===== 047_document_images.sql =====
-- Migración 047 · Imágenes de los documentos del Taller (requiere 046).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- Bucket privado `documents` (máx. 10 MB por imagen). Ruta de cada archivo:
--   <user_id>/<document_id>/<archivo>
-- Cada usuario solo lee, sube, reemplaza y borra dentro de su carpeta. El
-- documento guarda la imagen como ![texto](img/<archivo>); el móvil la busca
-- primero en el teléfono y, si falta, la descarga de aquí.

begin;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('documents', 'documents', false, 10485760,
        array['image/jpeg', 'image/png', 'image/webp', 'image/gif'])
on conflict (id) do update
  set public = false,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "documents: leer lo propio" on storage.objects;
create policy "documents: leer lo propio" on storage.objects
  for select to authenticated
  using (bucket_id = 'documents' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "documents: subir a lo propio" on storage.objects;
create policy "documents: subir a lo propio" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'documents' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "documents: reemplazar lo propio" on storage.objects;
create policy "documents: reemplazar lo propio" on storage.objects
  for update to authenticated
  using (bucket_id = 'documents' and (storage.foldername(name))[1] = auth.uid()::text)
  with check (bucket_id = 'documents' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "documents: borrar lo propio" on storage.objects;
create policy "documents: borrar lo propio" on storage.objects
  for delete to authenticated
  using (bucket_id = 'documents' and (storage.foldername(name))[1] = auth.uid()::text);

commit;

-- ===== 048_daily_reminders.sql =====
-- Migración 048 · Recordatorios del día, estilo Duolingo (requiere 036 y 043).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- Hasta cinco recordatorios al día (09:00, 13:00, 16:00, 19:30 y 21:30), solo si
-- hay hábitos de hoy, tareas que vencen hoy o vencidas, o proyectos en 🔴. El de
-- la noche defiende la racha; el de las 21:30 solo llega si hay una racha y hoy
-- todavía no se hizo ningún hábito. Tono de invitación, nunca de amenaza.
--   · Llegan como críticos (salen arriba con sonido) y respetan la ventana de
--     silencio salvo critical_bypass_silence.
--   · Solo el último momento que pasó (hace < 2 h) genera aviso: si el móvil
--     estuvo apagado no llegan todos juntos. Si llegó otro aviso hace < 90 min,
--     ese momento se salta.
--   · game_master_settings.daily_reminders los apaga (Configuración → Avisos).

begin;

-- 1. Interruptor -------------------------------------------------------------
alter table public.game_master_settings
  add column if not exists daily_reminders boolean not null default true;
grant update (daily_reminders) on public.game_master_settings to authenticated;

-- 2. Recordatorios del día ---------------------------------------------------
-- Cinco momentos. Solo el último que ya pasó (y hace menos de 2 h) cuenta: si el
-- móvil estuvo apagado no llegan todos juntos. Uno por momento y día (event_key).
create or replace function public._generate_reminders(p_uid uuid, p_day date, p_time time)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_slot text;
  v_habits int;
  v_tasks int;
  v_projects int;
  v_streak int;
  v_done_today boolean;
  v_pick int;
  v_title text;
  v_message text;
  v_todo text;
  v_quedan text;
begin
  if not coalesce((select daily_reminders from public.game_master_settings
                   where user_id = p_uid), true) then
    return;
  end if;

  select s.slot into v_slot
  from (values ('morning', time '09:00'), ('midday', time '13:00'),
               ('afternoon', time '16:00'), ('evening', time '19:30'),
               ('last_call', time '21:30')) s(slot, at)
  where s.at <= p_time and p_time < s.at + interval '2 hours'
  order by s.at desc limit 1;
  if v_slot is null then
    return;
  end if;

  -- Si hace poco llegó otro aviso, este momento se salta.
  if exists (select 1 from public.notifications
             where user_id = p_uid and delivered_at > now() - interval '90 minutes') then
    return;
  end if;

  -- Hábitos buenos de hoy sin hacer.
  select count(*)::int into v_habits
  from public.habits h
  where h.user_id = p_uid and h.type = 'good'
    and (h.frequency = 'daily' or extract(dow from p_day)::int = any (h.specific_days))
    and not exists (select 1 from public.habit_records r
                    where r.habit_id = h.id and r.completed_on = p_day);
  -- La racha que se defiende es la más larga de los hábitos buenos.
  select coalesce(max(h.current_streak), 0)::int into v_streak
  from public.habits h where h.user_id = p_uid and h.type = 'good';

  -- Tareas que vencen hoy o ya vencieron.
  select count(*)::int into v_tasks
  from public.tasks
  where user_id = p_uid and parent_task_id is null
    and status in ('pending', 'in_progress')
    and due_date < (p_day + 1)::timestamptz;

  -- Proyectos en 🔴.
  select count(*)::int into v_projects
  from public.projects p
  cross join lateral (
    select count(*)::int total, count(*) filter (where t.status = 'completed')::int done
    from public.tasks t where t.project_id = p.id and t.parent_task_id is null) c
  where p.user_id = p_uid and p.archived_at is null and p.status in ('not_started', 'in_progress')
    and public._project_urgency(c.total, c.done, coalesce(p.start_date, p.created_at::date),
                                p.end_date, p_day) = 'high';

  if v_habits + v_tasks + v_projects = 0 then
    return; -- nada pendiente: no se molesta
  end if;

  v_done_today := exists (select 1 from public.habit_records r
                          join public.habits h on h.id = r.habit_id
                          where h.user_id = p_uid and r.completed_on = p_day);

  -- Resumen de lo pendiente: «2 hábitos y 1 tarea».
  v_todo := array_to_string(array_remove(array[
    case when v_habits = 1 then '1 hábito' when v_habits > 1 then v_habits || ' hábitos' end,
    case when v_tasks = 1 then '1 tarea' when v_tasks > 1 then v_tasks || ' tareas' end,
    case when v_projects = 1 then '1 proyecto urgente'
         when v_projects > 1 then v_projects || ' proyectos urgentes' end
  ], null), ' y ');

  v_quedan := case when v_habits + v_tasks + v_projects = 1 then 'Te queda ' else 'Te quedan ' end;

  -- El texto cambia cada día para no repetirse.
  v_pick := extract(doy from p_day)::int % 3 + 1;

  if v_slot = 'morning' then
    v_title := (array['Buenos días ☀️', 'Tu aventura de hoy empieza ya 🗺️',
                      'Un nuevo día, una nueva misión ⚔️'])[v_pick];
    v_message := 'Hoy tienes ' || v_todo || '. Empieza por lo más pequeño.';
  elsif v_slot = 'midday' then
    v_title := (array['¿Un momento para avanzar? ⏱️', 'Pausa productiva 🌱',
                      'Mitad del día, buen momento 💡'])[v_pick];
    v_message := v_quedan || v_todo || '. Cinco minutos ya cuentan.';
  elsif v_slot = 'afternoon' then
    v_title := (array['Aún estás a tiempo 💪', 'Tu yo del futuro te lo agradecerá ✨',
                      'Un paso más hoy 🚶'])[v_pick];
    v_message := 'Pendiente: ' || v_todo || '. ¿Empiezas con uno?';
  elsif v_slot = 'evening' then
    -- El aviso de racha de 036 (desde notify_streak_hour) ya salió hoy o sale
    -- en esta misma revisión: no repetir.
    if exists (select 1 from public.notifications
               where user_id = p_uid and category = 'streak'
                 and (delivered_at >= p_day::timestamptz
                      or (delivered_at is null and read_at is null
                          and created_at >= now() - interval '24 hours'
                          and p_time >= make_time(public.rule('notify_streak_hour')::int, 0, 0)))) then
      return;
    end if;
    if v_streak > 0 and v_habits > 0 and not v_done_today then
      v_title := 'Tu racha de ' || v_streak || ' días te espera 🔥';
      v_message := 'Un hábito hoy y la mantienes. Te faltan ' || v_todo || '.';
    else
      v_title := (array['Cierra el día con una victoria 🏁', 'Último empujón del día 🌙',
                        'Termina con algo hecho ✅'])[v_pick];
      v_message := v_quedan || v_todo || '.';
    end if;
  else -- last_call: solo si hay una racha que mantener y hoy no se hizo nada
    if v_streak = 0 or v_habits = 0 or v_done_today then
      return;
    end if;
    v_title := 'Última oportunidad para tu racha 🔥';
    v_message := 'Llevas ' || v_streak || ' días. Un hábito rápido antes de dormir y sigue viva.';
  end if;

  insert into public.notifications (user_id, type, category, event_key, title, message, sent_at)
  values (p_uid, 'critical', 'reminder', 'reminder:' || p_uid || ':' || p_day || ':' || v_slot,
          v_title, v_message, now())
  on conflict (user_id, event_key) where event_key is not null do nothing;
end $$;

-- 3. Entrega: igual que 036 + los recordatorios ------------------------------
create or replace function public.device_notifications(p_token text, p_day date, p_time time)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
  v_now timestamptz := now();
  g public.game_master_settings;
  v_silent boolean;
  v_quiet boolean;
  v_left integer;
  v_count integer;
  v_items jsonb;
  v_digest jsonb;
begin
  update public.device_registrations set last_seen_at = v_now
  where token_hash = sha256(convert_to(coalesce(p_token, ''), 'UTF8'))
  returning user_id into v_uid;
  if v_uid is null then
    raise exception 'device_not_registered' using errcode = '28000';
  end if;

  -- Frecuencia decreciente: lo entregado y no leído a tiempo cuenta como ignorado.
  update public.notifications set ignored = true
  where user_id = v_uid and type <> 'critical' and not ignored and read_at is null
    and delivered_at < v_now - make_interval(hours => public.rule('notify_ignored_after_hours')::int);

  perform public._generate_notifications(v_uid, p_day);
  -- 048: recordatorios del día a distintas horas.
  perform public._generate_reminders(v_uid, p_day, p_time);

  select * into g from public.game_master_settings where user_id = v_uid;
  v_silent := coalesce(case
    when g.silence_window_start <= g.silence_window_end
      then p_time >= g.silence_window_start and p_time < g.silence_window_end
    else p_time >= g.silence_window_start or p_time < g.silence_window_end end, false);
  v_quiet := v_silent or exists (select 1 from public.focus_sessions
                                 where user_id = v_uid and status in ('active', 'paused'));
  -- Entregas no críticas desde la medianoche local (un digest cuenta 1).
  select coalesce(g.notification_daily_limit - (
           count(*) filter (where digest_slot is null)
           + count(distinct delivered_at) filter (where digest_slot is not null))::int,
         2147483647)
  into v_left
  from public.notifications
  where user_id = v_uid and type <> 'critical'
    and delivered_at >= v_now - (p_time - time '00:00');

  -- ▲ Críticos.
  with sent as (
    update public.notifications n set delivered_at = v_now
    where n.user_id = v_uid and n.delivered_at is null and n.read_at is null
      and n.created_at >= v_now - interval '24 hours' and n.type = 'critical'
      and (not v_silent or coalesce(g.critical_bypass_silence, false))
      and (n.category is distinct from 'streak'
           or p_time >= make_time(public.rule('notify_streak_hour')::int, 0, 0))
    returning n.id, n.type, n.title, n.message, n.created_at)
  select coalesce(jsonb_agg(jsonb_build_object('id', id, 'type', type, 'title', title,
           'message', message, 'created_at', created_at) order by created_at), '[]'::jsonb)
  into v_items from sent;

  -- ● Motivacionales, hasta el límite del día.
  if not v_quiet and v_left > 0 then
    with sent as (
      update public.notifications n set delivered_at = v_now
      where n.id in (select id from public.notifications
                     where user_id = v_uid and delivered_at is null and read_at is null
                       and created_at >= v_now - interval '24 hours' and type = 'motivational'
                     order by created_at limit v_left)
      returning n.id, n.type, n.title, n.message, n.created_at)
    select v_items || coalesce(jsonb_agg(jsonb_build_object('id', id, 'type', type,
             'title', title, 'message', message, 'created_at', created_at)
             order by created_at), '[]'::jsonb), count(*)
    into v_items, v_count from sent;
    v_left := v_left - v_count;
  end if;

  -- ○ Informativos, juntos en un digest.
  if not v_quiet and v_left > 0
     and p_time >= coalesce(g.digest_time, make_time(public.rule('notify_digest_hour')::int, 0, 0)) then
    with sent as (
      update public.notifications n set delivered_at = v_now,
        digest_slot = case when p_time < time '14:00' then 'morning' else 'evening' end::public.digest_slot
      where n.user_id = v_uid and n.delivered_at is null and n.read_at is null
        and n.created_at >= v_now - interval '24 hours' and n.type = 'informational'
      returning n.id, n.title, n.message, n.created_at)
    select case
      when count(*) = 1 then jsonb_build_object('id', min(id::text), 'type', 'informational',
        'title', min(title), 'message', min(message), 'created_at', min(created_at))
      when count(*) > 1 then jsonb_build_object('id', min(id::text), 'type', 'informational',
        'title', 'Tu resumen del día',
        'message', 'Tienes ' || count(*) || ' avisos: ' || string_agg(title, ' · ' order by created_at) || '.',
        'created_at', min(created_at))
      end
    into v_digest from sent;
    if v_digest is not null then
      v_items := v_items || jsonb_build_array(v_digest);
    end if;
  end if;

  return jsonb_build_object('items', v_items);
end $$;

-- 4. Configuración devuelve el interruptor -----------------------------------
create or replace function public.settings_overview()
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  select jsonb_build_object(
    'level', s.level,
    'current_xp', s.current_xp,
    'xp_to_next_level', s.xp_to_next_level,
    'difficulty', g.difficulty,
    'notification_daily_limit', g.notification_daily_limit,
    'silence_window_start', to_char(g.silence_window_start, 'HH24:MI'),
    -- 043: hora del resumen diario (null = la de notify_digest_hour).
    'digest_time', to_char(g.digest_time, 'HH24:MI'),
    'silence_window_end', to_char(g.silence_window_end, 'HH24:MI'),
    'critical_bypass_silence', g.critical_bypass_silence,
    -- 048: recordatorios del día (estilo Duolingo).
    'daily_reminders', coalesce(g.daily_reminders, true),
    'short_break_minutes', g.short_break_minutes,
    'long_break_minutes', g.long_break_minutes,
    'long_break_every_n_cycles', g.long_break_every_n_cycles,
    'difficulties', (
      select coalesce(jsonb_agg(jsonb_build_object(
        'level', dl.level,
        'xp_multiplier', dl.xp_multiplier,
        'hp_penalty_multiplier', dl.hp_penalty_multiplier,
        'coin_multiplier', dl.coin_multiplier
      ) order by dl.level), '[]'::jsonb)
      from public.difficulty_levels dl
    )
  )
  from public.profiles p
  left join public.character_stats s on s.user_id = p.id
  left join public.game_master_settings g on g.user_id = p.id
  where p.id = auth.uid()
$$;
revoke all on function public.settings_overview() from public, anon;
grant execute on function public.settings_overview() to authenticated;
revoke all on function public._generate_reminders(uuid, date, time) from public, anon, authenticated;

commit;

-- ===== 049_local_timezone.sql =====
-- Migración 049 · Hora de Colombia en el job diario y en los avisos (requiere 007,
-- 036 y 048). Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- Supabase trabaja en UTC: medianoche UTC son las 19:00 en Colombia. Por eso:
--   · daily_maintenance corría a las 19:05 (hora local): rompía la racha de quien
--     hacía su hábito de noche y contaba el «día» de 19:00 a 19:00.
--   · «Vence hoy» se calculaba hasta las 19:00 locales: una tarea de hoy 23:59 no
--     contaba para los avisos ni los recordatorios.
-- Ahora esas funciones calculan los días en America/Bogota (sin horario de
-- verano, UTC−5) y el job corre a las 00:05 hora local (05:05 UTC).
-- shortcut: zona fija para la app de un solo país; si llega a otros, guardar la
-- zona en profiles y usarla por usuario.

begin;

alter function public.daily_maintenance(date) set timezone to 'America/Bogota';
alter function public._generate_notifications(uuid, date) set timezone to 'America/Bogota';
alter function public._generate_reminders(uuid, date, time) set timezone to 'America/Bogota';
alter function public.device_notifications(text, date, time) set timezone to 'America/Bogota';
alter function public.notifications_overview(date) set timezone to 'America/Bogota';

-- 00:05 en Colombia. El día por defecto (current_date − 1) se calcula al llamar,
-- en UTC: a las 05:05 UTC la fecha UTC ya es la local, así que procesa ayer.
do $$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    perform cron.unschedule(jobid) from cron.job where jobname = 'lifequest_daily';
    perform cron.schedule('lifequest_daily', '5 5 * * *', 'select public.daily_maintenance()');
  else
    raise notice 'pg_cron no está activo: actívalo en Database → Extensions y vuelve a ejecutar esta migración.';
  end if;
end $$;

commit;

-- ===== 050_push_fcm.sql =====
-- Migración 050 · Notificaciones push con Firebase (FCM) (requiere 036, 048 y 049).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- Supabase decide qué aviso toca y cuándo (mismas reglas de 036/048); FCM solo
-- lo entrega al teléfono al instante, aunque la app esté cerrada.
--   1. device_registrations.fcm_token: el token FCM de cada teléfono.
--   2. set_push_token(código, token): el teléfono guarda su token FCM.
--   3. _deliver_notifications(uid, día, hora): la entrega de device_notifications,
--      ahora reutilizable. device_notifications (revisión del teléfono cada
--      ~15 min) la sigue usando: queda de respaldo y nunca duplica, porque los
--      dos caminos marcan delivered_at.
--   4. push_dispatch(): para cada usuario con token FCM, entrega lo que toca a
--      la hora de Colombia. Solo service_role (la Edge Function push-dispatch).
--   5. clear_push_token(token): FCM avisa que el token ya no existe.
--   6. pg_cron + pg_net llaman a push-dispatch cada 5 min. La URL del proyecto
--      y la clave del cron se leen del Vault (ver docs al final).

begin;

-- 1. Token FCM ----------------------------------------------------------------
alter table public.device_registrations add column if not exists fcm_token text;
create unique index if not exists device_registrations_fcm_token_idx
  on public.device_registrations (fcm_token) where fcm_token is not null;

-- 2. El teléfono registra su token FCM --------------------------------------
create or replace function public.set_push_token(p_token text, p_fcm_token text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_fcm_token is null or length(p_fcm_token) not between 20 and 4096 then
    raise exception 'invalid_push_token' using errcode = '22023';
  end if;
  -- Un token FCM pertenece a un solo teléfono: si cambió de cuenta, se mueve.
  update public.device_registrations set fcm_token = null
  where fcm_token = p_fcm_token
    and token_hash <> sha256(convert_to(coalesce(p_token, ''), 'UTF8'));
  update public.device_registrations set fcm_token = p_fcm_token, last_seen_at = now()
  where token_hash = sha256(convert_to(coalesce(p_token, ''), 'UTF8'));
  if not found then
    raise exception 'device_not_registered' using errcode = '28000';
  end if;
end $$;

-- 3. Entrega reutilizable -----------------------------------------------------
create or replace function public._deliver_notifications(p_uid uuid, p_day date, p_time time)
returns jsonb
language plpgsql
security definer
set search_path = ''
set timezone to 'America/Bogota'
as $$
declare
  v_uid uuid := p_uid;
  v_now timestamptz := now();
  g public.game_master_settings;
  v_silent boolean;
  v_quiet boolean;
  v_left integer;
  v_count integer;
  v_items jsonb;
  v_digest jsonb;
begin
  -- Frecuencia decreciente: lo entregado y no leído a tiempo cuenta como ignorado.
  update public.notifications set ignored = true
  where user_id = v_uid and type <> 'critical' and not ignored and read_at is null
    and delivered_at < v_now - make_interval(hours => public.rule('notify_ignored_after_hours')::int);

  perform public._generate_notifications(v_uid, p_day);
  -- 048: recordatorios del día a distintas horas.
  perform public._generate_reminders(v_uid, p_day, p_time);

  select * into g from public.game_master_settings where user_id = v_uid;
  v_silent := coalesce(case
    when g.silence_window_start <= g.silence_window_end
      then p_time >= g.silence_window_start and p_time < g.silence_window_end
    else p_time >= g.silence_window_start or p_time < g.silence_window_end end, false);
  v_quiet := v_silent or exists (select 1 from public.focus_sessions
                                 where user_id = v_uid and status in ('active', 'paused'));
  -- Entregas no críticas desde la medianoche local (un digest cuenta 1).
  select coalesce(g.notification_daily_limit - (
           count(*) filter (where digest_slot is null)
           + count(distinct delivered_at) filter (where digest_slot is not null))::int,
         2147483647)
  into v_left
  from public.notifications
  where user_id = v_uid and type <> 'critical'
    and delivered_at >= v_now - (p_time - time '00:00');

  -- ▲ Críticos.
  with sent as (
    update public.notifications n set delivered_at = v_now
    where n.user_id = v_uid and n.delivered_at is null and n.read_at is null
      and n.created_at >= v_now - interval '24 hours' and n.type = 'critical'
      and (not v_silent or coalesce(g.critical_bypass_silence, false))
      and (n.category is distinct from 'streak'
           or p_time >= make_time(public.rule('notify_streak_hour')::int, 0, 0))
    returning n.id, n.type, n.title, n.message, n.created_at)
  select coalesce(jsonb_agg(jsonb_build_object('id', id, 'type', type, 'title', title,
           'message', message, 'created_at', created_at) order by created_at), '[]'::jsonb)
  into v_items from sent;

  -- ● Motivacionales, hasta el límite del día.
  if not v_quiet and v_left > 0 then
    with sent as (
      update public.notifications n set delivered_at = v_now
      where n.id in (select id from public.notifications
                     where user_id = v_uid and delivered_at is null and read_at is null
                       and created_at >= v_now - interval '24 hours' and type = 'motivational'
                     order by created_at limit v_left)
      returning n.id, n.type, n.title, n.message, n.created_at)
    select v_items || coalesce(jsonb_agg(jsonb_build_object('id', id, 'type', type,
             'title', title, 'message', message, 'created_at', created_at)
             order by created_at), '[]'::jsonb), count(*)
    into v_items, v_count from sent;
    v_left := v_left - v_count;
  end if;

  -- ○ Informativos, juntos en un digest.
  if not v_quiet and v_left > 0
     and p_time >= coalesce(g.digest_time, make_time(public.rule('notify_digest_hour')::int, 0, 0)) then
    with sent as (
      update public.notifications n set delivered_at = v_now,
        digest_slot = case when p_time < time '14:00' then 'morning' else 'evening' end::public.digest_slot
      where n.user_id = v_uid and n.delivered_at is null and n.read_at is null
        and n.created_at >= v_now - interval '24 hours' and n.type = 'informational'
      returning n.id, n.title, n.message, n.created_at)
    select case
      when count(*) = 1 then jsonb_build_object('id', min(id::text), 'type', 'informational',
        'title', min(title), 'message', min(message), 'created_at', min(created_at))
      when count(*) > 1 then jsonb_build_object('id', min(id::text), 'type', 'informational',
        'title', 'Tu resumen del día',
        'message', 'Tienes ' || count(*) || ' avisos: ' || string_agg(title, ' · ' order by created_at) || '.',
        'created_at', min(created_at))
      end
    into v_digest from sent;
    if v_digest is not null then
      v_items := v_items || jsonb_build_array(v_digest);
    end if;
  end if;

  return jsonb_build_object('items', v_items);
end $$;

create or replace function public.device_notifications(p_token text, p_day date, p_time time)
returns jsonb
language plpgsql
security definer
set search_path = ''
set timezone to 'America/Bogota'
as $$
declare
  v_uid uuid;
begin
  update public.device_registrations set last_seen_at = now()
  where token_hash = sha256(convert_to(coalesce(p_token, ''), 'UTF8'))
  returning user_id into v_uid;
  if v_uid is null then
    raise exception 'device_not_registered' using errcode = '28000';
  end if;
  return public._deliver_notifications(v_uid, p_day, p_time);
end $$;

-- 4. Envío push -----------------------------------------------------------------
-- [{ "tokens": [...], "items": [{id, type, title, message, created_at}] }]
create or replace function public.push_dispatch()
returns jsonb
language plpgsql
security definer
set search_path = ''
set timezone to 'America/Bogota'
as $$
declare
  v_local timestamp := now()::timestamp;  -- ya en hora de Colombia
  v_user record;
  v_items jsonb;
  v_out jsonb := '[]'::jsonb;
begin
  for v_user in
    select user_id, array_agg(fcm_token) tokens
    from public.device_registrations
    where fcm_token is not null
    group by user_id
  loop
    v_items := public._deliver_notifications(
      v_user.user_id, v_local::date, v_local::time) -> 'items';
    if jsonb_array_length(coalesce(v_items, '[]'::jsonb)) > 0 then
      v_out := v_out || jsonb_build_array(jsonb_build_object(
        'tokens', to_jsonb(v_user.tokens), 'items', v_items));
    end if;
  end loop;
  return v_out;
end $$;

-- 5. Token que FCM ya no reconoce ---------------------------------------------
create or replace function public.clear_push_token(p_fcm_token text)
returns void
language sql
security definer
set search_path = ''
as $$
  update public.device_registrations set fcm_token = null where fcm_token = p_fcm_token
$$;

revoke all on function public._deliver_notifications(uuid, date, time) from public, anon, authenticated;
revoke all on function public.push_dispatch() from public, anon, authenticated;
revoke all on function public.clear_push_token(text) from public, anon, authenticated;
grant execute on function public.push_dispatch() to service_role;
grant execute on function public.clear_push_token(text) to service_role;
revoke all on function public.set_push_token(text, text) from public;
grant execute on function public.set_push_token(text, text) to anon, authenticated;
grant execute on function public.device_notifications(text, date, time) to anon, authenticated;

-- 6. Cron cada 5 minutos --------------------------------------------------------
-- Necesita pg_cron, pg_net y dos secretos en el Vault (Project Settings → Vault):
--   lifequest_project_url = https://<proyecto>.supabase.co
--   lifequest_push_secret = el mismo valor del secret PUSH_CRON_SECRET de la función
do $$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron')
     and exists (select 1 from pg_extension where extname = 'pg_net') then
    perform cron.unschedule(jobid) from cron.job where jobname = 'lifequest_push';
    perform cron.schedule('lifequest_push', '*/5 * * * *', $job$
      select net.http_post(
        url := (select decrypted_secret from vault.decrypted_secrets
                where name = 'lifequest_project_url') || '/functions/v1/push-dispatch',
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'x-push-secret', (select decrypted_secret from vault.decrypted_secrets
                            where name = 'lifequest_push_secret')),
        body := '{}'::jsonb)
    $job$);
  else
    raise notice 'Activa pg_cron y pg_net (Database → Extensions) y vuelve a ejecutar esta migración.';
  end if;
end $$;

commit;

-- ===== 051_habit_priority.sql =====
-- Migración 051 · Prioridad de hábitos y Camino (requiere 011, 003 y 042).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
--   1. habits.priority: urgency_level, la única escala de la app (§6), por
--      defecto 'medium'.
--   2. create_habit(..., p_priority): guarda la prioridad al crear.
--   3. habits_overview: devuelve 'priority' de cada hábito. El resto es la
--      misma copia de 042. El Camino de la app ordena por prioridad.

begin;

alter table public.habits
  add column if not exists priority public.urgency_level not null default 'medium';

grant insert (priority), update (priority) on public.habits to authenticated;

-- 2. create_habit con prioridad -------------------------------------------------
drop function if exists public.create_habit(text, public.habit_type, public.habit_frequency, integer[], integer, uuid);

create or replace function public.create_habit(
  p_name text,
  p_type public.habit_type,
  p_frequency public.habit_frequency default 'daily',
  p_specific_days integer[] default null,
  p_hp_penalty integer default 0,
  p_skill_id uuid default null,
  p_priority public.urgency_level default 'medium'
)
returns uuid
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_name text := trim(coalesce(p_name, ''));
  v_days integer[];
  v_id uuid;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  if v_name = '' or length(v_name) > 100 then
    raise exception 'invalid_name' using errcode = '22023';
  end if;
  if p_type = 'bad' and coalesce(p_hp_penalty, 0) not in (3, 5, 8) then
    raise exception 'invalid_severity' using errcode = '22023';
  end if;
  if p_type = 'good' and p_frequency = 'specific_days' then
    select array_agg(distinct d order by d) into v_days
    from unnest(coalesce(p_specific_days, '{}')) d;
    if v_days is null or exists (select 1 from unnest(v_days) d where d not between 0 and 6) then
      raise exception 'invalid_days' using errcode = '22023';
    end if;
  end if;
  if p_skill_id is not null
     and not exists (select 1 from public.skills where id = p_skill_id and user_id = v_uid) then
    raise exception 'skill_not_found' using errcode = 'P0002';
  end if;

  insert into public.habits (user_id, skill_id, name, type, frequency, specific_days, hp_penalty, priority)
  values (v_uid, p_skill_id, v_name, p_type,
          case when v_days is null then 'daily'::public.habit_frequency else 'specific_days' end,
          v_days, case when p_type = 'bad' then p_hp_penalty else 0 end,
          coalesce(p_priority, 'medium'))
  returning id into v_id;
  return v_id;
end $$;
revoke all on function public.create_habit(text, public.habit_type, public.habit_frequency, integer[], integer, uuid, public.urgency_level) from public, anon;
grant execute on function public.create_habit(text, public.habit_type, public.habit_frequency, integer[], integer, uuid, public.urgency_level) to authenticated;

-- 3. habits_overview con prioridad ---------------------------------------------
create or replace function public.habits_overview(p_day date)
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  with week as (
    select generate_series(p_day - 6, p_day, interval '1 day')::date as day
  ),
  h as (
    select h.*,
           h.frequency = 'daily' or extract(dow from p_day)::int = any (h.specific_days) as scheduled_today
    from public.habits h
  ),
  -- Días de la semana en que tocaba cada hábito bueno (desde que existe).
  scheduled as (
    select h.id, w.day
    from h cross join week w
    where h.type = 'good' and w.day >= h.created_at::date
      and (h.frequency = 'daily' or extract(dow from w.day)::int = any (h.specific_days))
  )
  select jsonb_build_object(
    'habits', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', h.id,
        'name', h.name,
        'priority', h.priority,
        'type', h.type,
        'frequency', h.frequency,
        'specific_days', coalesce(to_jsonb(h.specific_days), '[]'::jsonb),
        'skill_name', s.name,
        'hp_penalty', h.hp_penalty,
        'current_streak', coalesce(h.current_streak, 0),
        'best_streak', coalesce(h.best_streak, 0),
        'scheduled_today', h.scheduled_today,
        'done_today', exists (select 1 from public.habit_records r
                              where r.habit_id = h.id and r.completed_on = p_day),
        'today_count', (select count(*) from public.habit_records r
                        where r.habit_id = h.id and r.completed_on = p_day),
        'week', (select jsonb_agg(exists (select 1 from public.habit_records r
                                          where r.habit_id = h.id and r.completed_on = w.day)
                                  order by w.day)
                 from week w)
      ) order by h.type, h.created_at)
      from h left join public.skills s on s.id = h.skill_id
    ), '[]'::jsonb),
    'week_xp', (
      select coalesce(sum(q.xp_awarded), 0) from public.quest_log_entries q
      where q.source_type = 'habit' and q.occurred_at >= (p_day - 6)::timestamptz
    ),
    'week_done', (
      select count(*) from scheduled sc
      where exists (select 1 from public.habit_records r
                    where r.habit_id = sc.id and r.completed_on = sc.day)
    ),
    'week_scheduled', (select count(*) from scheduled),
    'bad_free_days', (
      select count(*) from week w
      where not exists (select 1 from public.habit_records r join h on h.id = r.habit_id
                        where h.type = 'bad' and r.completed_on = w.day)
    ),
    'month_days', coalesce((
      select jsonb_agg(distinct extract(day from r.completed_on)::int)
      from public.habit_records r join h on h.id = r.habit_id
      where h.type = 'good'
        and r.completed_on >= date_trunc('month', p_day)::date and r.completed_on <= p_day
    ), '[]'::jsonb),
    -- 042: Estadísticas de crecimiento y mapa de calor de Habitos.dc.html.
    'month_heat', coalesce((
      select jsonb_object_agg(d, n) from (
        select extract(day from r.completed_on)::int as d, count(*) as n
        from public.habit_records r join h on h.id = r.habit_id
        where h.type = 'good'
          and r.completed_on >= date_trunc('month', p_day)::date and r.completed_on <= p_day
        group by 1) x
    ), '{}'::jsonb),
    'month_done', (
      select count(*) from public.habit_records r join h on h.id = r.habit_id
      where h.type = 'good'
        and r.completed_on >= date_trunc('month', p_day)::date and r.completed_on <= p_day
    ),
    'year_done', (
      select count(*) from public.habit_records r join h on h.id = r.habit_id
      where h.type = 'good'
        and r.completed_on >= date_trunc('year', p_day)::date and r.completed_on <= p_day
    ),
    'skills', coalesce((
      select jsonb_agg(jsonb_build_object('id', id, 'name', name) order by created_at)
      from public.skills
    ), '[]'::jsonb)
  )
$$;
revoke all on function public.habits_overview(date) from public, anon;
grant execute on function public.habits_overview(date) to authenticated;

commit;

-- ===== 052_challenges_league.sql =====
-- Migración 052 · Desafíos y Liga estilo Duolingo (requiere 004, 005, 008 y 012).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
--   1. Desafíos del día: 3 metas pequeñas (XP, tareas, ciclos de Mazmorra) que se
--      cobran por separado con claim_challenge(key). Cada cobro suma 1 punto al
--      Desafío del mes, que se cobra con claim_challenge('month').
--   2. Liga semanal: el usuario compite por XP de la semana (lunes a domingo)
--      contra 10 rivales SIMULADOS de su división. No hay otros usuarios en la
--      tabla (CLAUDE.md §1: sin ranking social). Top 3 sube, últimos 3 bajan.
--   3. challenges_overview(): todo lo anterior en una llamada.
--
-- Los días y semanas se cuentan en America/Bogota (igual que 049).
-- Valores de la economía: reglas provisionales en game_rules.

alter type public.quest_source add value if not exists 'challenge';

begin;

insert into public.game_rules (key, value, provisional, note) values
  ('challenge_xp_target',    30, true, 'Desafío del día: gana N XP'),
  ('challenge_tasks_target',  2, true, 'Desafío del día: completa N tareas'),
  ('challenge_focus_target',  1, true, 'Desafío del día: N ciclos en la Mazmorra'),
  ('challenge_coins',         5, true, 'Monedas por cada desafío del día'),
  ('challenge_month_target', 30, true, 'Desafíos del día cobrados para el del mes'),
  ('challenge_month_coins',  60, true, 'Monedas del Desafío del mes'),
  ('league_base_xp',         60, true, 'XP semanal típica de un rival en la división 0')
on conflict (key) do nothing;

-- División de cada semana. Solo la escriben las funciones (security definer).
create table if not exists public.league_weeks (
  user_id uuid not null references public.profiles(id) on delete cascade,
  week_start date not null,
  division smallint not null default 0 check (division between 0 and 9),
  -- Resultado de la semana anterior: promoted / demoted / stayed / null.
  last_result text,
  primary key (user_id, week_start)
);
alter table public.league_weeks enable row level security;
drop policy if exists "own rows" on public.league_weeks;
create policy "own rows" on public.league_weeks for select using (user_id = auth.uid());

-- Id estable de cada desafío dentro de quest_log_entries.source_id.
create or replace function public._challenge_id(p_key text)
returns uuid
language sql
immutable
set search_path = ''
as $$ select md5('lifequest-challenge:' || p_key)::uuid $$;

-- Progreso de hoy de un desafío del día (null si la clave no existe).
create or replace function public._challenge_progress(p_uid uuid, p_key text)
returns integer
language sql
stable
security definer
set search_path = ''
set timezone to 'America/Bogota'
as $$
  select case p_key
    when 'xp' then (
      select coalesce(sum(xp_awarded), 0)::integer from public.quest_log_entries
      where user_id = p_uid and occurred_at >= current_date and occurred_at < current_date + 1)
    when 'tasks' then (
      select count(*)::integer from public.quest_log_entries
      where user_id = p_uid and source_type::text in ('task', 'npc') and result = 'completed'
        and occurred_at >= current_date and occurred_at < current_date + 1)
    when 'focus' then (
      select count(*)::integer from public.dungeon_runs r
      join public.focus_sessions s on s.id = r.session_id
      where s.user_id = p_uid and r.completed
        and r.ended_at >= current_date and r.ended_at < current_date + 1)
  end
$$;

create or replace function public._challenge_target(p_key text)
returns integer
language sql
stable
security definer
set search_path = ''
as $$
  select public.rule('challenge_' || p_key || '_target')::integer
$$;

-- Ya cobrado: los del día, hoy; el del mes, este mes.
create or replace function public._challenge_claimed(p_uid uuid, p_key text)
returns boolean
language sql
stable
security definer
set search_path = ''
set timezone to 'America/Bogota'
as $$
  select exists (
    select 1 from public.quest_log_entries
    where user_id = p_uid and source_type::text = 'challenge'
      and source_id = public._challenge_id(p_key)
      and occurred_at >= case when p_key = 'month'
                              then date_trunc('month', current_date)::date
                              else current_date end)
$$;

-- Desafíos del día cobrados este mes (puntos del Desafío del mes).
create or replace function public._challenge_month_points(p_uid uuid)
returns integer
language sql
stable
security definer
set search_path = ''
set timezone to 'America/Bogota'
as $$
  select count(*)::integer from public.quest_log_entries
  where user_id = p_uid and source_type::text = 'challenge'
    and source_id <> public._challenge_id('month')
    and occurred_at >= date_trunc('month', current_date)::date
$$;

create or replace function public.claim_challenge(p_key text)
returns jsonb
language plpgsql
security definer
set search_path = ''
set timezone to 'America/Bogota'
as $$
declare
  v_uid uuid := auth.uid();
  v_progress integer;
  v_target integer;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  if p_key not in ('xp', 'tasks', 'focus', 'month') then
    raise exception 'challenge_not_found' using errcode = 'P0002';
  end if;
  perform pg_advisory_xact_lock(hashtext('challenge:' || v_uid::text));
  if public._challenge_claimed(v_uid, p_key) then
    raise exception 'challenge_already_claimed' using errcode = '23505';
  end if;
  if p_key = 'month' then
    v_progress := public._challenge_month_points(v_uid);
    v_target := public.rule('challenge_month_target')::integer;
  else
    v_progress := public._challenge_progress(v_uid, p_key);
    v_target := public._challenge_target(p_key);
  end if;
  if v_progress < v_target then
    raise exception 'challenge_locked' using errcode = '22023';
  end if;
  return public._award(v_uid, 'challenge', public._challenge_id(p_key), 0,
    public.rule(case when p_key = 'month' then 'challenge_month_coins'
                     else 'challenge_coins' end)::integer);
end $$;

-- XP de un rival al final de la semana y su ritmo (0..1 → cuándo la gana).
-- Determinista por usuario, semana y puesto: la tabla no cambia al recargar.
create or replace function public._league_rival(
  p_uid uuid, p_week date, p_division integer, p_slot integer,
  out name text, out full_xp integer, out pace numeric)
language sql
stable
security definer
set search_path = ''
as $$
  with h as (
    -- bigint: abs() del menor int4 desborda.
    select abs(hashtext(p_uid::text || p_week::text || p_slot)::bigint) as a,
           abs(hashtext(p_slot || p_week::text || p_uid::text)::bigint) as b,
           abs(hashtext(p_uid::text || p_week::text)::bigint) as base
  )
  select
    (array['Aria Luna','Bruno Vega','Camila Sol','Dante Roble','Elena Brisa',
           'Fabio Cruz','Gala Nieve','Hugo Pardo','Iris Monte','Joaquín Mar',
           'Kira Alba','León Duarte','Maya Ríos','Nico Valle','Olivia Paz',
           'Pablo Lago','Quira Flor','Rocío Aire','Saúl Peña','Tania Lince'])
      -- 3 y 20 son coprimos: los puestos 1–10 nunca repiten nombre.
      [1 + (h.base + p_slot * 3) % 20],
    round(public.rule('league_base_xp') * power(1.35, p_division)
          * (0.2 + (h.a % 1000) / 1000.0 * 1.6))::integer,
    0.5 + (h.b % 1000) / 1000.0
  from h
$$;

-- Puesto (1 = primero) del usuario con [p_xp] en una semana terminada o en curso.
create or replace function public._league_rank(
  p_uid uuid, p_week date, p_division integer, p_xp integer, p_fraction numeric)
returns integer
language sql
stable
security definer
set search_path = ''
as $$
  select 1 + count(*)::integer
  from generate_series(1, 10) i,
       lateral public._league_rival(p_uid, p_week, p_division, i) r
  where round(r.full_xp * power(p_fraction, r.pace)) > p_xp
$$;

create or replace function public._league_week_xp(p_uid uuid, p_week date)
returns integer
language sql
stable
security definer
set search_path = ''
set timezone to 'America/Bogota'
as $$
  select coalesce(sum(xp_awarded), 0)::integer from public.quest_log_entries
  where user_id = p_uid and occurred_at >= p_week and occurred_at < p_week + 7
$$;

-- Fila de esta semana; si falta, cierra la última semana jugada y sube o baja.
create or replace function public._league_current(p_uid uuid)
returns public.league_weeks
language plpgsql
security definer
set search_path = ''
set timezone to 'America/Bogota'
as $$
declare
  v_week date := date_trunc('week', current_date)::date;
  v_row public.league_weeks;
  v_prev public.league_weeks;
  v_rank integer;
  v_division integer := 0;
  v_result text;
begin
  select * into v_row from public.league_weeks where user_id = p_uid and week_start = v_week;
  if found then
    return v_row;
  end if;
  select * into v_prev from public.league_weeks
  where user_id = p_uid and week_start < v_week order by week_start desc limit 1;
  if found then
    v_rank := public._league_rank(p_uid, v_prev.week_start, v_prev.division,
      public._league_week_xp(p_uid, v_prev.week_start), 1);
    v_division := v_prev.division;
    v_result := 'stayed';
    if v_rank <= 3 and v_division < 9 then
      v_division := v_division + 1;
      v_result := 'promoted';
    elsif v_rank >= 9 and v_division > 0 then
      v_division := v_division - 1;
      v_result := 'demoted';
    end if;
  end if;
  insert into public.league_weeks (user_id, week_start, division, last_result)
  values (p_uid, v_week, v_division, v_result)
  on conflict (user_id, week_start) do nothing;
  select * into v_row from public.league_weeks where user_id = p_uid and week_start = v_week;
  return v_row;
end $$;

create or replace function public.challenges_overview()
returns jsonb
language plpgsql
security definer
set search_path = ''
set timezone to 'America/Bogota'
as $$
declare
  v_uid uuid := auth.uid();
  v_league public.league_weeks;
  v_fraction numeric;
  v_xp integer;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  v_league := public._league_current(v_uid);
  -- Parte de la semana que ya pasó: los rivales avanzan con ella.
  v_fraction := least(1, extract(epoch from (now() - v_league.week_start::timestamptz))
                         / (7 * 86400));
  v_xp := public._league_week_xp(v_uid, v_league.week_start);

  return jsonb_build_object(
    'daily', (
      select jsonb_agg(jsonb_build_object(
        'key', k,
        'progress', public._challenge_progress(v_uid, k),
        'target', public._challenge_target(k),
        'coins', public.rule('challenge_coins'),
        'claimed', public._challenge_claimed(v_uid, k)) order by o)
      from unnest(array['xp', 'tasks', 'focus']) with ordinality as t(k, o)),
    'month', jsonb_build_object(
      'progress', public._challenge_month_points(v_uid),
      'target', public.rule('challenge_month_target'),
      'coins', public.rule('challenge_month_coins'),
      'claimed', public._challenge_claimed(v_uid, 'month'),
      'days_left', (date_trunc('month', current_date) + interval '1 month')::date - current_date),
    'league', jsonb_build_object(
      'division', v_league.division,
      'last_result', v_league.last_result,
      'days_left', v_league.week_start + 7 - current_date,
      'xp', v_xp,
      'rivals', (
        select jsonb_agg(jsonb_build_object(
          'name', r.name,
          'xp', round(r.full_xp * power(v_fraction, r.pace))::integer))
        from generate_series(1, 10) i,
             lateral public._league_rival(v_uid, v_league.week_start, v_league.division, i) r))
  );
end $$;

revoke all on function public._challenge_id(text) from public, anon, authenticated;
revoke all on function public._challenge_progress(uuid, text) from public, anon, authenticated;
revoke all on function public._challenge_target(text) from public, anon, authenticated;
revoke all on function public._challenge_claimed(uuid, text) from public, anon, authenticated;
revoke all on function public._challenge_month_points(uuid) from public, anon, authenticated;
revoke all on function public._league_rival(uuid, date, integer, integer) from public, anon, authenticated;
revoke all on function public._league_rank(uuid, date, integer, integer, numeric) from public, anon, authenticated;
revoke all on function public._league_week_xp(uuid, date) from public, anon, authenticated;
revoke all on function public._league_current(uuid) from public, anon, authenticated;
revoke all on function public.claim_challenge(text) from public, anon;
grant execute on function public.claim_challenge(text) to authenticated;
revoke all on function public.challenges_overview() from public, anon;
grant execute on function public.challenges_overview() to authenticated;

commit;

-- ===== 053_nevi_reminders.sql =====
-- Migración 053 · Recordatorios del día con la voz de Nevi (requiere 048 y 049).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- La mascota se llama Nevi (decisión del usuario 2026-11-14). Solo cambian los
-- títulos y mensajes de _generate_reminders (048): Nevi habla en primera persona
-- y con tono de invitación (§7). Momentos, reglas y event_key son los mismos.

begin;

create or replace function public._generate_reminders(p_uid uuid, p_day date, p_time time)
returns void
language plpgsql
security definer
set search_path = ''
-- Hora de Colombia (049): reemplazar la función sin esto volvería a UTC.
set timezone to 'America/Bogota'
as $$
declare
  v_slot text;
  v_habits int;
  v_tasks int;
  v_projects int;
  v_streak int;
  v_done_today boolean;
  v_pick int;
  v_title text;
  v_message text;
  v_todo text;
  v_quedan text;
begin
  if not coalesce((select daily_reminders from public.game_master_settings
                   where user_id = p_uid), true) then
    return;
  end if;

  select s.slot into v_slot
  from (values ('morning', time '09:00'), ('midday', time '13:00'),
               ('afternoon', time '16:00'), ('evening', time '19:30'),
               ('last_call', time '21:30')) s(slot, at)
  where s.at <= p_time and p_time < s.at + interval '2 hours'
  order by s.at desc limit 1;
  if v_slot is null then
    return;
  end if;

  -- Si hace poco llegó otro aviso, este momento se salta.
  if exists (select 1 from public.notifications
             where user_id = p_uid and delivered_at > now() - interval '90 minutes') then
    return;
  end if;

  -- Hábitos buenos de hoy sin hacer.
  select count(*)::int into v_habits
  from public.habits h
  where h.user_id = p_uid and h.type = 'good'
    and (h.frequency = 'daily' or extract(dow from p_day)::int = any (h.specific_days))
    and not exists (select 1 from public.habit_records r
                    where r.habit_id = h.id and r.completed_on = p_day);
  -- La racha que se defiende es la más larga de los hábitos buenos.
  select coalesce(max(h.current_streak), 0)::int into v_streak
  from public.habits h where h.user_id = p_uid and h.type = 'good';

  -- Tareas que vencen hoy o ya vencieron.
  select count(*)::int into v_tasks
  from public.tasks
  where user_id = p_uid and parent_task_id is null
    and status in ('pending', 'in_progress')
    and due_date < (p_day + 1)::timestamptz;

  -- Proyectos en 🔴.
  select count(*)::int into v_projects
  from public.projects p
  cross join lateral (
    select count(*)::int total, count(*) filter (where t.status = 'completed')::int done
    from public.tasks t where t.project_id = p.id and t.parent_task_id is null) c
  where p.user_id = p_uid and p.archived_at is null and p.status in ('not_started', 'in_progress')
    and public._project_urgency(c.total, c.done, coalesce(p.start_date, p.created_at::date),
                                p.end_date, p_day) = 'high';

  if v_habits + v_tasks + v_projects = 0 then
    return; -- nada pendiente: no se molesta
  end if;

  v_done_today := exists (select 1 from public.habit_records r
                          join public.habits h on h.id = r.habit_id
                          where h.user_id = p_uid and r.completed_on = p_day);

  -- Resumen de lo pendiente: «2 hábitos y 1 tarea».
  v_todo := array_to_string(array_remove(array[
    case when v_habits = 1 then '1 hábito' when v_habits > 1 then v_habits || ' hábitos' end,
    case when v_tasks = 1 then '1 tarea' when v_tasks > 1 then v_tasks || ' tareas' end,
    case when v_projects = 1 then '1 proyecto urgente'
         when v_projects > 1 then v_projects || ' proyectos urgentes' end
  ], null), ' y ');

  v_quedan := case when v_habits + v_tasks + v_projects = 1 then 'Te queda ' else 'Te quedan ' end;

  -- El texto cambia cada día para no repetirse.
  v_pick := extract(doy from p_day)::int % 3 + 1;

  if v_slot = 'morning' then
    v_title := (array['Nevi: ¡buenos días! ☀️', 'Nevi: tu camino de hoy ya está listo 🗺️',
                      'Nevi: ¡nuevo día, nueva misión! ⚔️'])[v_pick];
    v_message := 'Hoy te esperan ' || v_todo || '. Yo empezaría por lo más pequeño.';
  elsif v_slot = 'midday' then
    v_title := (array['Nevi: ¿cinco minutos conmigo? ⏱️', 'Nevi: pausa productiva 🌱',
                      'Nevi: mitad del día, buen momento 💡'])[v_pick];
    v_message := v_quedan || v_todo || '. Cinco minutos ya cuentan, te acompaño.';
  elsif v_slot = 'afternoon' then
    v_title := (array['Nevi: aún estamos a tiempo 💪', 'Nevi: tu yo del futuro te lo agradecerá ✨',
                      'Nevi: un pasito más hoy 🚶'])[v_pick];
    v_message := 'Pendiente: ' || v_todo || '. ¿Empezamos con uno?';
  elsif v_slot = 'evening' then
    -- El aviso de racha de 036 (desde notify_streak_hour) ya salió hoy o sale
    -- en esta misma revisión: no repetir.
    if exists (select 1 from public.notifications
               where user_id = p_uid and category = 'streak'
                 and (delivered_at >= p_day::timestamptz
                      or (delivered_at is null and read_at is null
                          and created_at >= now() - interval '24 hours'
                          and p_time >= make_time(public.rule('notify_streak_hour')::int, 0, 0)))) then
      return;
    end if;
    if v_streak > 0 and v_habits > 0 and not v_done_today then
      v_title := 'Nevi: tu racha de ' || v_streak || ' días te espera 🔥';
      v_message := 'Un hábito hoy y la mantenemos. Te faltan ' || v_todo || '.';
    else
      v_title := (array['Nevi: cerremos el día con una victoria 🏁', 'Nevi: último empujón del día 🌙',
                        'Nevi: terminemos con algo hecho ✅'])[v_pick];
      v_message := v_quedan || v_todo || '. Te espero en el camino.';
    end if;
  else -- last_call: solo si hay una racha que mantener y hoy no se hizo nada
    if v_streak = 0 or v_habits = 0 or v_done_today then
      return;
    end if;
    -- §7: invitación, nunca amenaza (antes «Última oportunidad»).
    v_title := 'Nevi: tu racha de ' || v_streak || ' días sigue encendida 🔥';
    v_message := 'Un hábito rápido antes de dormir y la mantenemos juntos.';
  end if;

  insert into public.notifications (user_id, type, category, event_key, title, message, sent_at)
  values (p_uid, 'critical', 'reminder', 'reminder:' || p_uid || ':' || p_day || ':' || v_slot,
          v_title, v_message, now())
  on conflict (user_id, event_key) where event_key is not null do nothing;
end $$;

commit;

-- ===== 054_push_tick.sql =====
-- Migración 054 · El reloj de push llama a una función (requiere 050).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- En 050 el cron guardaba un comando largo con subconsultas y comillas dentro de
-- $job$…$job$; al copiarlo a mano quedó con un error de sintaxis («syntax error
-- at or near where», 2026-11-14) y nunca llamó a push-dispatch. Ahora la lógica
-- vive en _push_tick() y el cron solo ejecuta «select public._push_tick()».
--
-- Necesita pg_cron, pg_net y los secretos del Vault de 050:
--   lifequest_project_url = https://<proyecto>.supabase.co
--   lifequest_push_secret = el mismo valor del secret PUSH_CRON_SECRET

begin;

create or replace function public._push_tick()
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_url text;
  v_secret text;
begin
  select decrypted_secret into v_url
  from vault.decrypted_secrets where name = 'lifequest_project_url';
  select decrypted_secret into v_secret
  from vault.decrypted_secrets where name = 'lifequest_push_secret';
  if v_url is null or v_secret is null then
    raise exception 'push_secrets_missing'
      using hint = 'Crea lifequest_project_url y lifequest_push_secret en el Vault (050).';
  end if;
  -- Devuelve el id de la petición de pg_net (la respuesta llega a net._http_response).
  return net.http_post(
    url := rtrim(v_url, '/') || '/functions/v1/push-dispatch',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-push-secret', v_secret),
    body := '{}'::jsonb);
end $$;

-- Solo el cron (postgres) la ejecuta.
revoke all on function public._push_tick() from public, anon, authenticated;

do $$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    perform cron.unschedule(jobid) from cron.job where jobname = 'lifequest_push';
    perform cron.schedule('lifequest_push', '*/5 * * * *', 'select public._push_tick()');
  else
    raise notice 'Activa pg_cron y pg_net (Database → Extensions) y vuelve a ejecutar esta migración.';
  end if;
end $$;

commit;

-- ===== 055_nevi_notifications.sql =====
-- Migración 055 · Los avisos del día también los firma Nevi (requiere 045 y 049).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- Igual que 053 con los recordatorios: solo cambian títulos y mensajes de
-- _generate_notifications (045). Nevi habla con tono de invitación (§7); reglas,
-- categorías, event_key y la hora de Colombia (049) son los mismos.

begin;

create or replace function public._generate_notifications(p_uid uuid, p_day date)
returns void
language plpgsql
security definer
set search_path = ''
-- Hora de Colombia (049): reemplazar la función sin esto volvería a UTC.
set timezone to 'America/Bogota'
as $$
declare
  v_reduced text[];
begin
  select coalesce(array_agg(category), '{}') into v_reduced
  from public.notification_category_state where user_id = p_uid and reduced;

  insert into public.notifications (user_id, type, category, event_key, title, message,
                                    related_entity_type, related_entity_id, sent_at)
  select p_uid, x.type::public.notification_type, x.category, x.key, x.title, x.message,
         x.entity_type, x.entity_id, now()
  from (
    -- ▲ Racha en riesgo (tono de invitación, nunca de amenaza).
    select 'critical' type, 'streak' category,
           'streak:' || h.id || ':' || p_day key,
           'Nevi: tu racha te está esperando 🔥' title,
           'Llevas ' || h.current_streak || ' días con «' || h.name || '». Hoy podemos sumar uno más.' message,
           'habit' entity_type, h.id entity_id
    from public.habits h
    where h.user_id = p_uid and h.type = 'good' and coalesce(h.current_streak, 0) > 0
      and (h.frequency = 'daily' or extract(dow from p_day)::int = any (h.specific_days))
      and not exists (select 1 from public.habit_records r
                      where r.habit_id = h.id and r.completed_on = p_day)
    union all
    -- ▲ Proyecto en 🔴.
    select 'critical', 'project', 'project:' || p.id || ':' || p_day,
           'Nevi: un proyecto necesita tu atención',
           '«' || p.title || '» va con el tiempo justo. Una misión hoy lo pone al día, te acompaño.',
           'project', p.id
    from public.projects p
    cross join lateral (
      select count(*)::int total, count(*) filter (where t.status = 'completed')::int done
      from public.tasks t where t.project_id = p.id and t.parent_task_id is null) c
    where p.user_id = p_uid and p.archived_at is null and p.status in ('not_started', 'in_progress')
      and public._project_urgency(c.total, c.done, coalesce(p.start_date, p.created_at::date),
                                  p.end_date, p_day) = 'high'
    union all
    -- ● Cerca de subir de nivel.
    select 'motivational', 'level', 'level:' || p_uid || ':' || s.level,
           'Nevi: ¡estás a un paso del nivel ' || (s.level + 1) || '!',
           'Te faltan ' || (s.xp_to_next_level - s.current_xp) || ' XP. Una misión más y lo logramos.',
           null, null
    from public.character_stats s
    where s.user_id = p_uid and s.current_xp >= s.xp_to_next_level * 0.9
      and not ('level' = any (v_reduced))
    union all
    -- ● Cofre del día listo (misma regla que claim_daily_chest).
    select 'motivational', 'chest', 'chest:' || p_uid || ':' || p_day,
           'Nevi: ¡tu cofre del día está listo! 🎁',
           'Cumpliste tus misiones de hoy. Ábrelo en el Inicio.',
           null, null
    where (select count(*) from public.quest_log_entries
           where user_id = p_uid and source_type::text in ('task', 'npc') and result = 'completed'
             and coin_awarded > 0 and occurred_at >= current_date and occurred_at < current_date + 1)
          >= public.rule('daily_chest_min_missions')
      and not exists (select 1 from public.quest_log_entries
                      where user_id = p_uid and source_type::text = 'daily_chest'
                        and occurred_at >= current_date and occurred_at < current_date + 1)
      and not ('chest' = any (v_reduced))
    union all
    -- ▲ Hábitos de hoy sin hacer y aún sin racha: un solo aviso que los junta
    --   (los que tienen racha ya avisan arriba). Categoría streak: misma hora.
    select 'critical', 'streak', 'habits_pending:' || p_uid || ':' || p_day,
           'Nevi: tienes hábitos pendientes hoy',
           case when count(*) = 1 then 'Te falta «' || min(h.name) || '». Un paso pequeño también cuenta.'
                else 'Te faltan ' || count(*) || ' hábitos: ' || string_agg(h.name, ', ' order by h.name) || '.' end,
           null, null
    from public.habits h
    where h.user_id = p_uid and h.type = 'good' and coalesce(h.current_streak, 0) = 0
      and (h.frequency = 'daily' or extract(dow from p_day)::int = any (h.specific_days))
      and not exists (select 1 from public.habit_records r
                      where r.habit_id = h.id and r.completed_on = p_day)
    having count(*) > 0
    union all
    -- ▲ Tareas vencidas que siguen abiertas.
    select 'critical', 'overdue', 'overdue:' || p_uid || ':' || p_day,
           'Nevi: tienes tareas pendientes',
           case when n = 1 then '1 tarea ya pasó su fecha. La retomamos cuando puedas.'
                else n || ' tareas ya pasaron su fecha. Elige una y empezamos por ahí.' end,
           null, null
    from (select count(*) n from public.tasks
          where user_id = p_uid and parent_task_id is null
            and status in ('pending', 'in_progress')
            and due_date < p_day::timestamptz) o
    where n > 0
    union all
    -- ○ Lo que vence hoy.
    select 'informational', 'due', 'due:' || p_uid || ':' || p_day,
           'Nevi: tu día de hoy',
           case when n = 1 then 'Hoy vence 1 misión. Tú decides cuándo.'
                else 'Hoy vencen ' || n || ' misiones. Tú decides el orden.' end,
           null, null
    from (select count(*) n from public.tasks
          where user_id = p_uid and parent_task_id is null
            and status in ('pending', 'in_progress')
            and due_date >= p_day::timestamptz and due_date < (p_day + 1)::timestamptz) d
    where n > 0 and not ('due' = any (v_reduced))
  ) x
  on conflict (user_id, event_key) where event_key is not null do nothing;
end $$;

commit;

-- ===== 056_activity_streak.sql =====
-- Migración 056 · Racha diaria de actividad (requiere 041).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- Como en Duolingo, la racha del Inicio cuenta días seguidos con al menos una
-- actividad real: tarea, misión de mentor, hábito cumplido, ciclo de Foco, paso
-- de tarea guiada, proyecto o meta (quest_log_entries con result = 'completed').
-- Cofres, desafíos y logros no cuentan: son premios, no esfuerzo. Un mal hábito
-- se registra como 'failed' y tampoco cuenta.
-- Si hoy aún no hay actividad, la racha sigue viva desde ayer hasta que acabe
-- el día. Se calcula (CLAUDE.md §8: lo derivable no se guarda). Las rachas por
-- hábito (habits.current_streak) no cambian.
--
-- home_dashboard es la misma copia de 041 con streak_days de _activity_streak.

begin;

create or replace function public._activity_streak(
  p_uid uuid,
  p_day date,
  p_utc_offset_minutes integer default 0
)
returns integer
language sql
stable
-- invoker: lee quest_log_entries con su RLS (cada quien solo ve lo suyo).
security invoker
set search_path = ''
as $$
  with days as (
    -- Día local del usuario de cada actividad (mismo desfase que el Inicio).
    select distinct (q.occurred_at at time zone 'UTC'
                     + make_interval(mins => p_utc_offset_minutes))::date as d
    from public.quest_log_entries q
    where q.user_id = p_uid
      and q.result = 'completed'
      and q.source_type::text in ('task', 'npc', 'habit', 'dungeon', 'task_step', 'project', 'goal')
      and q.occurred_at > now() - interval '400 days'
  ),
  anchor as (
    select case when exists (select 1 from days where d = p_day) then p_day
                else p_day - 1 end as a
  ),
  ranked as (
    select d, row_number() over (order by d desc) as rn
    from days, anchor where d <= anchor.a
  )
  -- Días consecutivos hacia atrás desde el ancla: al primer hueco deja de contar.
  select count(*)::int from ranked, anchor where ranked.d = anchor.a - (ranked.rn::int - 1)
$$;

revoke all on function public._activity_streak(uuid, date, integer) from public, anon;
grant execute on function public._activity_streak(uuid, date, integer) to authenticated;

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
    -- 056: racha de días con actividad (estilo Duolingo), no solo de hábitos.
    'streak_days', public._activity_streak(auth.uid(), p_day, p_utc_offset_minutes),
    -- 038: lista «Hoy» del Inicio (plan S2). Vencen hoy, vencidas o de
    -- prioridad alta; la app quita la que ya muestra como Siguiente paso.
    'today_tasks', coalesce((
      select jsonb_agg(jsonb_build_object(
               'id', t.id,
               'title', t.title,
               'priority', t.priority,
               'due_date', t.due_date,
               'xp_reward', t.xp_reward,
               'overdue', coalesce(t.due_date < now(), false))
             order by t.due_date nulls last, t.created_at)
      from (
        select t.* from public.tasks t, day
        where t.user_id = auth.uid()
          and t.parent_task_id is null
          and t.status in ('pending', 'in_progress')
          and (t.due_date < day.end_at or t.priority = 'high')
        order by t.due_date nulls last, t.created_at
        limit 6
      ) t
    ), '[]'::jsonb),
    -- 041: tarjetas del Inicio de Main.dc.html (Mentores, Bandeja y Meta).
    'mentor_task', (
      select jsonb_build_object('id', t.id, 'title', t.title,
                                'xp_reward', t.xp_reward, 'mentor', n.name)
      from public.tasks t join public.npcs n on n.id = t.npc_id
      where t.user_id = auth.uid() and t.status in ('pending', 'in_progress')
      order by t.created_at desc
      limit 1
    ),
    'inbox_count', (
      select count(*) from public.brain_dump_entries
      where user_id = auth.uid() and status = 'pending'
    ),
    'top_goal', (
      select jsonb_build_object('id', g.id, 'title', g.title, 'due_date', g.due_date,
                                'hp', g.boss_current_hp, 'max_hp', g.boss_max_hp)
      from public.goals g
      where g.user_id = auth.uid() and g.status in ('not_started', 'in_progress')
        and g.archived_at is null
      order by g.due_date nulls last, g.created_at
      limit 1
    ),
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
revoke all on function public.home_dashboard(date, integer) from public, anon;
grant execute on function public.home_dashboard(date, integer) to authenticated;

commit;

-- ===== 057_achievements.sql =====
-- Migración 057 · Logros que se desbloquean solos (requiere 026, 052 y 056).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- 1. Catálogo de 12 logros (achievements, antes vacío). Premios provisionales.
-- 2. _unlock_achievements(uid): revisa las condiciones; si se cumple una, guarda
--    user_achievements, paga con _award('achievement') y deja un aviso de Nevi.
-- 3. Triggers: después de cada fila de quest_log_entries (salvo los pagos de
--    logros, para no entrar en bucle) y al abrir una semana de liga.
-- El cliente no puede escribir user_achievements (003): solo el servidor.

begin;

-- 1. Catálogo -------------------------------------------------------------------
insert into public.achievements (code, name, description, reward_coins) values
  ('first_task',     'Primer paso',          'Completa tu primera tarea.',                 10),
  ('tasks_10',       'Manos a la obra',      'Completa 10 tareas.',                        20),
  ('tasks_50',       'Imparable',            'Completa 50 tareas.',                        50),
  ('first_habit',    'Buen hábito',          'Cumple un hábito por primera vez.',          10),
  ('streak_3',       'Racha encendida',      'Logra una racha de 3 días con actividad.',   15),
  ('streak_7',       'Semana de fuego',      'Logra una racha de 7 días con actividad.',   30),
  ('streak_30',      'Llama eterna',         'Logra una racha de 30 días con actividad.',  60),
  ('focus_10',       'Maestro del foco',     'Termina 10 ciclos en el Modo Foco.',         30),
  ('chests_10',      'Cazador de cofres',    'Abre 10 cofres del día.',                    30),
  ('challenges_10',  'Retador',              'Cumple 10 desafíos del día.',                30),
  ('level_5',        'Aventurero',           'Llega al nivel 5.',                          40),
  ('league_up',      'Ascenso',              'Sube de división en la Liga.',               25)
on conflict (code) do update
  set name = excluded.name, description = excluded.description,
      reward_coins = excluded.reward_coins;

-- 2. Desbloqueo -------------------------------------------------------------------
create or replace function public._unlock_achievements(p_uid uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  -- shortcut: día y desfase de Colombia (049), app de un solo país.
  v_day date := (now() at time zone 'America/Bogota')::date;
  v_count integer;
  a record;
  v_ok boolean;
begin
  for a in
    select ac.id, ac.code, ac.name, ac.reward_coins
    from public.achievements ac
    where not exists (select 1 from public.user_achievements ua
                      where ua.user_id = p_uid and ua.achievement_id = ac.id)
  loop
    v_ok := case a.code
      when 'first_task' then exists (
        select 1 from public.quest_log_entries where user_id = p_uid
          and source_type::text in ('task', 'npc') and result = 'completed')
      when 'tasks_10' then (
        select count(*) from public.quest_log_entries where user_id = p_uid
          and source_type::text in ('task', 'npc') and result = 'completed') >= 10
      when 'tasks_50' then (
        select count(*) from public.quest_log_entries where user_id = p_uid
          and source_type::text in ('task', 'npc') and result = 'completed') >= 50
      when 'first_habit' then exists (
        select 1 from public.quest_log_entries where user_id = p_uid
          and source_type::text = 'habit' and result = 'completed')
      when 'streak_3' then public._activity_streak(p_uid, v_day, -300) >= 3
      when 'streak_7' then public._activity_streak(p_uid, v_day, -300) >= 7
      when 'streak_30' then public._activity_streak(p_uid, v_day, -300) >= 30
      when 'focus_10' then (
        select count(*) from public.quest_log_entries where user_id = p_uid
          and source_type::text = 'dungeon' and result = 'completed') >= 10
      when 'chests_10' then (
        select count(*) from public.quest_log_entries where user_id = p_uid
          and source_type::text = 'daily_chest') >= 10
      when 'challenges_10' then (
        select count(*) from public.quest_log_entries where user_id = p_uid
          and source_type::text = 'challenge') >= 10
      when 'level_5' then coalesce((
        select level from public.character_stats where user_id = p_uid), 0) >= 5
      when 'league_up' then exists (
        select 1 from public.league_weeks where user_id = p_uid and last_result = 'promoted')
      else false
    end;
    if not v_ok then
      continue;
    end if;
    -- Unicidad (user_id, achievement_id): nunca se cobra dos veces.
    insert into public.user_achievements (user_id, achievement_id)
    values (p_uid, a.id) on conflict do nothing;
    get diagnostics v_count = row_count;
    if v_count = 0 then
      continue;
    end if;
    if a.reward_coins > 0 then
      perform public._award(p_uid, 'achievement', a.id, 0, a.reward_coins);
    end if;
    insert into public.notifications (user_id, type, category, event_key, title, message, sent_at)
    values (p_uid, 'motivational', 'achievement', 'achievement:' || a.id,
            'Nevi: ¡desbloqueaste «' || a.name || '»! 🏅',
            'Ganaste ' || a.reward_coins || ' Monedas. Míralo en Perfil → Logros.', now())
    on conflict (user_id, event_key) where event_key is not null do nothing;
  end loop;
end $$;

revoke all on function public._unlock_achievements(uuid) from public, anon, authenticated;

-- 3. Disparadores -------------------------------------------------------------------
create or replace function public._achievements_on_log()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public._unlock_achievements(new.user_id);
  return null;
end $$;

drop trigger if exists trg_achievements_on_log on public.quest_log_entries;
create trigger trg_achievements_on_log
  after insert on public.quest_log_entries
  for each row
  -- Los pagos de logros también son filas: sin esto, un logro revisaría otro sin fin.
  when (new.source_type::text <> 'achievement')
  execute function public._achievements_on_log();

drop trigger if exists trg_achievements_on_league on public.league_weeks;
create trigger trg_achievements_on_league
  after insert on public.league_weeks
  for each row execute function public._achievements_on_log();

revoke all on function public._achievements_on_log() from public, anon, authenticated;

-- 4. Quienes ya jugaban reciben al instante lo que ya habían logrado.
select public._unlock_achievements(id) from public.profiles;

commit;

-- ===== 058_streak_reminders.sql =====
-- Migración 058 · Los recordatorios defienden la racha diaria (requiere 053 y 056).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- Copia de 053 con un cambio: «tu racha de N días» (19:30 y 21:30) era la del
-- mejor hábito, pero el 🔥 del Inicio es la racha diaria de actividad (056).
-- Ahora usa _activity_streak y «hoy ya hiciste algo» cuenta cualquier actividad
-- real, no solo hábitos. Momentos, reglas y event_key son los mismos.

begin;

create or replace function public._generate_reminders(p_uid uuid, p_day date, p_time time)
returns void
language plpgsql
security definer
set search_path = ''
-- Hora de Colombia (049): reemplazar la función sin esto volvería a UTC.
set timezone to 'America/Bogota'
as $$
declare
  v_slot text;
  v_habits int;
  v_tasks int;
  v_projects int;
  v_streak int;
  v_done_today boolean;
  v_pick int;
  v_title text;
  v_message text;
  v_todo text;
  v_quedan text;
begin
  if not coalesce((select daily_reminders from public.game_master_settings
                   where user_id = p_uid), true) then
    return;
  end if;

  select s.slot into v_slot
  from (values ('morning', time '09:00'), ('midday', time '13:00'),
               ('afternoon', time '16:00'), ('evening', time '19:30'),
               ('last_call', time '21:30')) s(slot, at)
  where s.at <= p_time and p_time < s.at + interval '2 hours'
  order by s.at desc limit 1;
  if v_slot is null then
    return;
  end if;

  -- Si hace poco llegó otro aviso, este momento se salta.
  if exists (select 1 from public.notifications
             where user_id = p_uid and delivered_at > now() - interval '90 minutes') then
    return;
  end if;

  -- Hábitos buenos de hoy sin hacer.
  select count(*)::int into v_habits
  from public.habits h
  where h.user_id = p_uid and h.type = 'good'
    and (h.frequency = 'daily' or extract(dow from p_day)::int = any (h.specific_days))
    and not exists (select 1 from public.habit_records r
                    where r.habit_id = h.id and r.completed_on = p_day);
  -- La racha que se defiende es la del Inicio (056); si hoy no hay actividad
  -- cuenta hasta ayer. shortcut: desfase fijo de Colombia (049), app de un solo país.
  v_streak := public._activity_streak(p_uid, p_day, -300);

  -- Tareas que vencen hoy o ya vencieron.
  select count(*)::int into v_tasks
  from public.tasks
  where user_id = p_uid and parent_task_id is null
    and status in ('pending', 'in_progress')
    and due_date < (p_day + 1)::timestamptz;

  -- Proyectos en 🔴.
  select count(*)::int into v_projects
  from public.projects p
  cross join lateral (
    select count(*)::int total, count(*) filter (where t.status = 'completed')::int done
    from public.tasks t where t.project_id = p.id and t.parent_task_id is null) c
  where p.user_id = p_uid and p.archived_at is null and p.status in ('not_started', 'in_progress')
    and public._project_urgency(c.total, c.done, coalesce(p.start_date, p.created_at::date),
                                p.end_date, p_day) = 'high';

  if v_habits + v_tasks + v_projects = 0 then
    return; -- nada pendiente: no se molesta
  end if;

  -- Mismas fuentes que _activity_streak (056); la función va en hora de Colombia.
  v_done_today := exists (select 1 from public.quest_log_entries q
                          where q.user_id = p_uid and q.result = 'completed'
                            and q.source_type::text in ('task', 'npc', 'habit', 'dungeon',
                                                        'task_step', 'project', 'goal')
                            and q.occurred_at >= p_day::timestamptz
                            and q.occurred_at < (p_day + 1)::timestamptz);

  -- Resumen de lo pendiente: «2 hábitos y 1 tarea».
  v_todo := array_to_string(array_remove(array[
    case when v_habits = 1 then '1 hábito' when v_habits > 1 then v_habits || ' hábitos' end,
    case when v_tasks = 1 then '1 tarea' when v_tasks > 1 then v_tasks || ' tareas' end,
    case when v_projects = 1 then '1 proyecto urgente'
         when v_projects > 1 then v_projects || ' proyectos urgentes' end
  ], null), ' y ');

  v_quedan := case when v_habits + v_tasks + v_projects = 1 then 'Te queda ' else 'Te quedan ' end;

  -- El texto cambia cada día para no repetirse.
  v_pick := extract(doy from p_day)::int % 3 + 1;

  if v_slot = 'morning' then
    v_title := (array['Nevi: ¡buenos días! ☀️', 'Nevi: tu camino de hoy ya está listo 🗺️',
                      'Nevi: ¡nuevo día, nueva misión! ⚔️'])[v_pick];
    v_message := 'Hoy te esperan ' || v_todo || '. Yo empezaría por lo más pequeño.';
  elsif v_slot = 'midday' then
    v_title := (array['Nevi: ¿cinco minutos conmigo? ⏱️', 'Nevi: pausa productiva 🌱',
                      'Nevi: mitad del día, buen momento 💡'])[v_pick];
    v_message := v_quedan || v_todo || '. Cinco minutos ya cuentan, te acompaño.';
  elsif v_slot = 'afternoon' then
    v_title := (array['Nevi: aún estamos a tiempo 💪', 'Nevi: tu yo del futuro te lo agradecerá ✨',
                      'Nevi: un pasito más hoy 🚶'])[v_pick];
    v_message := 'Pendiente: ' || v_todo || '. ¿Empezamos con uno?';
  elsif v_slot = 'evening' then
    -- El aviso de racha de 036 (desde notify_streak_hour) ya salió hoy o sale
    -- en esta misma revisión: no repetir.
    if exists (select 1 from public.notifications
               where user_id = p_uid and category = 'streak'
                 and (delivered_at >= p_day::timestamptz
                      or (delivered_at is null and read_at is null
                          and created_at >= now() - interval '24 hours'
                          and p_time >= make_time(public.rule('notify_streak_hour')::int, 0, 0)))) then
      return;
    end if;
    if v_streak > 0 and not v_done_today then
      v_title := 'Nevi: tu racha de ' || v_streak || case when v_streak = 1 then ' día' else ' días' end || ' te espera 🔥';
      v_message := 'Una actividad hoy y la mantenemos. Te faltan ' || v_todo || '.';
    else
      v_title := (array['Nevi: cerremos el día con una victoria 🏁', 'Nevi: último empujón del día 🌙',
                        'Nevi: terminemos con algo hecho ✅'])[v_pick];
      v_message := v_quedan || v_todo || '. Te espero en el camino.';
    end if;
  else -- last_call: solo si hay una racha que mantener y hoy no se hizo nada
    if v_streak = 0 or v_done_today then
      return;
    end if;
    -- §7: invitación, nunca amenaza (antes «Última oportunidad»).
    v_title := 'Nevi: tu racha de ' || v_streak || case when v_streak = 1 then ' día' else ' días' end || ' sigue encendida 🔥';
    v_message := 'Una tarea o un hábito rápido antes de dormir y la mantenemos juntos.';
  end if;

  insert into public.notifications (user_id, type, category, event_key, title, message, sent_at)
  values (p_uid, 'critical', 'reminder', 'reminder:' || p_uid || ':' || p_day || ':' || v_slot,
          v_title, v_message, now())
  on conflict (user_id, event_key) where event_key is not null do nothing;
end $$;

commit;

-- ===== 059_activity_month.sql =====
-- Migración 059 · Calendario de racha del Perfil (requiere 056).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- activity_month(día, desfase): la racha diaria (056) y, para el mes de ese
-- día, cuántas actividades reales hubo cada día local ({"14": 3, …}). Mismas
-- fuentes que _activity_streak: cofres, desafíos, logros y malos hábitos no cuentan.

begin;

create or replace function public.activity_month(
  p_day date,
  p_utc_offset_minutes integer default 0
)
returns jsonb
language sql
stable
-- invoker: lee quest_log_entries con su RLS (cada quien solo ve lo suyo).
security invoker
set search_path = ''
as $$
  with days as (
    select (q.occurred_at at time zone 'UTC'
            + make_interval(mins => p_utc_offset_minutes))::date as d
    from public.quest_log_entries q
    where q.user_id = auth.uid()
      and q.result = 'completed'
      and q.source_type::text in ('task', 'npc', 'habit', 'dungeon', 'task_step', 'project', 'goal')
      -- Un día de margen a cada lado; el desfase decide en qué día local cae.
      and q.occurred_at >= date_trunc('month', p_day) - interval '1 day'
      and q.occurred_at < date_trunc('month', p_day) + interval '1 month 1 day'
  )
  select jsonb_build_object(
    'streak', public._activity_streak(auth.uid(), p_day, p_utc_offset_minutes),
    'days', coalesce((
      select jsonb_object_agg(extract(day from d)::int, n)
      from (select d, count(*)::int n from days
            where date_trunc('month', d) = date_trunc('month', p_day)
            group by d) c
    ), '{}'::jsonb))
$$;

revoke all on function public.activity_month(date, integer) from public, anon;
grant execute on function public.activity_month(date, integer) to authenticated;

commit;


-- ===== 060_daily_streak_protector.sql =====
-- Migración 060 · El Protector de racha también cuida la racha diaria (requiere 054 y 056).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- Como el «congelar racha» de Duolingo: cada noche (00:10 en Colombia), si
-- ayer no hubo actividad, la racha diaria estaba viva y hay un Protector
-- guardado (recovery_passes sin usar), se gasta solo para proteger ayer
-- (habit_id null, protected_day = ayer) y Nevi lo cuenta en el resumen de la
-- mañana (informativo: nunca despierta a nadie). El día protegido une la
-- racha pero no suma días: la racha cuenta solo días con actividad real.
-- Los protectores son los mismos de los hábitos (use_recovery_pass, 006).

begin;

-- 1. La racha salta los días protegidos ---------------------------------------
create or replace function public._activity_streak(
  p_uid uuid,
  p_day date,
  p_utc_offset_minutes integer default 0
)
returns integer
language sql
stable
-- invoker: lee quest_log_entries y recovery_passes con su RLS.
security invoker
set search_path = ''
as $$
  with days as (
    select d, bool_or(real) as real
    from (
      -- Día local del usuario de cada actividad (mismo desfase que el Inicio).
      select (q.occurred_at at time zone 'UTC'
              + make_interval(mins => p_utc_offset_minutes))::date as d, true as real
      from public.quest_log_entries q
      where q.user_id = p_uid
        and q.result = 'completed'
        and q.source_type::text in ('task', 'npc', 'habit', 'dungeon', 'task_step', 'project', 'goal')
        and q.occurred_at > now() - interval '400 days'
      union all
      -- Días cubiertos por un Protector de la racha diaria (060).
      select r.protected_day, false
      from public.recovery_passes r
      where r.user_id = p_uid and r.habit_id is null and r.protected_day is not null
    ) x
    group by d
  ),
  anchor as (
    select case when exists (select 1 from days where d = p_day) then p_day
                else p_day - 1 end as a
  ),
  ranked as (
    select d, real, row_number() over (order by d desc) as rn
    from days, anchor where d <= anchor.a
  )
  -- Días seguidos hacia atrás desde el ancla; solo suman los de actividad real.
  select (count(*) filter (where real))::int
  from ranked, anchor where ranked.d = anchor.a - (ranked.rn::int - 1)
$$;

-- 2. Gastar un Protector por la noche -------------------------------------------
create or replace function public._protect_daily_streaks()
returns integer
language plpgsql
security definer
set search_path = ''
set timezone to 'America/Bogota'
as $$
declare
  -- shortcut: día y desfase de Colombia (049), app de un solo país.
  v_today date := now()::date;
  v_uid uuid;
  v_streak integer;
  v_pass uuid;
  v_used integer := 0;
begin
  for v_uid in
    select distinct user_id from public.recovery_passes where used_at is null
  loop
    -- Hoy y ayer sin actividad (0) pero la racha seguía viva hasta anteayer.
    if public._activity_streak(v_uid, v_today, -300) > 0 then
      continue;
    end if;
    v_streak := public._activity_streak(v_uid, v_today - 1, -300);
    if v_streak = 0 then
      continue;
    end if;
    select id into v_pass from public.recovery_passes
    where user_id = v_uid and used_at is null
    order by acquired_at limit 1 for update;
    update public.recovery_passes
    set used_at = now(), protected_day = v_today - 1
    where id = v_pass;
    insert into public.notifications (user_id, type, category, event_key, title, message, sent_at)
    values (v_uid, 'informational', 'streak_protector', 'streak_protector:' || (v_today - 1),
            'Nevi: usé un Protector y tu racha sigue viva 🛡️',
            'Ayer no hubo actividad, así que gasté un Protector de racha. Tus '
              || v_streak || case when v_streak = 1 then ' día' else ' días' end
              || ' de racha siguen en pie.',
            now())
    on conflict (user_id, event_key) where event_key is not null do nothing;
    v_used := v_used + 1;
  end loop;
  return v_used;
end $$;

revoke all on function public._protect_daily_streaks() from public, anon, authenticated;

-- 3. Cron: 05:10 UTC = 00:10 en Colombia, después de lifequest_daily (05:05) ----
do $$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    perform cron.unschedule(jobid) from cron.job where jobname = 'lifequest_streak_protector';
    perform cron.schedule('lifequest_streak_protector', '10 5 * * *',
                          'select public._protect_daily_streaks()');
  else
    raise notice 'Activa pg_cron (Database → Extensions) y vuelve a ejecutar esta migración.';
  end if;
end $$;

commit;

-- ===== 061_weekly_summary.sql =====
-- Migración 061 · Resumen semanal de Nevi (requiere 056 y 060).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- Cada domingo a las 19:00 de Colombia (cron lunes 00:00 UTC) Nevi manda un
-- aviso con la semana (lunes a hoy): XP, días con actividad, tareas y racha,
-- comparando la XP con la semana pasada. Solo a quien tuvo actividad en las
-- últimas 2 semanas: a quien dejó la app no se le insiste (§9).

begin;

create or replace function public._weekly_summary()
returns integer
language plpgsql
security definer
set search_path = ''
set timezone to 'America/Bogota'
as $$
declare
  -- shortcut: semana y desfase de Colombia (049), app de un solo país.
  v_today date := now()::date;
  v_start date := date_trunc('week', now())::date;  -- lunes
  u record;
  v_streak integer;
  v_title text;
  v_message text;
  v_sent integer := 0;
begin
  for u in
    select q.user_id,
           coalesce(sum(q.xp_awarded) filter (where q.occurred_at >= v_start::timestamptz), 0)::int xp,
           coalesce(sum(q.xp_awarded) filter (where q.occurred_at < v_start::timestamptz), 0)::int xp_prev,
           count(distinct q.occurred_at::date) filter (
             where q.occurred_at >= v_start::timestamptz and q.result = 'completed'
               and q.source_type::text in ('task', 'npc', 'habit', 'dungeon', 'task_step', 'project', 'goal')
           )::int days,
           count(*) filter (
             where q.occurred_at >= v_start::timestamptz and q.result = 'completed'
               and q.source_type::text in ('task', 'npc')
           )::int tasks
    from public.quest_log_entries q
    where q.occurred_at >= (v_start - 7)::timestamptz
    group by q.user_id
  loop
    v_streak := public._activity_streak(u.user_id, v_today, -300);
    if u.days = 0 then
      v_title := 'Nevi: una semana tranquila 🌙';
      v_message := 'Esta semana descansamos. Mañana empieza otra: te espero con algo pequeño.';
    else
      v_title := 'Nevi: tu semana en LifeQuest 📊';
      v_message := u.xp || ' XP, ' || u.days || ' de 7 días con actividad y '
        || u.tasks || case when u.tasks = 1 then ' tarea' else ' tareas' end || '.'
        || case when u.xp > u.xp_prev and u.xp_prev > 0
                  then ' ¡' || (u.xp - u.xp_prev) || ' XP más que la semana pasada!'
                else '' end
        || case when v_streak > 0
                  then ' Tu racha va en ' || v_streak
                       || case when v_streak = 1 then ' día' else ' días' end || ' 🔥.'
                else '' end
        || ' ¡Vamos por otra semana!';
    end if;
    insert into public.notifications (user_id, type, category, event_key, title, message, sent_at)
    values (u.user_id, 'motivational', 'weekly', 'weekly:' || v_start, v_title, v_message, now())
    on conflict (user_id, event_key) where event_key is not null do nothing;
    v_sent := v_sent + 1;
  end loop;
  return v_sent;
end $$;

revoke all on function public._weekly_summary() from public, anon, authenticated;

-- Lunes 00:00 UTC = domingo 19:00 en Colombia; el reloj de push lo entrega en ≤ 5 min.
do $$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    perform cron.unschedule(jobid) from cron.job where jobname = 'lifequest_weekly';
    perform cron.schedule('lifequest_weekly', '0 0 * * 1', 'select public._weekly_summary()');
  else
    raise notice 'Activa pg_cron (Database → Extensions) y vuelve a ejecutar esta migración.';
  end if;
end $$;

commit;

-- ===== 062_streak_100.sql =====
-- Migración 062 · Logro de 100 días de racha (requiere 057).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- Hitos de racha: la app celebra los 7, 30, 100 y 365 días con una pantalla
-- especial; los de 7 y 30 ya pagan con sus logros (057). Este agrega «Leyenda»
-- (100 días, premio provisional) y su condición en _unlock_achievements, que
-- es la misma copia de 057 con una línea más.

begin;

insert into public.achievements (code, name, description, reward_coins) values
  ('streak_100', 'Leyenda', 'Logra una racha de 100 días con actividad.', 100)
on conflict (code) do update
  set name = excluded.name, description = excluded.description,
      reward_coins = excluded.reward_coins;

create or replace function public._unlock_achievements(p_uid uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  -- shortcut: día y desfase de Colombia (049), app de un solo país.
  v_day date := (now() at time zone 'America/Bogota')::date;
  v_count integer;
  a record;
  v_ok boolean;
begin
  for a in
    select ac.id, ac.code, ac.name, ac.reward_coins
    from public.achievements ac
    where not exists (select 1 from public.user_achievements ua
                      where ua.user_id = p_uid and ua.achievement_id = ac.id)
  loop
    v_ok := case a.code
      when 'first_task' then exists (
        select 1 from public.quest_log_entries where user_id = p_uid
          and source_type::text in ('task', 'npc') and result = 'completed')
      when 'tasks_10' then (
        select count(*) from public.quest_log_entries where user_id = p_uid
          and source_type::text in ('task', 'npc') and result = 'completed') >= 10
      when 'tasks_50' then (
        select count(*) from public.quest_log_entries where user_id = p_uid
          and source_type::text in ('task', 'npc') and result = 'completed') >= 50
      when 'first_habit' then exists (
        select 1 from public.quest_log_entries where user_id = p_uid
          and source_type::text = 'habit' and result = 'completed')
      when 'streak_3' then public._activity_streak(p_uid, v_day, -300) >= 3
      when 'streak_7' then public._activity_streak(p_uid, v_day, -300) >= 7
      when 'streak_30' then public._activity_streak(p_uid, v_day, -300) >= 30
      when 'streak_100' then public._activity_streak(p_uid, v_day, -300) >= 100
      when 'focus_10' then (
        select count(*) from public.quest_log_entries where user_id = p_uid
          and source_type::text = 'dungeon' and result = 'completed') >= 10
      when 'chests_10' then (
        select count(*) from public.quest_log_entries where user_id = p_uid
          and source_type::text = 'daily_chest') >= 10
      when 'challenges_10' then (
        select count(*) from public.quest_log_entries where user_id = p_uid
          and source_type::text = 'challenge') >= 10
      when 'level_5' then coalesce((
        select level from public.character_stats where user_id = p_uid), 0) >= 5
      when 'league_up' then exists (
        select 1 from public.league_weeks where user_id = p_uid and last_result = 'promoted')
      else false
    end;
    if not v_ok then
      continue;
    end if;
    -- Unicidad (user_id, achievement_id): nunca se cobra dos veces.
    insert into public.user_achievements (user_id, achievement_id)
    values (p_uid, a.id) on conflict do nothing;
    get diagnostics v_count = row_count;
    if v_count = 0 then
      continue;
    end if;
    if a.reward_coins > 0 then
      perform public._award(p_uid, 'achievement', a.id, 0, a.reward_coins);
    end if;
    insert into public.notifications (user_id, type, category, event_key, title, message, sent_at)
    values (p_uid, 'motivational', 'achievement', 'achievement:' || a.id,
            'Nevi: ¡desbloqueaste «' || a.name || '»! 🏅',
            'Ganaste ' || a.reward_coins || ' Monedas. Míralo en Perfil → Logros.', now())
    on conflict (user_id, event_key) where event_key is not null do nothing;
  end loop;
end $$;

revoke all on function public._unlock_achievements(uuid) from public, anon, authenticated;

commit;

-- ===== 063_daily_xp_goal.sql =====
-- Migración 063 · Meta diaria de XP (requiere 048 y 052).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- Estilo Duolingo: el jugador elige su meta del día (30, 50 o 100 XP) en
-- Configuración. No es un sistema aparte: es el desafío del día «Gana N XP»
-- (052), que ahora usa la meta de cada quien; el cofre paga lo mismo. Nunca
-- baja de 30 (el valor de game_rules) para no abaratar el cofre.
--   · game_master_settings.daily_xp_goal (30 por defecto, el cliente la escribe).
--   · _challenge_target('xp') lee la meta del usuario de la sesión.
--   · settings_overview la devuelve (copia de 048 con un campo más).
--   · daily_goal(): XP de hoy y la meta, para el anillo del Inicio.

begin;

alter table public.game_master_settings
  add column if not exists daily_xp_goal integer not null default 30;
alter table public.game_master_settings
  drop constraint if exists game_master_settings_daily_xp_goal_check;
alter table public.game_master_settings
  add constraint game_master_settings_daily_xp_goal_check check (daily_xp_goal in (30, 50, 100));
grant update (daily_xp_goal) on public.game_master_settings to authenticated;

-- Llamada desde challenges_overview y claim_challenge, siempre con sesión.
create or replace function public._challenge_target(p_key text)
returns integer
language sql
stable
security definer
set search_path = ''
as $$
  select case
    when p_key = 'xp' then greatest(
      public.rule('challenge_xp_target')::integer,
      coalesce((select daily_xp_goal from public.game_master_settings
                where user_id = auth.uid()), 0))
    else public.rule('challenge_' || p_key || '_target')::integer
  end
$$;

create or replace function public.daily_goal()
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'xp', public._challenge_progress(auth.uid(), 'xp'),
    'goal', public._challenge_target('xp'))
  where auth.uid() is not null
$$;

revoke all on function public.daily_goal() from public, anon;
grant execute on function public.daily_goal() to authenticated;

create or replace function public.settings_overview()
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  select jsonb_build_object(
    'level', s.level,
    'current_xp', s.current_xp,
    'xp_to_next_level', s.xp_to_next_level,
    'difficulty', g.difficulty,
    'notification_daily_limit', g.notification_daily_limit,
    'silence_window_start', to_char(g.silence_window_start, 'HH24:MI'),
    -- 043: hora del resumen diario (null = la de notify_digest_hour).
    'digest_time', to_char(g.digest_time, 'HH24:MI'),
    'silence_window_end', to_char(g.silence_window_end, 'HH24:MI'),
    'critical_bypass_silence', g.critical_bypass_silence,
    -- 048: recordatorios del día (estilo Duolingo).
    'daily_reminders', coalesce(g.daily_reminders, true),
    -- 063: meta diaria de XP (el desafío «Gana N XP»).
    'daily_xp_goal', coalesce(g.daily_xp_goal, 30),
    'short_break_minutes', g.short_break_minutes,
    'long_break_minutes', g.long_break_minutes,
    'long_break_every_n_cycles', g.long_break_every_n_cycles,
    'difficulties', (
      select coalesce(jsonb_agg(jsonb_build_object(
        'level', dl.level,
        'xp_multiplier', dl.xp_multiplier,
        'hp_penalty_multiplier', dl.hp_penalty_multiplier,
        'coin_multiplier', dl.coin_multiplier
      ) order by dl.level), '[]'::jsonb)
      from public.difficulty_levels dl
    )
  )
  from public.profiles p
  left join public.character_stats s on s.user_id = p.id
  left join public.game_master_settings g on g.user_id = p.id
  where p.id = auth.uid()
$$;
revoke all on function public.settings_overview() from public, anon;
grant execute on function public.settings_overview() to authenticated;

commit;


-- ===== 064_league_notices.sql =====
-- Migración 064 · Avisos de Liga de Nevi (requiere 052).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- Cada día a las 08:00 de Colombia (13:00 UTC), para quien tuvo actividad en
-- las últimas 2 semanas (§9, como 061):
--   · Primera vuelta de la semana (el lunes): cómo cerró la semana pasada
--     (subió, se mantuvo o bajó), con ánimo. _league_current la cierra igual
--     que al abrir la pantalla de Liga.
--   · Miércoles a domingo: si va entre los 3 primeros (zona de ascenso), un
--     aviso por semana. Mismo puesto que muestra challenges_overview.

begin;

drop function if exists public._league_notices();
-- p_today solo para pruebas (el día de la semana); el cron no lo pasa.
create or replace function public._league_notices(p_today date default null)
returns integer
language plpgsql
security definer
set search_path = ''
set timezone to 'America/Bogota'
as $$
declare
  v_today date := coalesce(p_today, current_date);
  v_uid uuid;
  v_league public.league_weeks;
  v_xp integer;
  v_rank integer;
  v_title text;
  v_message text;
  v_key text;
  v_sent integer := 0;
begin
  for v_uid in
    select distinct user_id from public.quest_log_entries
    where occurred_at >= now() - interval '14 days'
  loop
    v_league := public._league_current(v_uid);
    v_title := null;
    v_key := 'league:result:' || v_league.week_start;
    if v_league.last_result is not null and not exists (
         select 1 from public.notifications where user_id = v_uid and event_key = v_key) then
      if v_league.last_result = 'promoted' then
        v_title := 'Nevi: ¡subiste de división! 🏆';
        v_message := 'Quedaste entre los 3 primeros la semana pasada. Nueva liga, nuevos rivales: ¡vamos!';
      elsif v_league.last_result = 'demoted' then
        v_title := 'Nevi: nueva semana, nueva oportunidad 🌱';
        v_message := 'Bajaste una división, y aquí se recupera rápido. Te acompaño.';
      else
        v_title := 'Nevi: sigues en tu división 💪';
        v_message := 'Esta semana vamos por el podio: los 3 primeros suben.';
      end if;
    elsif extract(isodow from v_today) >= 3 and v_league.division < 9 then
      v_xp := public._league_week_xp(v_uid, v_league.week_start);
      v_rank := public._league_rank(v_uid, v_league.week_start, v_league.division, v_xp,
        least(1, extract(epoch from (now() - v_league.week_start::timestamptz)) / (7 * 86400)));
      if v_xp > 0 and v_rank <= 3 then
        v_key := 'league:zone:' || v_league.week_start;
        v_title := 'Nevi: ¡vas #' || v_rank || ' en la Liga! 🏆';
        v_message := 'Si terminas la semana entre los 3 primeros, subes de división. ¡Sigue así!';
      end if;
    end if;
    if v_title is not null then
      insert into public.notifications (user_id, type, category, event_key, title, message, sent_at)
      values (v_uid, 'motivational', 'league', v_key, v_title, v_message, now())
      on conflict (user_id, event_key) where event_key is not null do nothing;
      v_sent := v_sent + 1;
    end if;
  end loop;
  return v_sent;
end $$;

revoke all on function public._league_notices(date) from public, anon, authenticated;

do $$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    perform cron.unschedule(jobid) from cron.job where jobname = 'lifequest_league';
    perform cron.schedule('lifequest_league', '0 13 * * *', 'select public._league_notices()');
  else
    raise notice 'Activa pg_cron (Database → Extensions) y vuelve a ejecutar esta migración.';
  end if;
end $$;

commit;

-- ===== 065_habit_plan.sql =====
-- Migración 065 · Plan de hábito de Nevi (requiere 011 y 039).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- La IA (Edge Function npc-mission en modo hábito) propone un plan al estilo
-- Atomic Habits / Tiny Habits: la versión mínima de 2 minutos, el disparador
-- («después de X, hago Y»), la recompensa y por qué importa. Para un mal
-- hábito: cómo evitar el disparador y con qué reemplazarlo.
--   · habits.plan jsonb {tiny, cue, reward, why} (null = sin plan).
--   · attach_habit_plan(hábito, plan): solo el dueño; recorta cada campo.
-- La app lo lee con el select de habits (RLS «own rows»).

begin;

alter table public.habits add column if not exists plan jsonb;

create or replace function public.attach_habit_plan(p_habit_id uuid, p_plan jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_plan jsonb;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  v_plan := jsonb_strip_nulls(jsonb_build_object(
    'tiny', nullif(left(trim(coalesce(p_plan ->> 'tiny', '')), 200), ''),
    'cue', nullif(left(trim(coalesce(p_plan ->> 'cue', '')), 200), ''),
    'reward', nullif(left(trim(coalesce(p_plan ->> 'reward', '')), 200), ''),
    'why', nullif(left(trim(coalesce(p_plan ->> 'why', '')), 300), '')));
  if v_plan ->> 'tiny' is null then
    raise exception 'invalid_plan' using errcode = '22023';
  end if;
  update public.habits set plan = v_plan
  where id = p_habit_id and user_id = auth.uid();
  if not found then
    raise exception 'habit_not_found' using errcode = 'P0002';
  end if;
  return v_plan;
end $$;

revoke all on function public.attach_habit_plan(uuid, jsonb) from public, anon;
grant execute on function public.attach_habit_plan(uuid, jsonb) to authenticated;

commit;


-- ===== 066_dungeon_loot_steps.sql =====
-- Migración 066 · El resumen de Foco cuenta la XP de los pasos (requiere 033 y 039).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- Error encontrado en el teléfono (2026-11-15): una tarea guiada de 25 XP
-- cerrada en Foco mostraba «5 XP» en el resumen. Cada paso paga su parte al
-- marcarse (source 'task_step', 039) y _dungeon_loot (033) solo sumaba ciclos
-- y el complete_task final, que paga lo que falta. La XP sí se cobraba bien:
-- solo el resumen de la sesión la mostraba incompleta.
-- Ahora suma también los pasos de las tareas de la mochila pagados durante la
-- sesión. «missions» sigue contando solo tareas completadas.

begin;

create or replace function public._dungeon_loot(p_session_id uuid)
returns table (xp bigint, coins bigint, missions bigint)
language sql
stable
security invoker
set search_path = ''
as $$
  with s as (
    select * from public.focus_sessions where id = p_session_id
  ),
  q as (
    select q.xp_awarded, q.coin_awarded, q.source_type
    from public.quest_log_entries q, s
    where q.user_id = s.user_id
      and (
        (q.source_type = 'dungeon'
         and q.source_id in (select r.id from public.dungeon_runs r where r.session_id = s.id))
        or
        (q.source_type in ('task', 'npc')
         and q.result = 'completed'
         and q.occurred_at >= s.started_at
         and q.occurred_at <= coalesce(s.ended_at, now())
         and q.source_id in (select f.task_id from public.focus_session_tasks f
                             where f.session_id = s.id))
        or
        -- 066: pasos de las tareas de la mochila pagados durante la sesión.
        (q.source_type = 'task_step'
         and q.occurred_at >= s.started_at
         and q.occurred_at <= coalesce(s.ended_at, now())
         and q.source_id in (select ts.id from public.task_steps ts
                             join public.focus_session_tasks f on f.task_id = ts.task_id
                             where f.session_id = s.id))
      )
  )
  select coalesce(sum(xp_awarded), 0),
         coalesce(sum(coin_awarded), 0),
         count(*) filter (where source_type in ('task', 'npc'))
  from q
$$;

commit;

-- ===== 067_adapt_task_guide.sql =====
-- Migración 067 · «Hablar con Nevi»: rehacer solo los pasos pendientes (requiere 039).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- Idea del usuario (2026-11-15): si un paso no aplica («no tengo escritorio»),
-- la persona se lo dice a Nevi y la IA rehace lo que falta. attach_task_guide
-- (039) se niega con un paso ya cobrado (guide_locked); esta función conserva
-- los pasos pagados (y su XP) y reemplaza solo los pendientes, a continuación.
-- toggle_task_step reparte la XP restante entre los pasos sin pagar, así que
-- el total de la tarea no cambia. Hasta 8 pasos en total.

begin;

create or replace function public.adapt_task_guide(p_task_id uuid, p_guide jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_task public.tasks;
  v_kept integer;
  v_steps jsonb;
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

  -- Pasos ya cobrados: se quedan y fijan desde dónde siguen los nuevos.
  select coalesce(max(position), 0) into v_kept
  from public.task_steps where task_id = p_task_id and paid_at is not null;
  v_steps := public._text_list(p_guide -> 'steps', 8 - v_kept, 300);
  if jsonb_array_length(v_steps) = 0 then
    raise exception 'invalid_guide' using errcode = '22023';
  end if;

  delete from public.task_steps where task_id = p_task_id and paid_at is null;
  insert into public.task_steps (task_id, user_id, position, title)
  select p_task_id, v_uid, v_kept + n, x
  from jsonb_array_elements_text(v_steps) with ordinality as t(x, n);

  update public.tasks set guide = jsonb_build_object(
    'objective', coalesce(
      nullif(left(trim(coalesce(p_guide ->> 'objective', '')), 400), ''),
      v_task.guide ->> 'objective'),
    'topic', v_task.guide ->> 'topic',
    'hints', public._text_list(p_guide -> 'hints', 4, 400),
    'search', public._text_list(p_guide -> 'search', 2, 120))
  where id = p_task_id;

  return public.task_detail(p_task_id);
end $$;

revoke all on function public.adapt_task_guide(uuid, jsonb) from public, anon;
grant execute on function public.adapt_task_guide(uuid, jsonb) to authenticated;

commit;


notify pgrst, 'reload schema';

-- ===== 068_focus_unified.sql =====
-- Migración 068 · Foco unificado: tiempo según la tarea, pasos dentro de Foco
-- y hábitos en la sesión (idea del usuario, 2026-11-16). Requiere 033, 039, 066.
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- 1. task_steps.minutes: Nevi estima cuánto toma cada paso (set_step_minutes).
-- 2. focus_session_habits: hábitos buenos de hoy dentro de la sesión.
-- 3. dungeon_runs.habit_id: un bloque puede ser de un hábito (sin tarea).
-- 4. start_dungeon y complete_dungeon_cycle aceptan hábitos (parámetros con
--    default: la app anterior las sigue llamando igual).
-- 5. dungeon_overview trae minutos estimados, el paso actual de cada tarea y
--    los hábitos (de la sesión y candidatos de hoy).

begin;

-- 1. Minutos por paso -------------------------------------------------------------
alter table public.task_steps add column if not exists minutes smallint
  check (minutes between 1 and 240);

-- Los pasos pendientes, en orden, reciben los minutos en el mismo orden.
create or replace function public.set_step_minutes(p_task_id uuid, p_minutes integer[])
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  update public.task_steps s set minutes = least(greatest(m.v, 1), 240)
  from (select id, row_number() over (order by position) as n
        from public.task_steps
        where task_id = p_task_id and user_id = auth.uid() and paid_at is null) p
  join unnest(p_minutes) with ordinality as m(v, n) on m.n = p.n
  where s.id = p.id and m.v is not null;
end $$;

-- 2. Hábitos en la sesión ---------------------------------------------------------
create table if not exists public.focus_session_habits (
  session_id uuid not null references public.focus_sessions (id) on delete cascade,
  habit_id uuid not null references public.habits (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  primary key (session_id, habit_id)
);
alter table public.focus_session_habits enable row level security;
drop policy if exists focus_session_habits_select_own on public.focus_session_habits;
create policy focus_session_habits_select_own on public.focus_session_habits
  for select using (user_id = auth.uid());
revoke all on public.focus_session_habits from anon, authenticated;
grant select on public.focus_session_habits to authenticated;

-- 3. Bloques de un hábito ---------------------------------------------------------
alter table public.dungeon_runs alter column task_id drop not null;
alter table public.dungeon_runs add column if not exists habit_id uuid
  references public.habits (id) on delete set null;

-- 4a. Empezar con tareas y/o hábitos ----------------------------------------------
drop function if exists public.start_dungeon(integer, integer, uuid[]);
create or replace function public.start_dungeon(
  p_total_minutes integer,
  p_cycle_minutes integer,
  p_task_ids uuid[],
  p_habit_ids uuid[] default null
)
returns uuid
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_tasks uuid[];
  v_habits uuid[];
  v_session uuid;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  if p_cycle_minutes is null or p_cycle_minutes not in (25, 30, 45)
     or p_total_minutes is null or p_total_minutes % 30 <> 0
     or p_total_minutes < p_cycle_minutes or p_total_minutes > 480 then
    raise exception 'invalid_duration' using errcode = '22023';
  end if;
  select array_agg(distinct x) into v_tasks from unnest(coalesce(p_task_ids, '{}')) x;
  select array_agg(distinct x) into v_habits from unnest(coalesce(p_habit_ids, '{}')) x;
  if v_tasks is null and v_habits is null then
    raise exception 'no_tasks' using errcode = '22023';
  end if;
  if coalesce(cardinality(v_tasks), 0) + coalesce(cardinality(v_habits), 0)
     > public.rule('dungeon_max_tasks') then
    raise exception 'session_task_limit' using errcode = 'P0001';
  end if;
  if v_tasks is not null and (select count(*) from public.tasks
      where id = any (v_tasks) and user_id = v_uid
        and status in ('pending', 'in_progress', 'delegated')) <> cardinality(v_tasks) then
    raise exception 'task_not_found' using errcode = 'P0002';
  end if;
  if v_habits is not null and (select count(*) from public.habits
      where id = any (v_habits) and user_id = v_uid and type = 'good') <> cardinality(v_habits) then
    raise exception 'habit_not_found' using errcode = 'P0002';
  end if;

  insert into public.focus_sessions (user_id, total_minutes, cycle_minutes)
  values (v_uid, p_total_minutes, p_cycle_minutes)
  returning id into v_session;
  if v_tasks is not null then
    insert into public.focus_session_tasks (session_id, task_id)
    select v_session, unnest(v_tasks);
  end if;
  -- La tabla no tiene grant de insert: lo hace una función definer aparte.
  perform public._add_session_habits(v_session, v_habits);
  return v_session;
end $$;

create or replace function public._add_session_habits(p_session_id uuid, p_habits uuid[])
returns void
language sql
security definer
set search_path = ''
as $$
  insert into public.focus_session_habits (session_id, habit_id, user_id)
  select s.id, h.id, s.user_id
  from public.focus_sessions s
  join public.habits h on h.user_id = s.user_id and h.type = 'good'
  where s.id = p_session_id and s.user_id = auth.uid()
    and h.id = any (coalesce(p_habits, '{}'))
  on conflict do nothing;
$$;
-- start_dungeon (invoker) la llama como el usuario; solo inserta en su sesión
-- y con sus hábitos buenos.
revoke all on function public._add_session_habits(uuid, uuid[]) from public, anon;
grant execute on function public._add_session_habits(uuid, uuid[]) to authenticated;

-- 4b. Cobrar un bloque de una tarea o de un hábito (cuerpo de 008) -----------------
drop function if exists public.complete_dungeon_cycle(uuid, uuid);
create or replace function public.complete_dungeon_cycle(
  p_session_id uuid,
  p_task_id uuid default null,
  p_habit_id uuid default null
)
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
  if p_task_id is not null then
    if not exists (select 1 from public.focus_session_tasks
                   where session_id = p_session_id and task_id = p_task_id) then
      raise exception 'task_not_in_session' using errcode = '22023';
    end if;
  elsif p_habit_id is null or not exists (select 1 from public.focus_session_habits
                   where session_id = p_session_id and habit_id = p_habit_id) then
    raise exception 'task_not_in_session' using errcode = '22023';
  end if;
  -- Un ciclo no puede durar menos que su duración desde el inicio de la sesión.
  select count(*) + 1 into v_cycle from public.dungeon_runs where session_id = p_session_id;
  if v_cycle > floor(v_session.total_minutes::numeric / v_session.cycle_minutes) then
    raise exception 'session_cycles_exhausted' using errcode = '22023';
  end if;
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
  select coalesce((select skill_id from public.tasks where id = p_task_id),
                  (select skill_id from public.habits where id = p_habit_id))
  into v_skill;

  insert into public.dungeon_runs (session_id, task_id, habit_id, cycle_number, completed, ended_at)
  values (p_session_id, p_task_id, case when p_task_id is null then p_habit_id end,
          v_cycle, true, now())
  returning id into v_run;
  return public._award(v_uid, 'dungeon', v_run, floor(v_xp)::integer,
    round(public.rule('dungeon_cycle_xp') * public.rule('coin_ratio'))::integer, v_skill)
    || jsonb_build_object('cycle', v_cycle);
end $$;

-- 5. El tablero de Foco (cuerpo de 033 + minutos, paso actual y hábitos) ------------
create or replace function public.dungeon_overview()
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  with s as (
    select * from public.focus_sessions
    where user_id = auth.uid() and status in ('active', 'paused')
    order by started_at desc limit 1
  ),
  runs as (
    select r.* from public.dungeon_runs r join s on s.id = r.session_id
  ),
  today as (select (now() at time zone 'America/Bogota')::date as d),
  -- Por tarea: minutos de lo que falta (null si Nevi no los estimó) y el paso actual.
  steps as (
    select ts.task_id,
           count(*) filter (where ts.done_at is null) as pending,
           count(*) as total,
           sum(ts.minutes) filter (where ts.done_at is null) as minutes,
           (array_agg(jsonb_build_object('id', ts.id, 'title', ts.title,
                      'position', ts.position, 'minutes', ts.minutes)
                      order by ts.position) filter (where ts.done_at is null))[1] as current
    from public.task_steps ts where ts.user_id = auth.uid()
    group by ts.task_id
  ),
  hab as (
    select h.id, h.name,
           exists (select 1 from public.habit_records r, today
                   where r.habit_id = h.id and r.completed_on = today.d) as done
    from public.habits h, today
    where h.user_id = auth.uid() and h.type = 'good'
      and (h.frequency = 'daily' or extract(dow from today.d)::int = any (h.specific_days))
  )
  select jsonb_build_object(
    'session', (
      select jsonb_build_object(
        'id', s.id,
        'total_minutes', s.total_minutes,
        'cycle_minutes', s.cycle_minutes,
        'started_at', s.started_at,
        'cycles_done', (select count(*) from runs),
        'xp_earned', l.xp,
        'coins_earned', l.coins,
        'missions_done', l.missions,
        'focus_minutes', (select count(*) from runs) * s.cycle_minutes,
        'tasks', coalesce((
          select jsonb_agg(jsonb_build_object(
            'id', t.id,
            'title', t.title,
            'done', t.status = 'completed',
            'cycles', (select count(*) from runs where runs.task_id = t.id),
            'minutes', st.minutes,
            'step_count', coalesce(st.total, 0),
            'step', case when t.status = 'completed' then null else st.current end
          ) order by t.created_at)
          from public.focus_session_tasks f join public.tasks t on t.id = f.task_id
          left join steps st on st.task_id = t.id
          where f.session_id = s.id
        ), '[]'::jsonb),
        'habits', coalesce((
          select jsonb_agg(jsonb_build_object(
            'id', h.id,
            'title', h.name,
            'done', exists (select 1 from public.habit_records r, today
                            where r.habit_id = h.id and r.completed_on = today.d),
            'cycles', (select count(*) from runs where runs.habit_id = h.id)
          ) order by h.created_at)
          from public.focus_session_habits fh join public.habits h on h.id = fh.habit_id
          where fh.session_id = s.id
        ), '[]'::jsonb)
      )
      from s, public._dungeon_loot(s.id) l
    ),
    'candidates', coalesce((
      select jsonb_agg(jsonb_build_object('id', c.id, 'title', c.title, 'bucket', c.bucket,
                                          'minutes', st.minutes,
                                          'step_count', coalesce(st.pending, 0))
                       order by c.bucket_order, c.due_date nulls last)
      from (select * from public.v_daily_highlight
            order by bucket_order, due_date nulls last limit 30) c
      left join steps st on st.task_id = c.id
    ), '[]'::jsonb),
    -- Hábitos buenos que tocan hoy y aún no se cumplen.
    'habit_candidates', coalesce((
      select jsonb_agg(jsonb_build_object('id', hab.id, 'title', hab.name) order by hab.name)
      from hab where not hab.done
    ), '[]'::jsonb),
    'max_tasks', public.rule('dungeon_max_tasks')::integer,
    'cycle_xp', public.rule('dungeon_cycle_xp')::integer,
    -- RF-067: descansos que el jugador eligió en Configuración (016).
    'breaks', (
      select jsonb_build_object(
        'short_minutes', g.short_break_minutes,
        'long_minutes', g.long_break_minutes,
        'long_every_n_cycles', g.long_break_every_n_cycles
      )
      from public.game_master_settings g where g.user_id = auth.uid()
    )
  )
$$;

-- Permisos ---------------------------------------------------------------------
do $$
declare f text;
begin
  foreach f in array array['public.dungeon_overview()',
    'public.start_dungeon(integer, integer, uuid[], uuid[])',
    'public.complete_dungeon_cycle(uuid, uuid, uuid)',
    'public.set_step_minutes(uuid, integer[])'] loop
    execute format('revoke all on function %s from public, anon', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;

commit;

notify pgrst, 'reload schema';

-- ===== 069_dungeon_loot_habits.sql =====
-- Migración 069 · El botín de Foco cuenta los hábitos cumplidos en la sesión
-- (requiere 066 y 068). Ejecutar una vez en Supabase → SQL Editor. Se puede
-- volver a ejecutar.
--
-- Prueba en el teléfono (2026-11-16): un hábito marcado dentro de Foco subía
-- la XP del personaje, pero «Recompensas de la sesión» y el resumen no lo
-- sumaban. Ahora _dungeon_loot (cuerpo de 066) suma también los hábitos de la
-- sesión (focus_session_habits) cobrados mientras estaba abierta.

begin;

create or replace function public._dungeon_loot(p_session_id uuid)
returns table (xp bigint, coins bigint, missions bigint)
language sql
stable
security invoker
set search_path = ''
as $$
  with s as (
    select * from public.focus_sessions where id = p_session_id
  ),
  q as (
    select q.xp_awarded, q.coin_awarded, q.source_type
    from public.quest_log_entries q, s
    where q.user_id = s.user_id
      and (
        (q.source_type = 'dungeon'
         and q.source_id in (select r.id from public.dungeon_runs r where r.session_id = s.id))
        or
        (q.source_type in ('task', 'npc')
         and q.result = 'completed'
         and q.occurred_at >= s.started_at
         and q.occurred_at <= coalesce(s.ended_at, now())
         and q.source_id in (select f.task_id from public.focus_session_tasks f
                             where f.session_id = s.id))
        or
        -- 066: pasos de las tareas de la mochila pagados durante la sesión.
        (q.source_type = 'task_step'
         and q.occurred_at >= s.started_at
         and q.occurred_at <= coalesce(s.ended_at, now())
         and q.source_id in (select ts.id from public.task_steps ts
                             join public.focus_session_tasks f on f.task_id = ts.task_id
                             where f.session_id = s.id))
        or
        -- 069: hábitos de la sesión cumplidos mientras estaba abierta.
        (q.source_type = 'habit'
         and q.occurred_at >= s.started_at
         and q.occurred_at <= coalesce(s.ended_at, now())
         and q.source_id in (select fh.habit_id from public.focus_session_habits fh
                             where fh.session_id = s.id))
      )
  )
  select coalesce(sum(xp_awarded), 0),
         coalesce(sum(coin_awarded), 0),
         count(*) filter (where source_type in ('task', 'npc'))
  from q
$$;

commit;

-- ===== 070_daily_xp_goal_free.sql =====
-- Migración 070 · Meta diaria de XP libre (requiere 063). Ejecutar una vez en
-- Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- Pedido del usuario (2026-11-16): elegir su propia meta (p. ej. 60), no solo
-- 30, 50 o 100. La meta es un objetivo, nunca un tope de XP. El mínimo sigue
-- en 30 para no abaratar el cofre del desafío «Gana N XP» (063); de 10 en 10
-- hasta 500.

begin;

alter table public.game_master_settings
  drop constraint if exists game_master_settings_daily_xp_goal_check;
alter table public.game_master_settings
  add constraint game_master_settings_daily_xp_goal_check
  check (daily_xp_goal between 30 and 500 and daily_xp_goal % 10 = 0);

commit;

notify pgrst, 'reload schema';

-- ===== 071_habit_time.sql =====
-- Migración 071 · Hora para cada hábito con su aviso (requiere 051 y 058).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- Mejora 1 del plan del usuario (2026-11-16): «Leer después de cenar a las
-- 8 p. m.» (intención de implementación). La persona elige una hora por
-- hábito y, si a esa hora aún no lo cumplió, Nevi le avisa una vez.
-- 1. habits.reminder_time (hora local de Colombia, null = sin hora).
-- 2. set_habit_time(): la pone o la quita (solo el dueño, solo hábitos buenos).
-- 3. _habit_time_reminders(): aviso crítico «Nevi: es hora de …» dentro de la
--    hora siguiente a la elegida (el cron de push corre cada 5 min, 054).
-- 4. _generate_reminders (058) pasa a llamarse _generate_daily_reminders y la
--    nueva _generate_reminders llama a las dos: los 5 recordatorios del día y
--    los de cada hábito. Quien la llamaba (050) no cambia.
-- 5. habits_overview (cuerpo de 051) devuelve reminder_time.

begin;

-- 1. Hora del hábito ----------------------------------------------------------
alter table public.habits add column if not exists reminder_time time;

-- 2. Poner o quitar la hora ----------------------------------------------------
create or replace function public.set_habit_time(p_habit_id uuid, p_time time)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  update public.habits set reminder_time = p_time
  where id = p_habit_id and user_id = auth.uid() and type = 'good';
  if not found then
    raise exception 'habit_not_found' using errcode = 'P0002';
  end if;
end $$;
revoke all on function public.set_habit_time(uuid, time) from public, anon;
grant execute on function public.set_habit_time(uuid, time) to authenticated;

-- 3. Aviso a la hora de cada hábito ----------------------------------------------
create or replace function public._habit_time_reminders(p_uid uuid, p_day date, p_time time)
returns void
language sql
security definer
set search_path = ''
set timezone to 'America/Bogota'
as $$
  insert into public.notifications (user_id, type, category, event_key, title, message, sent_at)
  select p_uid, 'critical', 'habit_time',
         'habit_time:' || h.id || ':' || p_day,
         'Nevi: es hora de «' || left(h.name, 60) || '» ⏰',
         'Lo planeaste para las ' || to_char(h.reminder_time, 'FMHH12:MI') ||
           case when h.reminder_time < time '12:00' then ' a. m.' else ' p. m.' end ||
           '. Hazlo ahora y suma a tu racha.',
         now()
  from public.habits h
  where h.user_id = p_uid and h.type = 'good' and h.reminder_time is not null
    and p_time >= h.reminder_time and p_time - h.reminder_time < interval '1 hour'
    and (h.frequency = 'daily' or extract(dow from p_day)::int = any (h.specific_days))
    and not exists (select 1 from public.habit_records r
                    where r.habit_id = h.id and r.completed_on = p_day)
  on conflict (user_id, event_key) where event_key is not null do nothing;
$$;
revoke all on function public._habit_time_reminders(uuid, date, time) from public, anon, authenticated;

-- 4. Los recordatorios del día y los de cada hábito -------------------------------
do $$
begin
  if to_regprocedure('public._generate_daily_reminders(uuid, date, time)') is null then
    alter function public._generate_reminders(uuid, date, time)
      rename to _generate_daily_reminders;
  end if;
end $$;

create or replace function public._generate_reminders(p_uid uuid, p_day date, p_time time)
returns void
language plpgsql
security definer
set search_path = ''
set timezone to 'America/Bogota'
as $$
begin
  -- Primero el del hábito: así el «hace poco llegó otro aviso» (048) no lo tapa.
  perform public._habit_time_reminders(p_uid, p_day, p_time);
  perform public._generate_daily_reminders(p_uid, p_day, p_time);
end $$;
revoke all on function public._generate_reminders(uuid, date, time) from public, anon, authenticated;

-- 5. habits_overview con la hora (cuerpo de 051) -----------------------------------
create or replace function public.habits_overview(p_day date)
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  with week as (
    select generate_series(p_day - 6, p_day, interval '1 day')::date as day
  ),
  h as (
    select h.*,
           h.frequency = 'daily' or extract(dow from p_day)::int = any (h.specific_days) as scheduled_today
    from public.habits h
  ),
  -- Días de la semana en que tocaba cada hábito bueno (desde que existe).
  scheduled as (
    select h.id, w.day
    from h cross join week w
    where h.type = 'good' and w.day >= h.created_at::date
      and (h.frequency = 'daily' or extract(dow from w.day)::int = any (h.specific_days))
  )
  select jsonb_build_object(
    'habits', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', h.id,
        'name', h.name,
        'priority', h.priority,
        -- 071: hora elegida para el hábito (hora local, «HH:MM» o null).
        'reminder_time', to_char(h.reminder_time, 'HH24:MI'),
        'type', h.type,
        'frequency', h.frequency,
        'specific_days', coalesce(to_jsonb(h.specific_days), '[]'::jsonb),
        'skill_name', s.name,
        'hp_penalty', h.hp_penalty,
        'current_streak', coalesce(h.current_streak, 0),
        'best_streak', coalesce(h.best_streak, 0),
        'scheduled_today', h.scheduled_today,
        'done_today', exists (select 1 from public.habit_records r
                              where r.habit_id = h.id and r.completed_on = p_day),
        'today_count', (select count(*) from public.habit_records r
                        where r.habit_id = h.id and r.completed_on = p_day),
        'week', (select jsonb_agg(exists (select 1 from public.habit_records r
                                          where r.habit_id = h.id and r.completed_on = w.day)
                                  order by w.day)
                 from week w)
      ) order by h.type, h.created_at)
      from h left join public.skills s on s.id = h.skill_id
    ), '[]'::jsonb),
    'week_xp', (
      select coalesce(sum(q.xp_awarded), 0) from public.quest_log_entries q
      where q.source_type = 'habit' and q.occurred_at >= (p_day - 6)::timestamptz
    ),
    'week_done', (
      select count(*) from scheduled sc
      where exists (select 1 from public.habit_records r
                    where r.habit_id = sc.id and r.completed_on = sc.day)
    ),
    'week_scheduled', (select count(*) from scheduled),
    'bad_free_days', (
      select count(*) from week w
      where not exists (select 1 from public.habit_records r join h on h.id = r.habit_id
                        where h.type = 'bad' and r.completed_on = w.day)
    ),
    'month_days', coalesce((
      select jsonb_agg(distinct extract(day from r.completed_on)::int)
      from public.habit_records r join h on h.id = r.habit_id
      where h.type = 'good'
        and r.completed_on >= date_trunc('month', p_day)::date and r.completed_on <= p_day
    ), '[]'::jsonb),
    -- 042: Estadísticas de crecimiento y mapa de calor de Habitos.dc.html.
    'month_heat', coalesce((
      select jsonb_object_agg(d, n) from (
        select extract(day from r.completed_on)::int as d, count(*) as n
        from public.habit_records r join h on h.id = r.habit_id
        where h.type = 'good'
          and r.completed_on >= date_trunc('month', p_day)::date and r.completed_on <= p_day
        group by 1) x
    ), '{}'::jsonb),
    'month_done', (
      select count(*) from public.habit_records r join h on h.id = r.habit_id
      where h.type = 'good'
        and r.completed_on >= date_trunc('month', p_day)::date and r.completed_on <= p_day
    ),
    'year_done', (
      select count(*) from public.habit_records r join h on h.id = r.habit_id
      where h.type = 'good'
        and r.completed_on >= date_trunc('year', p_day)::date and r.completed_on <= p_day
    ),
    'skills', coalesce((
      select jsonb_agg(jsonb_build_object('id', id, 'name', name) order by created_at)
      from public.skills
    ), '[]'::jsonb)
  )
$$;
revoke all on function public.habits_overview(date) from public, anon;
grant execute on function public.habits_overview(date) to authenticated;

commit;

-- ===== 072_real_league.sql =====
-- Migración 072 · Liga con personas reales y premios al top 3 (requiere 052, 057 y 064).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- Decisión del usuario (2026-11-16): en la Liga solo aparecen personas
-- registradas que usan LifeQuest, nada de rivales simulados. Sigue como
-- Duolingo: 10 divisiones, zona de ascenso y de descenso, semana de lunes a
-- domingo (America/Bogota).
--
--   1. Grupo = quienes tienen fila en league_weeks esa semana y en esa
--      división. La fila se crea al abrir Desafíos o con el cron diario de
--      064 para quien tuvo actividad en 14 días: solo entra gente activa.
--      shortcut: un grupo por división, sin tope; con cientos de usuarios
--      partirlo en grupos de 30 (como Duolingo).
--   2. Nombre visible: solo el nombre y la inicial del apellido («Juan G.»),
--      nunca el correo ni el id (privacidad, OWASP M6).
--   3. Al cerrar la semana (_league_current): suben los 3 primeros con XP;
--      bajan los 3 últimos si el grupo tiene 7 o más, y quien hizo 0 XP.
--      Con menos de 2 personas con XP nadie sube ni cobra premio.
--   4. Premios (reglas provisionales en game_rules): 1.º 50 Monedas y un Pase
--      de Recuperación, 2.º 35 Monedas, 3.º 20 Monedas. Se pagan con _award
--      (fuente 'league', fuera de la racha diaria) y Nevi avisa. Caben bajo las
--      50 Monedas completas del día: el cron de 064 (08:00) los paga el lunes.

alter type public.quest_source add value if not exists 'league';

begin;

insert into public.game_rules (key, value, provisional, note) values
  ('league_prize_1', 50, true, 'Monedas del 1.º de la Liga (y un Pase de Recuperación)'),
  ('league_prize_2', 35, true, 'Monedas del 2.º de la Liga'),
  ('league_prize_3', 20, true, 'Monedas del 3.º de la Liga')
on conflict (key) do nothing;

-- Puesto con que cerró la semana anterior (para mostrar el premio).
alter table public.league_weeks add column if not exists last_rank smallint;

drop function if exists public._league_rival(uuid, date, integer, integer);

-- Personas del grupo con su XP de la semana.
create or replace function public._league_players(p_week date, p_division integer)
returns table (user_id uuid, name text, xp integer)
language sql
stable
security definer
set search_path = ''
as $$
  select w.user_id,
         coalesce(nullif(trim(
           split_part(trim(p.display_name), ' ', 1) ||
           case when split_part(trim(p.display_name), ' ', 2) <> ''
                then ' ' || upper(left(split_part(trim(p.display_name), ' ', 2), 1)) || '.'
                else '' end), ''), 'Aventurero'),
         public._league_week_xp(w.user_id, p_week)
  from public.league_weeks w
  join public.profiles p on p.id = w.user_id
  where w.week_start = p_week and w.division = p_division
$$;

-- Puesto (1 = primero) de quien tiene [p_xp]; empate = mismo puesto.
-- Misma firma que en 052 (la usa 064); p_fraction ya no se usa.
create or replace function public._league_rank(
  p_uid uuid, p_week date, p_division integer, p_xp integer, p_fraction numeric)
returns integer
language sql
stable
security definer
set search_path = ''
as $$
  select 1 + count(*)::integer
  from public._league_players(p_week, p_division) g
  where g.user_id <> p_uid and g.xp > p_xp
$$;

-- Fila de esta semana; si falta, cierra la última semana jugada, sube o baja
-- y paga el premio del top 3 una sola vez (solo al crear la fila).
create or replace function public._league_current(p_uid uuid)
returns public.league_weeks
language plpgsql
security definer
set search_path = ''
set timezone to 'America/Bogota'
as $$
declare
  v_week date := date_trunc('week', current_date)::date;
  v_row public.league_weeks;
  v_prev public.league_weeks;
  v_xp integer;
  v_rank integer;
  v_size integer;
  v_active integer;
  v_division integer := 0;
  v_result text;
  v_coins integer;
begin
  select * into v_row from public.league_weeks where user_id = p_uid and week_start = v_week;
  if found then
    return v_row;
  end if;
  select * into v_prev from public.league_weeks
  where user_id = p_uid and week_start < v_week order by week_start desc limit 1;
  if found then
    v_xp := public._league_week_xp(p_uid, v_prev.week_start);
    v_rank := public._league_rank(p_uid, v_prev.week_start, v_prev.division, v_xp, 1);
    select count(*), count(*) filter (where g.xp > 0) into v_size, v_active
    from public._league_players(v_prev.week_start, v_prev.division) g;
    v_division := v_prev.division;
    v_result := 'stayed';
    if v_xp > 0 and v_rank <= 3 and v_active >= 2 and v_division < 9 then
      v_division := v_division + 1;
      v_result := 'promoted';
    elsif v_division > 0 and (v_xp = 0 or (v_size >= 7 and v_rank > v_size - 3)) then
      v_division := v_division - 1;
      v_result := 'demoted';
    end if;
  end if;

  insert into public.league_weeks (user_id, week_start, division, last_result, last_rank)
  values (p_uid, v_week, v_division, v_result, v_rank)
  on conflict (user_id, week_start) do nothing
  returning * into v_row;

  -- Premio: solo quien creó la fila (nunca dos veces) y con rivales reales.
  if v_row.user_id is not null and v_xp > 0 and v_rank <= 3 and v_active >= 2 then
    v_coins := public.rule('league_prize_' || v_rank)::integer;
    perform public._award(p_uid, 'league', gen_random_uuid(), 0, v_coins);
    if v_rank = 1 then
      insert into public.recovery_passes (user_id) values (p_uid);
    end if;
    insert into public.notifications (user_id, type, category, event_key, title, message, sent_at)
    values (p_uid, 'motivational', 'league', 'league:prize:' || v_prev.week_start,
      'Nevi: ¡quedaste #' || v_rank || ' en la Liga! 🏆',
      'Tu premio ya está en tu bolsa: +' || v_coins || ' Monedas'
        || case when v_rank = 1 then ' y un Pase de Recuperación' else '' end
        || '. ¡Gracias por tu constancia!', now())
    on conflict (user_id, event_key) where event_key is not null do nothing;
  end if;

  if v_row.user_id is null then
    select * into v_row from public.league_weeks where user_id = p_uid and week_start = v_week;
  end if;
  return v_row;
end $$;

create or replace function public.challenges_overview()
returns jsonb
language plpgsql
security definer
set search_path = ''
set timezone to 'America/Bogota'
as $$
declare
  v_uid uuid := auth.uid();
  v_league public.league_weeks;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  v_league := public._league_current(v_uid);

  return jsonb_build_object(
    'daily', (
      select jsonb_agg(jsonb_build_object(
        'key', k,
        'progress', public._challenge_progress(v_uid, k),
        'target', public._challenge_target(k),
        'coins', public.rule('challenge_coins'),
        'claimed', public._challenge_claimed(v_uid, k)) order by o)
      from unnest(array['xp', 'tasks', 'focus']) with ordinality as t(k, o)),
    'month', jsonb_build_object(
      'progress', public._challenge_month_points(v_uid),
      'target', public.rule('challenge_month_target'),
      'coins', public.rule('challenge_month_coins'),
      'claimed', public._challenge_claimed(v_uid, 'month'),
      'days_left', (date_trunc('month', current_date) + interval '1 month')::date - current_date),
    'league', jsonb_build_object(
      'division', v_league.division,
      'last_result', v_league.last_result,
      'last_rank', v_league.last_rank,
      'days_left', v_league.week_start + 7 - current_date,
      'xp', public._league_week_xp(v_uid, v_league.week_start),
      'prizes', jsonb_build_array(public.rule('league_prize_1'),
        public.rule('league_prize_2'), public.rule('league_prize_3')),
      -- Las demás personas del grupo (la app agrega «Tú»). Sin ids.
      'rivals', coalesce((
        select jsonb_agg(jsonb_build_object('name', g.name, 'xp', g.xp) order by g.xp desc)
        from public._league_players(v_league.week_start, v_league.division) g
        where g.user_id <> v_uid), '[]'::jsonb))
  );
end $$;

revoke all on function public._league_players(date, integer) from public, anon, authenticated;
revoke all on function public._league_rank(uuid, date, integer, integer, numeric) from public, anon, authenticated;
revoke all on function public._league_current(uuid) from public, anon, authenticated;
revoke all on function public.challenges_overview() from public, anon;
grant execute on function public.challenges_overview() to authenticated;

commit;

notify pgrst, 'reload schema';
