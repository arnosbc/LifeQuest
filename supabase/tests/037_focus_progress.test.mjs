// Prueba la migración 037 (Foco con pasos, progreso y semana) sobre 001–036.
// Uso: cd supabase/tests && node 037_focus_progress.test.mjs
import assert from 'node:assert/strict';
import { readdirSync } from 'node:fs';

import { U1, U2, createFullDb, migration, ok } from './bootstrap.mjs';

const { db, one, asUser } = await createFullDb();
const files = readdirSync(new URL('../migrations/', import.meta.url))
  .filter((f) => f >= '003' && f < '037' && f.endsWith('.sql')).sort();
for (const f of files) await db.exec(migration(f));
await db.exec(migration('037_focus_progress.sql'));
await db.exec(migration('037_focus_progress.sql')); // idempotente
await db.exec(`insert into auth.users values ('${U1}', '{}'), ('${U2}', '{}')`);
ok('037 se aplica dos veces sin error');

const as = (uid, sql, p) => asUser(uid, () => one(sql, p));
const overview = (uid) => as(uid, 'select dungeon_overview() r').then((x) => x.r);

// Sin sesión: progreso del personaje y semana en cero.
let r = await overview(U1);
assert.equal(r.session, null);
assert.equal(typeof r.progress.level, 'number');
assert.equal(typeof r.progress.xp_to_next_level, 'number');
assert.deepEqual(r.week, { minutes: 0, prev_minutes: 0 });

// Tarea con dos pasos; uno hecho.
const task = (await as(U1, `select create_task('Escribir informe') r`)).r.id;
await as(U1, `insert into tasks (user_id, parent_task_id, title) values ($1, $2, 'Esquema'), ($1, $2, 'Borrador')`, [U1, task]);
const steps = (await as(U1, `select array_agg(id order by title desc) ids from tasks where parent_task_id = $1`, [task])).ids;
await as(U1, 'select complete_task($1)', [steps[0]]);
await as(U1, 'select start_dungeon(60, 25, $1::uuid[])', [[task]]);

r = await overview(U1);
const t = r.session.tasks[0];
assert.equal(t.id, task);
// Mismo created_at: el orden lo decide el id; se compara ordenado.
assert.deepEqual(t.steps.map((s) => [s.title, s.done]).sort(), [['Borrador', false], ['Esquema', true]]);
ok('037: cada tarea de la sesión trae sus pasos con su estado');

// Una sesión de hace 10 días cuenta en la semana anterior.
await db.exec(`insert into focus_sessions (user_id, total_minutes, cycle_minutes, status, started_at, ended_at)
  values ('${U1}', 60, 25, 'completed', now() - interval '10 days', now() - interval '10 days' + interval '50 minutes')`);
r = await overview(U1);
assert.equal(r.week.prev_minutes, 50);
assert.equal(r.week.minutes, 0); // la sesión abierta acaba de empezar
assert.deepEqual((await overview(U2)).week, { minutes: 0, prev_minutes: 0 });
ok('037: week separa los últimos 7 días de los 7 anteriores, por usuario');
