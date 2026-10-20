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
