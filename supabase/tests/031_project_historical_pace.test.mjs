// Prueba la urgencia por ritmo histórico de 14 días (031) sobre 001–014.
import assert from 'node:assert/strict';

import { U1, U2, createFullDb, migration, ok } from './bootstrap.mjs';

const { db, one, asUser } = await createFullDb();
for (const f of ['003_security.sql', '004_structure.sql', '005_rewards.sql', '006_store.sql',
  '007_daily.sql', '008_fix_exploits.sql', '009_profile_titles.sql', '010_missions.sql',
  '011_habits.sql', '012_dungeon.sql', '013_stage.sql', '014_goals.sql']) {
  await db.exec(migration(f));
}
await db.exec(migration('031_project_historical_pace.sql'));
await db.exec(migration('031_project_historical_pace.sql'));
await db.exec(`insert into auth.users values ('${U1}', '{"username":"Ana"}'), ('${U2}', '{}')`);
ok('031 se aplica dos veces sin error');

const today = (await one('select current_date::text d')).d;
const overview = (uid) => asUser(uid, () =>
  one('select stage_overview($1::date) r', [today])).then((x) => x.r);
const projectId = await one(
  `insert into projects (user_id, title, start_date, end_date)
   values ($1, 'Proyecto histórico', current_date - 90, current_date + 10)
   returning id`,
  [U1],
).then((x) => x.id);

await db.query(`select set_config('lifequest.internal', 'on', false)`);
await db.query(
  `insert into tasks (user_id, project_id, title, status, completed_at)
   values
     ($1, $2, 'Completa reciente 1', 'completed', now() - interval '2 days'),
     ($1, $2, 'Completa reciente 2', 'completed', now() - interval '1 day'),
     ($1, $2, 'Pendiente 1', 'pending', null),
     ($1, $2, 'Pendiente 2', 'pending', null)`,
  [U1, projectId],
);
await db.query(`select set_config('lifequest.internal', 'off', false)`);

const project = (await overview(U1)).projects[0];
assert.deepEqual(
  [project.tasks_total, project.tasks_done, project.urgency],
  [4, 2, 'medium'],
);
assert.deepEqual((await overview(U2)).projects, []);
ok('031: Stage usa el ritmo reciente de tareas y mantiene el aislamiento RLS');

const recentWinsOverOld = await one(
  `select _project_urgency(4, 2, current_date - 90, current_date + 10,
                          current_date, 2) urgency`,
);
const noRecentFallsBack = await one(
  `select _project_urgency(4, 2, current_date - 90, current_date + 10,
                          current_date, 0) urgency`,
);
assert.equal(recentWinsOverOld.urgency, 'medium');
assert.equal(noRecentFallsBack.urgency, 'high');
ok('031: sin tareas recientes aplica el ritmo acumulado como fallback');
