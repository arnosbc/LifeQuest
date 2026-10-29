// Prueba la migración 033 (botín y tiempo efectivo de la Mazmorra) sobre 001–032.
// Uso: cd supabase/tests && node 033_dungeon_rewards.test.mjs
import assert from 'node:assert/strict';

import { U1, U2, createFullDb, migration, ok, rejects } from './bootstrap.mjs';

const { db, one, asUser } = await createFullDb();
// 032 necesita el esquema storage de Supabase; aquí basta con hasta la 031.
for (const f of ['003_security.sql', '004_structure.sql', '005_rewards.sql', '006_store.sql',
  '007_daily.sql', '008_fix_exploits.sql', '009_profile_titles.sql', '010_missions.sql',
  '011_habits.sql', '012_dungeon.sql', '013_stage.sql', '014_goals.sql', '015_onboarding.sql',
  '016_settings.sql', '017_dungeon_breaks.sql', '018_marketplace.sql', '019_tavern.sql',
  '020_journal.sql', '021_boss_fight.sql', '022_rpgenie.sql', '023_brain_dump.sql',
  '024_vision_board.sql', '025_stats.sql', '026_inventory.sql', '027_daily_chest.sql',
  '028_edit_delete.sql', '029_notifications.sql', '030_npc_noble_mission.sql',
  '031_npc_mission_guide.sql']) {
  await db.exec(migration(f));
}
await db.exec(migration('033_dungeon_rewards.sql'));
await db.exec(migration('033_dungeon_rewards.sql')); // idempotente
await db.exec(`insert into auth.users values ('${U1}', '{}'), ('${U2}', '{}')`);
ok('033 se aplica dos veces sin error');

const call = (uid, sql, params) => asUser(uid, () => one(sql, params)).then((x) => x && x.r);
const overview = (uid) => call(uid, `select dungeon_overview() r`);
const task = (uid, title) => call(uid, `select create_task($1) r`, [title]).then((x) => x.id);

const t1 = await task(U1, 'Estudiar álgebra lineal hoy');
const t2 = await task(U1, 'Escribir el informe');
const outside = await task(U1, 'Fuera de la mochila');
// Creadas hace rato: así pagan Monedas (regla de los 2 min, 005).
await db.query(`update tasks set created_at = now() - interval '1 hour' where user_id = $1`, [U1]);

const s = await call(U1, `select start_dungeon(60, 25, $1::uuid[]) r`, [[t1, t2]]);
await db.query(`update focus_sessions set started_at = now() - interval '40 minutes' where id = $1`, [s]);

let r = await overview(U1);
assert.deepEqual([r.session.xp_earned, r.session.coins_earned, r.session.missions_done,
  r.session.focus_minutes], [0, 0, 0, 0]);

// Misión de la mochila completada durante la sesión: cuenta.
const paid = await call(U1, `select complete_task($1) r`, [t1]);
assert.ok(paid.xp > 0 && paid.coins > 0);
r = await overview(U1);
assert.deepEqual([r.session.xp_earned, r.session.coins_earned, r.session.missions_done],
  [paid.xp, paid.coins, 1]);
ok('033: completar una misión de la mochila suma su XP y Monedas a la sesión');

// Misión fuera de la mochila: no cuenta.
await call(U1, `select complete_task($1) r`, [outside]);
r = await overview(U1);
assert.equal(r.session.missions_done, 1);

// Un ciclo: suma lo del ciclo y el tiempo efectivo es 25, no los 40 de reloj.
const cycle = await call(U1, `select complete_dungeon_cycle($1, $2) r`, [s, t2]);
r = await overview(U1);
assert.deepEqual([r.session.cycles_done, r.session.xp_earned, r.session.coins_earned,
  r.session.focus_minutes], [1, paid.xp + cycle.xp, paid.coins + cycle.coins, 25]);
ok('033: las misiones fuera de la mochila no cuentan; los ciclos se suman');

assert.equal(await overview(U2).then((x) => x.session), null);
await rejects(call(U2, `select end_dungeon($1) r`, [s]), /session_not_found/);

const summary = await call(U1, `select end_dungeon($1) r`, [s]);
assert.deepEqual(summary, { cycles: 1, xp: paid.xp + cycle.xp, coins: paid.coins + cycle.coins,
  missions: 1, minutes: 25 });

// Lo completado después de cerrar no entra en el resumen de esa sesión.
const later = await task(U1, 'Después');
await db.query(`update tasks set created_at = now() - interval '1 hour' where id = $1`, [later]);
await db.exec(`insert into focus_session_tasks (session_id, task_id) values ('${s}', '${later}')`);
await call(U1, `select complete_task($1) r`, [later]);
const loot = await call(U1, `select to_jsonb(l) r from _dungeon_loot($1) l`, [s]);
assert.equal(loot.missions, 1);
ok('033: end_dungeon da el botín completo con tiempo efectivo = ciclos × duración');
