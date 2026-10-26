// Prueba la migración 010 (Misiones) sobre 001–009: missions_overview y
// create_task, más complete_task de 005 desde la misma pantalla.
// Uso: cd supabase/tests && node 010_missions.test.mjs
import assert from 'node:assert/strict';

import { U1, U2, createFullDb, migration, ok, rejects } from './bootstrap.mjs';

const { db, one, asUser } = await createFullDb();
for (const f of ['003_security.sql', '004_structure.sql', '005_rewards.sql', '006_store.sql',
  '007_daily.sql', '008_fix_exploits.sql', '009_profile_titles.sql']) {
  await db.exec(migration(f));
}
await db.exec(migration('010_missions.sql'));
await db.exec(migration('010_missions.sql')); // idempotente
await db.exec(`insert into auth.users values ('${U1}', '{"username":"Ana"}'), ('${U2}', '{}')`);
ok('010 se aplica dos veces sin error');

const overview = (uid) => asUser(uid, () => one(`select missions_overview() r`)).then((x) => x.r);
const create = (uid, args) => asUser(uid, () => one(
  `select create_task(p_title => $1, p_description => $2, p_priority => $3, p_due_date => $4,
     p_skill_id => $5, p_project_id => $6, p_goal_id => $7, p_subtasks => $8) r`,
  [args.title, args.description ?? null, args.priority ?? 'low', args.due ?? null,
    args.skill ?? null, args.project ?? null, args.goal ?? null, args.subtasks ?? []])).then((x) => x.r);

const skill = (await one(`insert into skills (user_id, name) values ($1, 'Estudio') returning id`, [U1])).id;
const goal = (await one(`insert into goals (user_id, title) values ($1, 'Aprobar el curso') returning id`, [U1])).id;
const project = (await one(`insert into projects (user_id, title, goal_id) values ($1, 'Curso', $2) returning id`,
  [U1, goal])).id;
const foreignSkill = (await one(`insert into skills (user_id, name) values ($1, 'Ajena') returning id`, [U2])).id;

// Vacío ---------------------------------------------------------------------------
let r = await overview(U1);
assert.deepEqual(r.missions, []);
assert.deepEqual(r.skills.map((s) => s.name), ['Estudio']);
assert.deepEqual(r.projects.map((p) => [p.title, p.goal_id]), [['Curso', goal]]);
assert.deepEqual(r.goals.map((g) => g.title), ['Aprobar el curso']);
ok('010: overview vacío trae las opciones de vínculo propias');

// Crear -----------------------------------------------------------------------------
// Recompensa por reglas: 10 base + 10 título ≥ 5 palabras + 10 alta + 10 meta = 40.
const created = await create(U1, {
  title: '  Preparar la exposición del viernes  ', description: '  ', priority: 'high',
  skill, project, goal, subtasks: ['Guion', '  ', 'Diapositivas'],
});
assert.equal(created.xp_reward, 40);
assert.equal(created.coin_reward, 12);
const low = await create(U1, { title: 'Leer', due: new Date(Date.now() + 3 * 864e5).toISOString() });
assert.equal(low.xp_reward, 10);

r = await overview(U1);
assert.deepEqual(r.missions.map((m) => m.id), [created.id, low.id]); // high antes que low
const m = r.missions[0];
assert.equal(m.title, 'Preparar la exposición del viernes');
assert.equal(m.description, null);
assert.deepEqual([m.bucket, m.skill_name, m.project_title, m.goal_title], ['high', 'Estudio', 'Curso', 'Aprobar el curso']);
assert.deepEqual([m.subtasks_total, m.subtasks_done], [2, 0]);
const subs = (await db.query(`select title, goal_id, project_id, skill_id, xp_reward from tasks
  where parent_task_id = $1 order by title`, [created.id])).rows;
assert.deepEqual(subs.map((s) => [s.title, s.goal_id, s.project_id, s.skill_id]),
  [['Diapositivas', null, null, skill], ['Guion', null, null, skill]]);
ok('010: create_task aplica la recompensa del servidor y crea subtareas sin bonus de meta');

// Validaciones ------------------------------------------------------------------------
await rejects(create(U1, { title: '   ' }), /invalid_title/);
await rejects(create(U1, { title: 'x'.repeat(201) }), /invalid_title/);
await rejects(create(U1, { title: 'Hola', skill: foreignSkill }), /skill_not_found/);
await rejects(create(U2, { title: 'Hola', goal }), /goal_not_found/);
await rejects(create(U2, { title: 'Hola', project }), /project_not_found/);
await db.query(`update goals set archived_at = now() where id = $1`, [goal]);
await rejects(create(U1, { title: 'Hola', goal }), /goal_not_found/);
assert.deepEqual((await overview(U1)).goals, []);
await db.query(`update goals set archived_at = null where id = $1`, [goal]);
await db.exec(`select set_config('request.jwt.claim.sub', '', false); set role anon`);
await rejects(db.query(`select create_task('Hola')`), /permission denied/);
await db.exec('reset role');
ok('010: create_task rechaza título vacío o largo y vínculos ajenos o archivados');

// Aislamiento -----------------------------------------------------------------------
r = await overview(U2);
assert.deepEqual(r.missions, []);
assert.deepEqual(r.skills.map((s) => s.name), ['Ajena']);
assert.deepEqual([r.projects, r.goals], [[], []]);
ok('010: cada jugador solo ve sus misiones');

// Completar desde la pantalla (complete_task de 005) ---------------------------------
await db.query(`update tasks set created_at = now() - interval '1 hour'`);
await asUser(U1, () => db.query(`select complete_task($1)`, [low.id]));
r = await overview(U1);
assert.deepEqual(r.missions.map((x) => x.id), [created.id]);
await rejects(asUser(U2, () => db.query(`select complete_task($1)`, [created.id])), /task_not_found/);
ok('010: una misión completada sale de la lista; no se completa la de otro jugador');
