// Prueba la migración 046 (hábitos con hora y meta quieta en Hoy) sobre 001–045.
// Uso: cd supabase/tests && node 046_agenda_habits_goals.test.mjs
import assert from 'node:assert/strict';
import { readdirSync } from 'node:fs';

import { U1, U2, createFullDb, migration, ok } from './bootstrap.mjs';

const { db, one, asUser } = await createFullDb();
const files = readdirSync(new URL('../migrations/', import.meta.url))
  .filter((f) => f >= '003' && f < '046' && f.endsWith('.sql')).sort();
for (const f of files) await db.exec(migration(f));
await db.exec(migration('046_agenda_habits_goals.sql'));
await db.exec(migration('046_agenda_habits_goals.sql')); // idempotente
await db.exec(`insert into auth.users values ('${U1}', '{}'), ('${U2}', '{}')`);
ok('046 se aplica dos veces sin error');

const as = (uid, sql, p) => asUser(uid, () => one(sql, p));
const agenda = (uid) => as(uid, 'select day_agenda(current_date, 0) r').then((x) => x.r);

// Hábitos con hora ------------------------------------------------------------
const leer = (await as(U1, `select create_habit('Leer', 'good') id`)).id;
await as(U1, `select create_habit('Correr', 'good')`); // sin hora: no sale
const fumar = (await as(U1, `select create_habit('Fumar', 'bad', p_hp_penalty => 5) id`)).id;
await as(U1, `select set_habit_reminder($1, '21:15')`, [leer]);
await db.exec(`update habits set reminder_time = '08:00' where id = '${fumar}'`); // malo: no sale
let a = await agenda(U1);
assert.deepEqual(a.habit_times, [{ id: leer, reminder_time: '21:15:00' }]);
assert.ok(Array.isArray(a.scheduled)); // lo de antes sigue igual
assert.deepEqual((await agenda(U2)).habit_times, []);
ok('046: day_agenda trae los hábitos buenos de hoy con hora, solo del dueño');

// Meta quieta -----------------------------------------------------------------
const goal = (await as(U1, `select create_goal(p_title => 'Correr 10 km', p_specific => 's',
  p_measurable => 'm', p_achievable => 'a', p_relevant => 'r', p_due_date => current_date + 60) id`)).id;
assert.equal((await agenda(U1)).stalled_goal, null); // recién creada
await db.exec(`update goals set created_at = now() - interval '10 days' where id = '${goal}'`);
a = await agenda(U1);
assert.equal(a.stalled_goal.id, goal);
assert.equal(a.stalled_goal.next_task, null); // sin tareas: Hoy ofrece dividirla
const t1 = (await as(U1, `select create_task(p_title => 'Correr 3 km', p_goal_id => $1) r`, [goal])).r.id;
await as(U1, `select create_task(p_title => 'Correr 5 km', p_goal_id => $1)`, [goal]);
assert.deepEqual((await agenda(U1)).stalled_goal.next_task, { id: t1, title: 'Correr 3 km' });
await as(U1, 'select complete_task($1)', [t1]);
assert.equal((await agenda(U1)).stalled_goal, null); // avanzó esta semana
await db.exec(`update tasks set completed_at = now() - interval '8 days' where id = '${t1}'`);
assert.equal((await agenda(U1)).stalled_goal.next_task.title, 'Correr 5 km');
assert.equal((await agenda(U2)).stalled_goal, null);
ok('046: stalled_goal es la meta sin avance en 7 días, con su siguiente tarea');
