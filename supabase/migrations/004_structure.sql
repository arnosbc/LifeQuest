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
