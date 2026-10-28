// Prueba la migración 028 (editar y borrar) sobre 001–027.
// Uso: cd supabase/tests && node 028_edit_delete.test.mjs
import assert from 'node:assert/strict';

import { U1, U2, createFullDb, migration, ok, rejects } from './bootstrap.mjs';

const { db, one, asUser } = await createFullDb();
for (const f of ['003_security.sql', '004_structure.sql', '005_rewards.sql', '006_store.sql',
  '007_daily.sql', '008_fix_exploits.sql', '009_profile_titles.sql', '010_missions.sql',
  '011_habits.sql', '012_dungeon.sql', '013_stage.sql', '014_goals.sql', '015_onboarding.sql',
  '016_settings.sql', '017_dungeon_breaks.sql', '018_marketplace.sql', '019_tavern.sql',
  '020_journal.sql', '021_boss_fight.sql', '022_rpgenie.sql', '023_brain_dump.sql',
  '024_vision_board.sql', '025_stats.sql', '026_inventory.sql', '027_daily_chest.sql']) {
  await db.exec(migration(f));
}
await db.exec(migration('028_edit_delete.sql'));
await db.exec(migration('028_edit_delete.sql')); // idempotente
await db.exec(`insert into auth.users values ('${U1}', '{"username":"Ana"}'), ('${U2}', '{}')`);
ok('028 se aplica dos veces sin error');

const call = (uid, sql, params) => asUser(uid, () => one(sql, params)).then((x) => x && x.r);
const today = (await one(`select current_date::text d`)).d;

// 1. Misiones -------------------------------------------------------------------------
const t = (await call(U1, `select create_task('Leer', null, 'low', null, null, null, null, '{"Cap 1","Cap 2"}') r`)).id;
const before = await one(`select xp_reward from tasks where id = $1`, [t]);
await call(U1, `select rename_task($1, '  Leer el libro entero de una vez  ') r`, [t]);
const after = await one(`select title, xp_reward from tasks where id = $1`, [t]);
assert.deepEqual(after, { title: 'Leer el libro entero de una vez', xp_reward: before.xp_reward }); // RF-112
await rejects(call(U1, `select rename_task($1, ' ') r`, [t]), /invalid_title/);
await rejects(call(U2, `select rename_task($1, 'x') r`, [t]), /task_not_open/);
await rejects(call(U2, `select delete_task($1) r`, [t]), /task_not_open/);

await call(U1, `select delete_task($1) r`, [t]);
assert.equal((await one(`select count(*)::int n from tasks where user_id = $1`, [U1])).n, 0);

const done = (await call(U1, `select create_task('Hecha') r`)).id;
await call(U1, `select complete_task($1) r`, [done]);
await rejects(call(U1, `select delete_task($1) r`, [done]), /task_not_open/);

const played = (await call(U1, `select create_task('En la Mazmorra') r`)).id;
const s = (await one(`insert into focus_sessions (user_id, total_minutes, cycle_minutes) values ($1, 30, 25) returning id`, [U1])).id;
await db.query(`insert into focus_session_tasks (session_id, task_id) values ($1, $2)`, [s, played]);
await db.query(`insert into dungeon_runs (session_id, task_id, cycle_number, completed) values ($1, $2, 1, true)`, [s, played]);
await rejects(call(U1, `select delete_task($1) r`, [played]), /task_in_use/);
const queued = (await call(U1, `select create_task('En la mochila') r`)).id;
await db.query(`insert into focus_session_tasks (session_id, task_id) values ($1, $2)`, [s, queued]);
await call(U1, `select delete_task($1) r`, [queued]);
ok('028: renombrar y borrar misiones abiertas, sin tocar recompensa ni historia');

// 2. Hábitos ----------------------------------------------------------------------------
const h = (await one(`insert into habits (user_id, name, type) values ($1, 'Leer', 'good') returning id`, [U1])).id;
await call(U1, `select complete_habit($1, $2::date) r`, [h, today]);
await call(U1, `select rename_habit($1, 'Leer 20 páginas') r`, [h]);
assert.equal((await one(`select name from habits where id = $1`, [h])).name, 'Leer 20 páginas');
await rejects(call(U2, `select delete_habit($1) r`, [h]), /habit_not_found/);
await call(U1, `select delete_habit($1) r`, [h]);
assert.equal((await one(`select count(*)::int n from habit_records where habit_id = $1`, [h])).n, 0);
ok('028: renombrar y borrar hábitos con sus registros');

// 3. NPCs --------------------------------------------------------------------------------
const skill = (await one(`insert into skills (user_id, name) values ($1, 'Salud') returning id`, [U1])).id;
const npc = await call(U1, `select create_npc('Vera', $1) r`, [skill]);
const mission = (await call(U1, `select accept_npc_mission($1, 'Correr') r`, [npc])).task_id;
await call(U1, `select rename_npc($1, 'Entrenadora Vera') r`, [npc]);
await rejects(call(U2, `select delete_npc($1) r`, [npc]), /npc_not_found/);
await call(U1, `select delete_npc($1) r`, [npc]);
assert.deepEqual(await one(`select title, npc_id from tasks where id = $1`, [mission]), { title: 'Correr', npc_id: null });
assert.equal((await one(`select count(*)::int n from npcs`)).n, 0);
ok('028: borrar un NPC conserva sus misiones como misiones sueltas');
