// Prueba la migración 013 (Stage · P.A.R.A.) sobre 001–012: stage_overview,
// urgencia de proyectos, create_project, create_resource y archive_item.
// Uso: cd supabase/tests && node 013_stage.test.mjs
import assert from 'node:assert/strict';

import { U1, U2, createFullDb, migration, ok, rejects } from './bootstrap.mjs';

const { db, one, asUser } = await createFullDb();
for (const f of ['003_security.sql', '004_structure.sql', '005_rewards.sql', '006_store.sql',
  '007_daily.sql', '008_fix_exploits.sql', '009_profile_titles.sql', '010_missions.sql',
  '011_habits.sql', '012_dungeon.sql']) {
  await db.exec(migration(f));
}
await db.exec(migration('013_stage.sql'));
await db.exec(migration('013_stage.sql')); // idempotente
await db.exec(`insert into auth.users values ('${U1}', '{"username":"Ana"}'), ('${U2}', '{}')`);
ok('013 se aplica dos veces sin error');

const today = (await one(`select current_date::text d`)).d;
const overview = (uid) => asUser(uid, () => one(`select stage_overview($1::date) r`, [today])).then((x) => x.r);
const call = (uid, sql, params) => asUser(uid, () => one(sql, params));

// Urgencia (RF-019) --------------------------------------------------------------
const urgency = async (total, done, startAgo, endIn) => (await one(
  `select _project_urgency($1, $2, current_date - $3::int, current_date + $4::int, current_date) u`,
  [total, done, startAgo, endIn])).u;
assert.equal(await urgency(10, 5, 5, 5), 'low');      // necesita 1/día, va a 1/día
assert.equal(await urgency(10, 4, 4, 5), 'low');      // necesita 1,2/día = ×1,2 justo: aún no
assert.equal(await urgency(10, 4, 4, 4), 'medium');   // necesita 1,5/día, va a 1/día
assert.equal(await urgency(10, 2, 4, 2), 'high');     // necesita 4/día, va a 0,5/día
assert.equal(await urgency(10, 3, 3, 0), 'high');     // vence hoy con trabajo pendiente
assert.equal(await urgency(0, 0, 3, 3), 'low');       // sin tareas
assert.equal(await urgency(4, 4, 3, -1), 'low');      // todo hecho
assert.equal((await one(`select _project_urgency(5, 1, current_date, null, current_date) u`)).u, 'low');
ok('013: urgencia automática según ritmo necesario vs. actual');

// Vacío y Quick Add -----------------------------------------------------------------
let r = await overview(U1);
assert.deepEqual([r.highlight, r.highlight_total, r.projects, r.areas, r.resources],
  [[], 0, [], [], []]);
assert.deepEqual(r.archive, { projects: 0, goals: 0, resources: 0 });

const skill = (await one(`insert into skills (user_id, name) values ($1, 'Trabajo') returning id`, [U1])).id;
const goal = (await one(`insert into goals (user_id, title) values ($1, 'Ascenso') returning id`, [U1])).id;
const project = (await call(U1, `select create_project($1, $2, current_date + 10, $3, $4) id`,
  ['  Lanzamiento  ', ' ', skill, goal])).id;
const loose = (await call(U1, `select create_project('Curso de inglés') id`)).id;
const res = (await call(U1, `select create_resource($1, $2) id`, ['Guía', 'https://example.com/guia'])).id;

await rejects(call(U1, `select create_project(' ')`), /invalid_title/);
await rejects(call(U1, `select create_project('x', null, current_date - 5)`), /invalid_end_date/);
await rejects(call(U2, `select create_project('x', null, null, $1)`, [skill]), /skill_not_found/);
await rejects(call(U2, `select create_project('x', null, null, null, $1)`, [goal]), /goal_not_found/);
await rejects(call(U1, `select create_resource('x', 'ftp://algo')`), /invalid_url/);
await rejects(call(U1, `select create_resource('x', 'javascript:alert(1)')`), /invalid_url/);
ok('013: create_project y create_resource validan título, fecha, vínculos y URL');

// Lectura ----------------------------------------------------------------------------
const t1 = (await call(U1, `select create_task('Diseñar landing', null, 'high', null, $1, $2) r`, [skill, project])).r.id;
await call(U1, `select create_task('Escribir notas', null, 'low', null, null, $1, null, '{"Sub"}') r`, [project]);
await call(U1, `select create_task('Suelta') r`);
await db.query(`update tasks set created_at = now() - interval '1 hour' where id = $1`, [t1]);
await call(U1, `select complete_task($1) r`, [t1]);

r = await overview(U1);
assert.deepEqual(r.highlight.map((h) => h.title), ['Escribir notas', 'Suelta']); // sin subtareas
assert.equal(r.highlight_total, 2);
const lp = r.projects.find((p) => p.id === project);
assert.deepEqual([lp.title, lp.skill_name, lp.goal_title, lp.tasks_total, lp.tasks_done],
  ['Lanzamiento', 'Trabajo', 'Ascenso', 2, 1]);
assert.equal(lp.urgency, 'low'); // 1 hecha hoy; falta 1 en 10 días
const cp = r.projects.find((p) => p.id === loose);
assert.deepEqual([cp.skill_name, cp.urgency, cp.end_date], [null, 'low', null]);
assert.deepEqual(r.projects.map((p) => p.id), [project, loose]); // con fecha primero
assert.deepEqual(r.areas.map((a) => [a.name, a.level, a.open_tasks, a.projects, a.habits]),
  [['Trabajo', 1, 0, 1, 0]]);
assert.deepEqual(r.resources, [{ id: res, title: 'Guía', url: 'https://example.com/guia' }]);
assert.deepEqual(r.skills.map((s) => s.id), [skill]);
assert.deepEqual(r.goals.map((g) => g.id), [goal]);
ok('013: overview trae highlight, proyectos con progreso y urgencia, áreas y recursos');

// Archivo y aislamiento ------------------------------------------------------------------
await rejects(call(U2, `select archive_item('project', $1)`, [loose]), /item_not_found/);
await rejects(call(U1, `select archive_item('goal', $1)`, [goal]), /invalid_kind/);
await call(U1, `select archive_item('project', $1)`, [loose]);
await call(U1, `select archive_item('resource', $1)`, [res]);
await rejects(call(U1, `select archive_item('resource', $1)`, [res]), /item_not_found/);
r = await overview(U1);
assert.deepEqual(r.projects.map((p) => p.id), [project]);
assert.deepEqual(r.resources, []);
assert.deepEqual(r.archive, { projects: 1, goals: 0, resources: 1 });
r = await overview(U2);
assert.deepEqual([r.highlight, r.projects, r.areas, r.resources], [[], [], [], []]);
ok('013: archive_item manda al Archivo solo lo propio; cada jugador ve solo lo suyo');
