// Base de pruebas: Postgres real (PGlite) con stubs de Supabase
// (auth.users, auth.uid(), auth.role(), roles anon/authenticated) y el
// subconjunto del esquema desplegado (schema_deployed.sql, v1) que tocan
// las migraciones, con su RLS "own rows" y los grants por defecto.
import { PGlite } from '@electric-sql/pglite';
import { readFileSync } from 'node:fs';
import assert from 'node:assert/strict';

export const U0 = '00000000-0000-0000-0000-000000000000';
export const U1 = '11111111-1111-1111-1111-111111111111';
export const U2 = '22222222-2222-2222-2222-222222222222';

export const migration = (name) =>
  readFileSync(new URL(`../migrations/${name}`, import.meta.url), 'utf8');

const AUTH_STUBS = `
create role anon nologin; create role authenticated nologin;
create schema auth;
create table auth.users (id uuid primary key, raw_user_meta_data jsonb);
create function auth.uid() returns uuid language sql stable as
  $$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;
create function auth.role() returns text language sql stable as
  $$ select coalesce(nullif(current_setting('request.jwt.claim.role', true), ''), 'anon') $$;
grant usage on schema auth to anon, authenticated;
grant execute on all functions in schema auth to anon, authenticated;
`;

const helpers = (db) => {
  const one = async (sql, p) => (await db.query(sql, p)).rows[0];
  const asUser = async (uid, fn) => {
    await db.exec(`set role authenticated; select set_config('request.jwt.claim.sub', '${uid}', false);
                   select set_config('request.jwt.claim.role', 'authenticated', false);`);
    try { return await fn(); } finally { await db.exec('reset role'); }
  };
  return { db, one, asUser };
};

// Esquema desplegado completo (tests/deployed_v1.sql) con 001 y 002 aplicadas:
// el punto de partida de las migraciones 003 en adelante.
export async function createFullDb() {
  const db = new PGlite();
  await db.exec(AUTH_STUBS);
  await db.exec(readFileSync(new URL('./deployed_v1.sql', import.meta.url), 'utf8'));
  await db.exec(migration('001_home.sql'));
  await db.exec(migration('002_profile.sql'));
  return helpers(db);
}

export async function createDb() {
  const db = new PGlite();
  await db.exec(AUTH_STUBS);
  await db.exec(`

create type difficulty_level as enum ('easy','normal','hard');
create type habit_type as enum ('good','bad');
create type habit_frequency as enum ('daily','specific_days');
create type urgency_level as enum ('low','medium','high');
create type task_status as enum ('pending','in_progress','completed','delegated','expired');
create type session_status as enum ('active','paused','completed','cancelled');
create type quest_source as enum ('task','project','habit','npc','goal');
create type quest_result as enum ('completed','failed');

create table profiles (id uuid primary key references auth.users(id), display_name text,
  character_class text, identity_statement text, avatar_url text, created_at timestamptz not null default now());
create table character_stats (user_id uuid primary key references profiles(id), level int not null default 1,
  current_xp int not null default 0, xp_to_next_level int not null default 100, coins int not null default 0,
  hp_current int not null default 100, hp_max int not null default 100, is_weakened boolean not null default false,
  updated_at timestamptz not null default now());
create table skills (id uuid primary key default gen_random_uuid(), user_id uuid not null references profiles(id),
  name text not null, level int not null default 1, current_xp int not null default 0,
  xp_to_next_level int not null default 100, created_at timestamptz not null default now());
create table habits (id uuid primary key default gen_random_uuid(), user_id uuid not null references profiles(id),
  skill_id uuid references skills(id), name text not null, type habit_type not null,
  frequency habit_frequency not null default 'daily', specific_days smallint[], xp_reward int not null default 0,
  coin_reward int not null default 0, hp_penalty int not null default 0, created_at timestamptz not null default now());
create table habit_records (id uuid primary key default gen_random_uuid(), habit_id uuid not null references habits(id),
  user_id uuid not null references profiles(id), completed_on date not null, created_at timestamptz not null default now());
create table tasks (id uuid primary key default gen_random_uuid(), user_id uuid not null references profiles(id),
  parent_task_id uuid references tasks(id), title text not null, priority urgency_level not null default 'low',
  due_date timestamptz, status task_status not null default 'pending', xp_reward int not null default 0,
  coin_reward int not null default 0, completed_at timestamptz, created_at timestamptz not null default now());
create table focus_sessions (id uuid primary key default gen_random_uuid(), user_id uuid not null references profiles(id),
  total_minutes int not null, cycle_minutes int not null, status session_status not null default 'active',
  started_at timestamptz not null default now(), ended_at timestamptz);
create table quest_log_entries (id uuid primary key default gen_random_uuid(), user_id uuid not null references profiles(id),
  source_type quest_source not null, source_id uuid not null, result quest_result not null,
  xp_awarded int not null default 0, coin_awarded int not null default 0, hp_change int not null default 0,
  occurred_at timestamptz not null default now());
create table difficulty_levels (level difficulty_level primary key, xp_multiplier numeric not null,
  coin_multiplier numeric not null, hp_penalty_multiplier numeric not null);
create table game_master_settings (user_id uuid primary key references profiles(id),
  difficulty difficulty_level not null default 'normal', skill_limit int not null default 6);
insert into difficulty_levels values ('easy',1.2,1.2,0.8),('normal',1,1,1),('hard',0.8,0.8,1.2);

-- RLS y grants como en el proyecto desplegado.
do $$ declare t text; begin
  foreach t in array array['profiles','character_stats','skills','habits','habit_records','tasks',
                           'focus_sessions','quest_log_entries','game_master_settings'] loop
    execute format('alter table %I enable row level security', t);
    execute format('create policy "own rows" on %I for all using (auth.uid() = %s) with check (auth.uid() = %s)',
      t, case t when 'profiles' then 'id' else 'user_id' end, case t when 'profiles' then 'id' else 'user_id' end);
  end loop; end $$;
alter table difficulty_levels enable row level security;
create policy "read all" on difficulty_levels for select using (auth.role() = 'authenticated');
grant usage on schema public to anon, authenticated;
grant all on all tables in schema public to anon, authenticated;
-- Tablas que referencian skills (002 cambia sus FK) y el trigger del límite
-- tal como existe en el proyecto (cuerpo desconocido: aquí uno equivalente).
create type npc_frequency as enum ('daily','weekly','monthly');
create table goals (id uuid primary key default gen_random_uuid(), user_id uuid not null references profiles(id),
  skill_id uuid references skills(id), title text not null);
create table projects (id uuid primary key default gen_random_uuid(), user_id uuid not null references profiles(id),
  skill_id uuid references skills(id), title text not null);
create table npcs (id uuid primary key default gen_random_uuid(), user_id uuid not null references profiles(id),
  name text not null, skill_id uuid not null references skills(id), frequency npc_frequency not null);
alter table tasks add column skill_id uuid references skills(id);
create function enforce_skill_limit() returns trigger language plpgsql as $$
begin
  if (select count(*) from skills where user_id = new.user_id) >= 6 then
    raise exception 'Skill limit reached';
  end if;
  return new;
end $$;
create trigger trg_enforce_skill_limit before insert on skills for each row execute function enforce_skill_limit();
do $$ declare t text; begin
  foreach t in array array['goals','projects','npcs'] loop
    execute format('alter table %I enable row level security', t);
    execute format('create policy "own rows" on %I for all using (auth.uid() = user_id) with check (auth.uid() = user_id)', t);
  end loop; end $$;
grant all on all tables in schema public to anon, authenticated;
`);
  return helpers(db);
}

export const rejects = async (p, re) => {
  try { await p; } catch (e) { assert.match(e.message, re); return; }
  assert.fail(`esperaba error ${re}`);
};

export const ok = (m) => console.log('✔', m);
