// Prueba la migración 012 (Mazmorra) sobre 001–011: dungeon_overview,
// start_dungeon y end_dungeon, con complete_dungeon_cycle de 008.
// Uso: cd supabase/tests && node 012_dungeon.test.mjs
import assert from 'node:assert/strict';

import { U1, U2, createFullDb, migration, ok, rejects } from './bootstrap.mjs';

const { db, one, asUser } = await createFullDb();
for (const f of ['003_security.sql', '004_structure.sql', '005_rewards.sql', '006_store.sql',
  '007_daily.sql', '008_fix_exploits.sql', '009_profile_titles.sql', '010_missions.sql',
  '011_habits.sql']) {
  await db.exec(migration(f));
}
await db.exec(migration('012_dungeon.sql'));
await db.exec(migration('012_dungeon.sql')); // idempotente
await db.exec(`insert into auth.users values ('${U1}', '{"username":"Ana"}'), ('${U2}', '{}')`);
ok('012 se aplica dos veces sin error');

const overview = (uid) => asUser(uid, () => one(`select dungeon_overview() r`)).then((x) => x.r);
const start = (uid, total, cycle, tasks) =>
  asUser(uid, () => one(`select start_dungeon($1, $2, $3::uuid[]) id`, [total, cycle, tasks])).then((x) => x.id);
const task = (uid, title) => asUser(uid, () => one(`select create_task($1) r`, [title])).then((x) => x.r.id);

const t1 = await task(U1, 'Estudiar');
const t2 = await task(U1, 'Escribir');
const foreign = await task(U2, 'Ajena');

// Sin sesión ------------------------------------------------------------------------
let r = await overview(U1);
assert.equal(r.session, null);
assert.deepEqual(r.candidates.map((c) => c.id).sort(), [t1, t2].sort());
assert.deepEqual([r.max_tasks, r.cycle_xp], [5, 10]);
ok('012: sin sesión ofrece las misiones abiertas para la mochila');

// Validaciones ----------------------------------------------------------------------
await rejects(start(U1, 60, 20, [t1]), /invalid_duration/);
await rejects(start(U1, 45, 25, [t1]), /invalid_duration/);
await rejects(start(U1, 30, 45, [t1]), /invalid_duration/);
await rejects(start(U1, 60, 25, []), /no_tasks/);
await rejects(start(U1, 60, 25, [t1, foreign]), /task_not_found/);
const many = [];
for (let i = 0; i < 6; i++) many.push(await task(U1, `T${i}`));
await rejects(start(U1, 60, 25, many), /session_task_limit/);
ok('012: start_dungeon valida duración, mochila (1–5) y dueño de las tareas');

// Iniciar y jugar -----------------------------------------------------------------
const s = await start(U1, 60, 25, [t1, t2, t1]);
await rejects(start(U1, 60, 25, [t1]), /session_already_open/);
r = await overview(U1);
assert.equal(r.session.id, s);
assert.deepEqual([r.session.total_minutes, r.session.cycle_minutes, r.session.cycles_done], [60, 25, 0]);
assert.deepEqual(r.session.tasks.map((t) => [t.id, t.done, t.cycles]), [[t1, false, 0], [t2, false, 0]]);

await rejects(asUser(U1, () => db.query(`select complete_dungeon_cycle($1, $2)`, [s, t1])), /cycle_not_finished/);
await db.query(`update focus_sessions set started_at = now() - interval '26 minutes' where id = $1`, [s]);
await asUser(U1, () => db.query(`select complete_dungeon_cycle($1, $2)`, [s, t1]));
r = await overview(U1);
assert.deepEqual([r.session.cycles_done, r.session.xp_earned, r.session.coins_earned], [1, 10, 3]);
assert.equal(r.session.tasks[0].cycles, 1);
assert.equal(await overview(U2).then((x) => x.session), null);
await rejects(asUser(U2, () => db.query(`select end_dungeon($1)`, [s])), /session_not_found/);
ok('012: la sesión muestra ciclos, tareas y lo ganado; otro jugador no la ve ni la cierra');

// Terminar ----------------------------------------------------------------------------
const summary = await asUser(U1, () => one(`select end_dungeon($1) r`, [s])).then((x) => x.r);
assert.deepEqual(summary, { cycles: 1, xp: 10, coins: 3, minutes: 26 });
assert.equal((await overview(U1)).session, null);
await rejects(asUser(U1, () => db.query(`select end_dungeon($1)`, [s])), /session_not_found/);
await rejects(asUser(U1, () => db.query(`select complete_dungeon_cycle($1, $2)`, [s, t1])), /session_not_active/);
assert.ok(await start(U1, 30, 25, [t2]));
ok('012: end_dungeon cierra sin perder lo ganado, da el resumen y deja empezar otra');
