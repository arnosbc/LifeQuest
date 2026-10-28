// Prueba la migración 029 (centro de avisos) sobre 001–028.
// Uso: cd supabase/tests && node 029_notifications.test.mjs
import assert from 'node:assert/strict';

import { U1, U2, createFullDb, migration, ok } from './bootstrap.mjs';

const { db, one, asUser } = await createFullDb();
for (const f of ['003_security.sql', '004_structure.sql', '005_rewards.sql', '006_store.sql',
  '007_daily.sql', '008_fix_exploits.sql', '009_profile_titles.sql', '010_missions.sql',
  '011_habits.sql', '012_dungeon.sql', '013_stage.sql', '014_goals.sql', '015_onboarding.sql',
  '016_settings.sql', '017_dungeon_breaks.sql', '018_marketplace.sql', '019_tavern.sql',
  '020_journal.sql', '021_boss_fight.sql', '022_rpgenie.sql', '023_brain_dump.sql',
  '024_vision_board.sql', '025_stats.sql', '026_inventory.sql', '027_daily_chest.sql',
  '028_edit_delete.sql']) {
  await db.exec(migration(f));
}
await db.exec(migration('029_notifications.sql'));
await db.exec(migration('029_notifications.sql')); // idempotente
await db.exec(`insert into auth.users values ('${U1}', '{"username":"Ana"}'), ('${U2}', '{}')`);
ok('029 se aplica dos veces sin error');

const today = (await one(`select current_date::text d`)).d;
const call = (uid, sql, params) => asUser(uid, () => one(sql, params)).then((x) => x && x.r);
const overview = (uid) => call(uid, `select notifications_overview($1::date) r`, [today]);
const keys = async (uid) => (await db.query(
  `select category from notifications where user_id = $1 order by category`, [uid])).rows.map((r) => r.category);

assert.deepEqual((await overview(U1)).items, []);

// Racha en riesgo, proyecto en 🔴, cerca de nivel y misiones de hoy.
await db.query(`insert into habits (user_id, name, type, current_streak) values ($1, 'Leer', 'good', 12)`, [U1]);
const p = (await one(`insert into projects (user_id, title, start_date, end_date)
  values ($1, 'Tesis', current_date - 10, current_date + 1) returning id`, [U1])).id;
await db.query(`insert into tasks (user_id, project_id, title) values ($1, $2, 'A'), ($1, $2, 'B')`, [U1, p]);
await db.query(`update character_stats set current_xp = 95, xp_to_next_level = 100 where user_id = $1`, [U1]);
await db.query(`insert into tasks (user_id, title, due_date) values ($1, 'Pagar luz', $2::date + interval '20 hours')`, [U1, today]);

let r = await overview(U1);
assert.deepEqual(await keys(U1), ['due', 'level', 'project', 'streak']);
assert.equal(r.unread, 4);
const streak = r.items.find((i) => i.title.startsWith('Tu racha'));
assert.equal(streak.type, 'critical');
assert.match(streak.message, /12 días con «Leer»/);
assert.doesNotMatch(r.items.map((i) => i.message).join(' '), /perder/i);

// Volver a abrir no duplica nada (event_key único).
r = await overview(U1);
assert.equal(r.items.length, 4);
ok('029: genera cada aviso una sola vez, con tono de invitación');

// Leer uno, luego todos.
await call(U1, `select mark_notifications_read($1::uuid[]) r`, [[streak.id]]);
assert.equal((await overview(U1)).unread, 3);
await call(U1, `select mark_notifications_read() r`);
assert.equal((await overview(U1)).unread, 0);

// Categoría reducida (5 ignoradas): deja de generarse, salvo lo crítico.
await db.query(`delete from notifications where user_id = $1`, [U1]);
await db.query(`insert into notification_category_state (user_id, category, consecutive_ignored, reduced)
  values ($1, 'level', 5, true), ($1, 'streak', 5, true)`, [U1]);
await overview(U1);
assert.deepEqual(await keys(U1), ['due', 'project', 'streak']);

// Aislamiento.
assert.deepEqual((await overview(U2)).items, []);
await call(U2, `select mark_notifications_read() r`);
assert.equal((await one(`select count(*)::int n from notifications where user_id = $1 and read_at is null`, [U1])).n, 3);
ok('029: marcar leídas, respetar categorías reducidas y aislar jugadores');
