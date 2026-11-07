// Prueba la migración 035 (limpieza del juego retirado) sobre 001–034: lo
// borrado ya no existe y todo lo que la app sigue llamando funciona.
// Uso: cd supabase/tests && node 035_cleanup.test.mjs
import assert from 'node:assert/strict';
import { readdirSync } from 'node:fs';

import { U1, U2, createFullDb, migration, ok } from './bootstrap.mjs';

const { db, one, asUser } = await createFullDb();
const files = readdirSync(new URL('../migrations/', import.meta.url))
  .filter((f) => f >= '003' && f < '035' && f.endsWith('.sql')).sort();
for (const f of files) await db.exec(migration(f));
await db.exec(`insert into auth.users values ('${U1}', '{"username":"Ana"}'), ('${U2}', '{}')`);

// Datos del juego viejo antes de limpiar: no deben romper la migración.
await db.exec(`insert into npcs (user_id, name, noble_mission, skill_id)
  select '${U1}', 'Sabio', 'Aprender', (select id from skills limit 1)
  where exists (select 1 from skills)`);

await db.exec(migration('035_cleanup.sql'));
await db.exec(migration('035_cleanup.sql')); // idempotente
ok('035 se aplica dos veces sin error');

const gone = await one(`select
  (select count(*) from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.proname in ('purchase', 'tavern_overview', 'claim_daily_chest',
     'vision_overview', 'buy_black_market', 'use_recovery_pass', 'enforce_npc_limit'))::int f,
  (select count(*) from information_schema.tables where table_schema = 'public'
   and table_name in ('npcs', 'market_items', 'purchases', 'vision_boards', 'recovery_passes',
     'black_market_items', 'inventory_items', 'v_user_store'))::int t`);
assert.deepEqual(gone, { f: 0, t: 0 });
ok('035: las RPC y tablas del juego retirado ya no existen');

// Lo que la app sigue usando ------------------------------------------------------
const as = (uid, sql, p) => asUser(uid, () => one(sql, p));
const day = (await one('select current_date::text d')).d;
const t = (await as(U1, `select create_task('Leer el capítulo dos del libro') r`)).r.id;
await as(U1, 'select complete_task($1)', [t]);
const t2 = (await as(U1, `select create_task('Escribir') r`)).r.id;
const good = (await as(U1, `select create_habit('Meditar', 'good') id`)).id;
const bad = (await as(U1, `select create_habit('Azúcar', 'bad', p_hp_penalty => 5) id`)).id;
await as(U1, 'select complete_habit($1, $2::date)', [good, day]);
await as(U1, 'select register_bad_habit($1)', [bad]);
const s = (await as(U1, 'select start_dungeon(60, 25, $1::uuid[]) id', [[t2]])).id;
await db.query(`update focus_sessions set started_at = now() - interval '26 minutes' where id = $1`, [s]);
await as(U1, 'select complete_dungeon_cycle($1, $2)', [s, t2]);
await as(U1, 'select end_dungeon($1)', [s]);
for (const sql of [
  'select home_dashboard($1::date, 0) r', 'select day_agenda($1::date, 0) r',
  'select habits_overview($1::date) r', 'select stage_overview($1::date) r',
  'select stats_overview($1::date) r', 'select journal_overview($1::date) r',
  'select weekly_review($1::date, 0) r',
]) assert.ok((await as(U1, sql, [day])).r, sql);
for (const sql of [
  'select missions_overview() r', 'select profile_overview() r', 'select settings_overview() r',
  'select onboarding_overview() r', 'select brain_dump_overview() r', 'select dungeon_overview() r',
  `select sync_reminders('UTC') r`, 'select assistant_status() r',
]) assert.ok((await as(U1, sql)).r, sql);
await db.query('select daily_maintenance()');
ok('035: tareas, hábitos, Foco, Hoy, Stage, Historial, Perfil y el job diario siguen funcionando');

// Avisos sin Cofre y con «tarea» -----------------------------------------------------
await db.query(`update character_stats set current_xp = xp_to_next_level - 1 where user_id = $1`, [U1]);
const n = (await as(U1, 'select notifications_overview($1::date) r', [day])).r.items;
const text = JSON.stringify(n);
assert.ok(!/cofre/i.test(text), text);
assert.ok(!/misi[oó]n/i.test(text), text);
assert.ok(n.some((x) => x.title.startsWith('Estás a un paso')), text);
ok('035: el centro de avisos ya no anuncia el Cofre y habla de tareas');
