// Prueba la migración 034 (editar y revisar) sobre 001–033: update_task,
// set_habit_reminder, habits_overview con aviso, weekly_review y postpone_task.
// Uso: cd supabase/tests && node 034_edit_review.test.mjs
import assert from 'node:assert/strict';
import { readdirSync } from 'node:fs';

import { U1, U2, createFullDb, migration, ok, rejects } from './bootstrap.mjs';

const { db, one, asUser } = await createFullDb();
const files = readdirSync(new URL('../migrations/', import.meta.url))
  .filter((f) => f >= '003' && f < '034' && f.endsWith('.sql')).sort();
for (const f of files) await db.exec(migration(f));
await db.exec(migration('034_edit_review.sql'));
await db.exec(migration('034_edit_review.sql')); // idempotente
await db.exec(`insert into auth.users values ('${U1}', '{"username":"Ana"}'), ('${U2}', '{}')`);
ok('034 se aplica dos veces sin error');

const as = (uid, sql, p) => asUser(uid, () => one(sql, p));
const run = (uid, sql, p) => asUser(uid, () => db.query(sql, p));
const task = (uid, title, due = null) =>
  as(uid, 'select create_task(p_title => $1, p_due_date => $2) r', [title, due]).then((x) => x.r.id);
const row = (id) => one('select * from tasks where id = $1', [id]);

// update_task -------------------------------------------------------------------
const t1 = await task(U1, 'Leer');
const xp = (await row(t1)).xp_reward;
await run(U1, `select update_task($1, 'Leer el capítulo 3 del libro', 'high',
  '2030-01-10T23:59:00Z', '2030-01-10T18:00:00Z', 45, 15, 'weekly:4', ' notas ')`, [t1]);
let t = await row(t1);
assert.deepEqual(
  [t.title, t.priority, t.estimated_minutes, t.reminder_minutes, t.repeat_rule, t.description],
  ['Leer el capítulo 3 del libro', 'high', 45, 15, 'weekly:4', 'notas'],
);
assert.equal(t.scheduled_at.toISOString(), '2030-01-10T18:00:00.000Z');
assert.equal(t.xp_reward, xp); // RF-112: editar no sube la recompensa
await run(U1, `select update_task($1, 'Leer', 'low', null, null, 30, 15, null)`, [t1]);
t = await row(t1);
assert.deepEqual([t.scheduled_at, t.reminder_minutes, t.repeat_rule, t.due_date], [null, null, null, null]);
await rejects(run(U1, `select update_task($1, '  ')`, [t1]), /invalid_title/);
await rejects(run(U1, `select update_task($1, 'X', 'low', null, null, null, null, 'cada lunes')`, [t1]),
  /tasks_repeat_rule_check/);
await rejects(run(U2, `select update_task($1, 'Mía')`, [t1]), /task_not_found/);
await as(U1, 'select complete_task($1)', [t1]);
await rejects(run(U1, `select update_task($1, 'Tarde')`, [t1]), /task_not_found/);
ok('034: update_task edita lo abierto y propio, sin tocar la recompensa');

// Aviso de hábitos ----------------------------------------------------------------
const good = await as(U1, `select create_habit('Meditar', 'good') id`).then((x) => x.id);
const bad = await as(U1, `select create_habit('Azúcar', 'bad', p_hp_penalty => 5) id`).then((x) => x.id);
await run(U1, `select set_habit_reminder($1, '07:30')`, [good]);
const day = (await one('select current_date::text d')).d;
const habits = (await as(U1, 'select habits_overview($1::date) r', [day])).r.habits;
assert.equal(habits.find((h) => h.id === good).reminder_time, '07:30');
assert.equal(habits.find((h) => h.id === bad).reminder_time, null);
await rejects(run(U1, `select set_habit_reminder($1, '07:30')`, [bad]), /habit_not_found/);
await rejects(run(U2, `select set_habit_reminder($1, '07:30')`, [good]), /habit_not_found/);
await run(U1, 'select set_habit_reminder($1, null)', [good]);
assert.equal((await one('select reminder_time from habits where id = $1', [good])).reminder_time, null);
ok('034: el aviso de un hábito bueno se pone, se quita y se ve en habits_overview');

// Revisión semanal ---------------------------------------------------------------
// Miércoles 7 ene 2026 → semana del lunes 5 al domingo 11.
const overdue = await task(U1, 'Vencida', '2025-12-20T12:00:00Z');
const thisWeek = await task(U1, 'Esta semana', '2026-01-09T12:00:00Z');
await task(U1, 'Próxima semana', '2026-01-14T12:00:00Z');
await task(U1, 'Sin fecha');
await task(U2, 'Ajena', '2026-01-08T12:00:00Z');
const review = (uid) => as(uid, `select weekly_review('2026-01-07', 0) r`).then((x) => x.r);
let r = await review(U1);
assert.equal(r.week_start, '2026-01-05');
assert.deepEqual(r.pending.map((p) => p.title), ['Vencida', 'Esta semana']);
assert.deepEqual((await review(U2)).pending.map((p) => p.title), ['Ajena']);
ok('034: weekly_review lista lo vencido y lo de esta semana, sin mezclar usuarios');

const future = await task(U1, 'Futura', '2030-01-09T12:00:00Z');
const due = (await as(U1, 'select postpone_task($1) r', [future])).r;
assert.equal(due.toISOString(), '2030-01-16T12:00:00.000Z');
await as(U1, 'select postpone_task($1)', [thisWeek]);
const now = Date.now();
const moved = (await as(U1, 'select postpone_task($1) r', [overdue])).r;
assert.ok(moved - now > 6.9 * 864e5 && moved - now < 7.1 * 864e5);
await rejects(as(U2, 'select postpone_task($1)', [thisWeek]), /task_not_found/);
r = await review(U1);
assert.deepEqual(r.pending.map((p) => p.title), []);
ok('034: postpone_task pasa la tarea a la semana siguiente (o a 7 días si ya venció)');
