-- Exportación del esquema DESPLEGADO en Supabase (proyecto admyvhbfxnitcwedywak),
-- tomada del visualizador de esquema el 2026-10-17.
--
-- Corresponde a la v1 (31 tablas): NO es el schema.sql v2 (33 tablas, 18 enums,
-- 2 vistas) que CLAUDE.md declara fuente de verdad. Diferencias detectadas:
--   - Faltan habits.current_streak / best_streak, habit_records.hp_change y
--     notifications.event_key / category / digest_slot.
--   - Faltan las tablas user_market_selection y notification_category_state.
--   - Faltan las vistas v_daily_highlight y v_user_store.
--   - character_stats.is_weakened es un boolean normal, no columna generada.
--   - market_items aún tiene user_id (autorecompensas de texto libre, eliminadas).
-- No incluye enums, triggers, funciones ni políticas RLS.
--
-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.profiles (
  id uuid NOT NULL,
  display_name text,
  character_class text,
  identity_statement text,
  avatar_url text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT profiles_pkey PRIMARY KEY (id),
  CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id)
);
CREATE TABLE public.character_stats (
  user_id uuid NOT NULL,
  level integer NOT NULL DEFAULT 1,
  current_xp integer NOT NULL DEFAULT 0,
  xp_to_next_level integer NOT NULL DEFAULT 100,
  coins integer NOT NULL DEFAULT 0,
  hp_current integer NOT NULL DEFAULT 100,
  hp_max integer NOT NULL DEFAULT 100,
  is_weakened boolean NOT NULL DEFAULT false,
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT character_stats_pkey PRIMARY KEY (user_id),
  CONSTRAINT character_stats_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.vision_boards (
  user_id uuid NOT NULL,
  content text,
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT vision_boards_pkey PRIMARY KEY (user_id),
  CONSTRAINT vision_boards_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.skills (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  name text NOT NULL,
  level integer NOT NULL DEFAULT 1,
  current_xp integer NOT NULL DEFAULT 0,
  xp_to_next_level integer NOT NULL DEFAULT 100,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT skills_pkey PRIMARY KEY (id),
  CONSTRAINT skills_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.brain_dump_entries (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  content text NOT NULL,
  status USER-DEFINED NOT NULL DEFAULT 'pending'::brain_dump_status,
  converted_to_type USER-DEFINED,
  converted_to_id uuid,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT brain_dump_entries_pkey PRIMARY KEY (id),
  CONSTRAINT brain_dump_entries_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.goals (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  skill_id uuid,
  title text NOT NULL,
  smart_specific text,
  smart_measurable text,
  smart_achievable text,
  smart_relevant text,
  smart_timebound text,
  start_date date,
  due_date date,
  status USER-DEFINED NOT NULL DEFAULT 'not_started'::objective_status,
  boss_max_hp integer NOT NULL DEFAULT 100,
  boss_current_hp integer NOT NULL DEFAULT 100,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT goals_pkey PRIMARY KEY (id),
  CONSTRAINT goals_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id),
  CONSTRAINT goals_skill_id_fkey FOREIGN KEY (skill_id) REFERENCES public.skills(id)
);
CREATE TABLE public.projects (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  goal_id uuid,
  skill_id uuid,
  title text NOT NULL,
  description text,
  start_date date,
  end_date date,
  urgency USER-DEFINED NOT NULL DEFAULT 'low'::urgency_level,
  status USER-DEFINED NOT NULL DEFAULT 'not_started'::objective_status,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT projects_pkey PRIMARY KEY (id),
  CONSTRAINT projects_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id),
  CONSTRAINT projects_goal_id_fkey FOREIGN KEY (goal_id) REFERENCES public.goals(id),
  CONSTRAINT projects_skill_id_fkey FOREIGN KEY (skill_id) REFERENCES public.skills(id)
);
CREATE TABLE public.npcs (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  name text NOT NULL,
  avatar_url text,
  banner_url text,
  noble_mission text,
  skill_id uuid NOT NULL,
  frequency USER-DEFINED NOT NULL,
  last_mission_at timestamp with time zone,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT npcs_pkey PRIMARY KEY (id),
  CONSTRAINT npcs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id),
  CONSTRAINT npcs_skill_id_fkey FOREIGN KEY (skill_id) REFERENCES public.skills(id)
);
CREATE TABLE public.tasks (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  project_id uuid,
  goal_id uuid,
  skill_id uuid,
  npc_id uuid,
  parent_task_id uuid,
  title text NOT NULL,
  description text,
  category text,
  priority USER-DEFINED NOT NULL DEFAULT 'low'::urgency_level,
  due_date timestamp with time zone,
  estimated_minutes integer,
  difficulty USER-DEFINED NOT NULL DEFAULT 'medium'::difficulty_scale,
  status USER-DEFINED NOT NULL DEFAULT 'pending'::task_status,
  tags ARRAY NOT NULL DEFAULT '{}'::text[],
  xp_reward integer NOT NULL DEFAULT 0,
  coin_reward integer NOT NULL DEFAULT 0,
  repeat_rule text,
  delegated_to text,
  source USER-DEFINED NOT NULL DEFAULT 'manual'::task_source,
  completed_at timestamp with time zone,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT tasks_pkey PRIMARY KEY (id),
  CONSTRAINT tasks_parent_task_id_fkey FOREIGN KEY (parent_task_id) REFERENCES public.tasks(id),
  CONSTRAINT tasks_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id),
  CONSTRAINT tasks_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id),
  CONSTRAINT tasks_goal_id_fkey FOREIGN KEY (goal_id) REFERENCES public.goals(id),
  CONSTRAINT tasks_skill_id_fkey FOREIGN KEY (skill_id) REFERENCES public.skills(id),
  CONSTRAINT tasks_npc_id_fkey FOREIGN KEY (npc_id) REFERENCES public.npcs(id)
);
CREATE TABLE public.resources (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  npc_id uuid,
  title text NOT NULL,
  file_url text NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT resources_pkey PRIMARY KEY (id),
  CONSTRAINT resources_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id),
  CONSTRAINT resources_npc_id_fkey FOREIGN KEY (npc_id) REFERENCES public.npcs(id)
);
CREATE TABLE public.calendar_events (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  title text NOT NULL,
  event_date timestamp with time zone NOT NULL,
  priority USER-DEFINED NOT NULL DEFAULT 'low'::urgency_level,
  contact text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT calendar_events_pkey PRIMARY KEY (id),
  CONSTRAINT calendar_events_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.habits (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  skill_id uuid,
  name text NOT NULL,
  type USER-DEFINED NOT NULL,
  frequency USER-DEFINED NOT NULL DEFAULT 'daily'::habit_frequency,
  specific_days ARRAY,
  xp_reward integer NOT NULL DEFAULT 0,
  coin_reward integer NOT NULL DEFAULT 0,
  hp_penalty integer NOT NULL DEFAULT 0,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT habits_pkey PRIMARY KEY (id),
  CONSTRAINT habits_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id),
  CONSTRAINT habits_skill_id_fkey FOREIGN KEY (skill_id) REFERENCES public.skills(id)
);
CREATE TABLE public.habit_records (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  habit_id uuid NOT NULL,
  user_id uuid NOT NULL,
  completed_on date NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT habit_records_pkey PRIMARY KEY (id),
  CONSTRAINT habit_records_habit_id_fkey FOREIGN KEY (habit_id) REFERENCES public.habits(id),
  CONSTRAINT habit_records_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.focus_sessions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  total_minutes integer NOT NULL,
  cycle_minutes integer NOT NULL,
  status USER-DEFINED NOT NULL DEFAULT 'active'::session_status,
  started_at timestamp with time zone NOT NULL DEFAULT now(),
  ended_at timestamp with time zone,
  CONSTRAINT focus_sessions_pkey PRIMARY KEY (id),
  CONSTRAINT focus_sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.focus_session_tasks (
  session_id uuid NOT NULL,
  task_id uuid NOT NULL,
  CONSTRAINT focus_session_tasks_pkey PRIMARY KEY (session_id, task_id),
  CONSTRAINT focus_session_tasks_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.focus_sessions(id),
  CONSTRAINT focus_session_tasks_task_id_fkey FOREIGN KEY (task_id) REFERENCES public.tasks(id)
);
CREATE TABLE public.dungeon_runs (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  session_id uuid NOT NULL,
  task_id uuid NOT NULL,
  cycle_number integer NOT NULL,
  completed boolean NOT NULL DEFAULT false,
  xp_awarded integer NOT NULL DEFAULT 0,
  coin_awarded integer NOT NULL DEFAULT 0,
  started_at timestamp with time zone NOT NULL DEFAULT now(),
  ended_at timestamp with time zone,
  CONSTRAINT dungeon_runs_pkey PRIMARY KEY (id),
  CONSTRAINT dungeon_runs_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.focus_sessions(id),
  CONSTRAINT dungeon_runs_task_id_fkey FOREIGN KEY (task_id) REFERENCES public.tasks(id)
);
CREATE TABLE public.quest_log_entries (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  source_type USER-DEFINED NOT NULL,
  source_id uuid NOT NULL,
  result USER-DEFINED NOT NULL,
  xp_awarded integer NOT NULL DEFAULT 0,
  coin_awarded integer NOT NULL DEFAULT 0,
  hp_change integer NOT NULL DEFAULT 0,
  occurred_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT quest_log_entries_pkey PRIMARY KEY (id),
  CONSTRAINT quest_log_entries_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.hero_journal_entries (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  entry_date date NOT NULL,
  narrative_text text NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT hero_journal_entries_pkey PRIMARY KEY (id),
  CONSTRAINT hero_journal_entries_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.achievements (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  code text NOT NULL UNIQUE,
  name text NOT NULL,
  description text,
  is_hidden boolean NOT NULL DEFAULT false,
  CONSTRAINT achievements_pkey PRIMARY KEY (id)
);
CREATE TABLE public.user_achievements (
  user_id uuid NOT NULL,
  achievement_id uuid NOT NULL,
  unlocked_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT user_achievements_pkey PRIMARY KEY (user_id, achievement_id),
  CONSTRAINT user_achievements_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id),
  CONSTRAINT user_achievements_achievement_id_fkey FOREIGN KEY (achievement_id) REFERENCES public.achievements(id)
);
CREATE TABLE public.inventory_items (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text,
  icon_url text,
  CONSTRAINT inventory_items_pkey PRIMARY KEY (id)
);
CREATE TABLE public.user_inventory (
  user_id uuid NOT NULL,
  item_id uuid NOT NULL,
  obtained_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT user_inventory_pkey PRIMARY KEY (user_id, item_id),
  CONSTRAINT user_inventory_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id),
  CONSTRAINT user_inventory_item_id_fkey FOREIGN KEY (item_id) REFERENCES public.inventory_items(id)
);
CREATE TABLE public.market_items (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  category USER-DEFINED NOT NULL,
  name text NOT NULL,
  description text,
  coin_cost integer NOT NULL,
  is_active boolean NOT NULL DEFAULT true,
  CONSTRAINT market_items_pkey PRIMARY KEY (id),
  CONSTRAINT market_items_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.purchases (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  market_item_id uuid NOT NULL,
  coins_spent integer NOT NULL,
  purchased_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT purchases_pkey PRIMARY KEY (id),
  CONSTRAINT purchases_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id),
  CONSTRAINT purchases_market_item_id_fkey FOREIGN KEY (market_item_id) REFERENCES public.market_items(id)
);
CREATE TABLE public.hp_recovery_purchases (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  hp_restored integer NOT NULL,
  coins_spent integer NOT NULL,
  purchased_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT hp_recovery_purchases_pkey PRIMARY KEY (id),
  CONSTRAINT hp_recovery_purchases_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.black_market_items (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name text NOT NULL,
  coin_cost integer NOT NULL,
  cooldown_hours integer NOT NULL,
  max_uses_per_user integer,
  CONSTRAINT black_market_items_pkey PRIMARY KEY (id)
);
CREATE TABLE public.black_market_redemptions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  item_id uuid NOT NULL,
  redeemed_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT black_market_redemptions_pkey PRIMARY KEY (id),
  CONSTRAINT black_market_redemptions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id),
  CONSTRAINT black_market_redemptions_item_id_fkey FOREIGN KEY (item_id) REFERENCES public.black_market_items(id)
);
CREATE TABLE public.recovery_passes (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  used_at timestamp with time zone NOT NULL DEFAULT now(),
  cooldown_until timestamp with time zone NOT NULL,
  CONSTRAINT recovery_passes_pkey PRIMARY KEY (id),
  CONSTRAINT recovery_passes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.difficulty_levels (
  level USER-DEFINED NOT NULL,
  xp_multiplier numeric NOT NULL,
  coin_multiplier numeric NOT NULL,
  hp_penalty_multiplier numeric NOT NULL,
  CONSTRAINT difficulty_levels_pkey PRIMARY KEY (level)
);
CREATE TABLE public.game_master_settings (
  user_id uuid NOT NULL,
  difficulty USER-DEFINED NOT NULL DEFAULT 'normal'::difficulty_level,
  skill_limit integer NOT NULL DEFAULT 6,
  notification_daily_limit integer,
  silence_window_start time without time zone,
  silence_window_end time without time zone,
  ignore_threshold integer NOT NULL DEFAULT 5,
  short_break_minutes integer NOT NULL DEFAULT 5,
  long_break_minutes integer NOT NULL DEFAULT 15,
  long_break_every_n_cycles integer NOT NULL DEFAULT 4,
  CONSTRAINT game_master_settings_pkey PRIMARY KEY (user_id),
  CONSTRAINT game_master_settings_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.notifications (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  type USER-DEFINED NOT NULL,
  title text NOT NULL,
  message text NOT NULL,
  related_entity_type text,
  related_entity_id uuid,
  sent_at timestamp with time zone,
  read_at timestamp with time zone,
  ignored boolean NOT NULL DEFAULT false,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT notifications_pkey PRIMARY KEY (id),
  CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);
