// Prueba la migración 042 (aviso antes de que un proyecto pase a 🔴) sobre 001–041.
// Uso: cd supabase/tests && node 042_project_alerts.test.mjs
import assert from 'node:assert/strict';
import { readdirSync } from 'node:fs';

import { U1, U2, createFullDb, migration, ok } from './bootstrap.mjs';

const { db, one, asUser } = await createFullDb();
const files = readdirSync(new URL('../migrations/', import.meta.url))
  .filter((f) => f >= '003' && f < '042' && f.endsWith('.sql')).sort();
for (const f of files) await db.exec(migration(f));
await db.exec(migration('042_project_alerts.sql'));
await db.exec(migration('042_project_alerts.sql')); // idempotente
await db.exec(`insert into auth.users values ('${U1}', '{}'), ('${U2}', '{}')`);
ok('042 se aplica dos veces sin error');

const today = (await one(`select (now() at time zone 'UTC')::date::text d`)).d;
const day = async (offset) => (await one(`select ($1::date + $2::int)::text d`, [today, offset])).d;
const ins = async (sql, p) => (await one(sql, p)).id;

// Va bien hoy (ritmo 0,5/día, necesita 0,42/día) y pasa a 🔴 en 4 días sin avanzar.
const slow = await ins(`insert into projects (user_id, title, start_date, end_date)
  values ($1, 'Lento', $2::date - 10, $2::date + 12) returning id`, [U1, today]);
await db.exec(`select set_config('lifequest.internal', 'on', false)`);
for (let i = 0; i < 10; i++) {
  await db.query(`insert into tasks (user_id, title, project_id, status, completed_at)
    values ($1, 'T', $2, $3, now() - interval '30 days')`, [U1, slow, i < 5 ? 'completed' : 'pending']);
}
await db.exec(`select set_config('lifequest.internal', '', false)`);
// Ya en 🔴 hoy: no se avisa otra vez. Sin fecha: nunca.
const late = await ins(`insert into projects (user_id, title, end_date) values ($1, 'Tarde', $2::date + 1) returning id`, [U1, today]);
await db.query(`insert into tasks (user_id, title, project_id) values ($1, 'X', $2)`, [U1, late]);
await ins(`insert into projects (user_id, title) values ($1, 'Sin fecha') returning id`, [U1]);

const plan = (uid) => asUser(uid, () => one(`select sync_reminders('UTC') r`)).then((x) => x.r);
const p1 = (await plan(U1)).projects;
assert.deepEqual(p1, [{ id: slow, title: 'Lento', day: await day(4) }]);
assert.deepEqual((await plan(U2)).projects, []);
ok('042: avisa el día en que pasaría a 🔴, no lo que ya está en 🔴 ni lo ajeno');

// Terminarlo quita el aviso.
await db.exec(`select set_config('lifequest.internal', 'on', false)`);
await db.query(`update tasks set status = 'completed', completed_at = now()
  where project_id = $1 and status = 'pending'`, [slow]);
await db.exec(`select set_config('lifequest.internal', '', false)`);
assert.deepEqual((await plan(U1)).projects, []);
ok('042: al terminar el proyecto, el aviso desaparece');
