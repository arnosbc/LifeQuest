// Prueba la migración 014 (Metas en Stage) sobre 001–013: create_goal,
// stage_overview con metas y misiones por proyecto, y archivar metas.
// Uso: cd supabase/tests && node 014_goals.test.mjs
import assert from 'node:assert/strict';

import { U1, U2, createFullDb, migration, ok, rejects } from './bootstrap.mjs';

const { db, one, asUser } = await createFullDb();
for (const f of ['003_security.sql', '004_structure.sql', '005_rewards.sql', '006_store.sql',
  '007_daily.sql', '008_fix_exploits.sql', '009_profile_titles.sql', '010_missions.sql',
  '011_habits.sql', '012_dungeon.sql', '013_stage.sql']) {
  await db.exec(migration(f));
}
await db.exec(migration('014_goals.sql'));
await db.exec(migration('014_goals.sql')); // idempotente
await db.exec(`insert into auth.users values ('${U1}', '{"username":"Ana"}'), ('${U2}', '{}')`);
ok('014 se aplica dos veces sin error');

const today = (await one(`select current_date::text d`)).d;
const call = (uid, sql, params) => asUser(uid, () => one(sql, params));
const overview = (uid) => call(uid, `select stage_overview($1::date) r`, [today]).then((x) => x.r);
const goal = (uid, a) => call(uid,
  `select create_goal(p_title => $1, p_specific => $2, p_measurable => $3, p_achievable => $4,
     p_relevant => $5, p_due_date => current_date + $6::int, p_timebound => $7, p_skill_id => $8) id`,
  [a.title ?? 'Correr 10 km', a.s ?? 'Correr 10 km sin parar', a.m ?? 'Tiempo bajo 60 min',
    a.a ?? '3 entrenos por semana', a.r ?? 'Quiero más energía', a.days ?? 60, a.t ?? null,
    a.skill ?? null]).then((x) => x.id);

const skill = (await one(`insert into skills (user_id, name) values ($1, 'Salud') returning id`, [U1])).id;

// Crear Meta -----------------------------------------------------------------------
const g = await goal(U1, { title: '  Correr 10 km  ', skill, t: '  En diciembre  ' });
const row = await one(`select title, smart_specific, smart_timebound, start_date::text sd, due_date - current_date d,
  status, boss_current_hp, boss_max_hp, skill_id from goals where id = $1`, [g]);
assert.deepEqual(row, { title: 'Correr 10 km', smart_specific: 'Correr 10 km sin parar',
  smart_timebound: 'En diciembre', sd: today, d: 60, status: 'not_started',
  boss_current_hp: 100, boss_max_hp: 100, skill_id: skill });

await rejects(goal(U1, { title: ' ' }), /invalid_title/);
await rejects(goal(U1, { m: '  ' }), /smart_incomplete/);
await rejects(goal(U1, { r: '' }), /smart_incomplete/);
await rejects(goal(U1, { days: -1 }), /invalid_due_date/);
await rejects(call(U1, `select create_goal('x', 's', 'm', 'a', 'r', null)`), /invalid_due_date/);
await rejects(goal(U2, { skill }), /skill_not_found/);
ok('014: create_goal guarda la ficha S.M.A.R.T. y valida lo obligatorio');

// Stage con metas y misiones por proyecto ---------------------------------------------
const project = (await call(U1, `select create_project('Plan de entreno', null, null, null, $1) id`, [g])).id;
const t1 = (await call(U1, `select create_task('Primera salida', null, 'high', null, null, $1, $2) r`, [project, g])).r.id;
const t2 = (await call(U1, `select create_task('Comprar zapatillas', null, 'low', null, null, $1) r`, [project])).r.id;
await call(U1, `select create_task('Estirar', null, 'low', null, null, $1, null, '{"Sub"}') r`, [project]);
await db.query(`update tasks set created_at = now() - interval '1 hour' where id = $1`, [t1]);
await call(U1, `select complete_task($1) r`, [t1]);

let r = await overview(U1);
const sg = r.goals.find((x) => x.id === g);
assert.deepEqual([sg.title, sg.skill_name, sg.boss_max_hp, sg.projects, sg.open_tasks],
  ['Correr 10 km', 'Salud', 100, 1, 0]);
assert.ok(sg.boss_hp < 100, 'la misión vinculada le restó vida al jefe');
assert.equal(typeof sg.due_date, 'string');
const sp = r.projects.find((x) => x.id === project);
assert.deepEqual(sp.tasks.map((t) => [t.title, t.done]),
  [['Comprar zapatillas', false], ['Estirar', false], ['Primera salida', true]]); // abiertas primero, sin subtareas
assert.ok(sp.tasks.every((t) => t.id !== t2 || !t.done));
assert.deepEqual([sp.tasks_total, sp.tasks_done], [3, 1]);
ok('014: stage_overview trae metas con vida del jefe y las misiones de cada proyecto');

// Archivar metas y aislamiento --------------------------------------------------------
await rejects(call(U2, `select archive_item('goal', $1)`, [g]), /item_not_found/);
await call(U1, `select archive_item('goal', $1)`, [g]);
r = await overview(U1);
assert.deepEqual(r.goals, []);
assert.equal(r.archive.goals, 1);
await rejects(call(U1, `select create_project('x', null, null, null, $1)`, [g]), /goal_not_found/);
r = await overview(U2);
assert.deepEqual([r.goals, r.projects], [[], []]);
ok('014: archivar una meta la saca de Stage y no se puede vincular; cada jugador ve lo suyo');
