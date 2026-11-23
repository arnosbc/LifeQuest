// Prueba la migración 048 (resumen del día, racha en peligro y límite) sobre 001–047.
// Uso: cd supabase/tests && node 048_day_nudges.test.mjs
import assert from 'node:assert/strict';
import { readdirSync } from 'node:fs';

import { U1, U2, createFullDb, migration, ok } from './bootstrap.mjs';

const { db, one, asUser } = await createFullDb();
const files = readdirSync(new URL('../migrations/', import.meta.url))
  .filter((f) => f >= '003' && f < '048' && f.endsWith('.sql')).sort();
for (const f of files) await db.exec(migration(f));
await db.exec(migration('048_day_nudges.sql'));
await db.exec(migration('048_day_nudges.sql')); // idempotente
await db.exec(`insert into auth.users values ('${U1}', '{}'), ('${U2}', '{}')`);
ok('048 se aplica dos veces sin error');

const today = (await one(`select (now() at time zone 'UTC')::date::text d`)).d;
const dow = (await one(`select extract(dow from $1::date)::int d`, [today])).d;
const ins = async (sql, p) => (await one(sql, p)).id;

await db.exec(`select set_config('lifequest.internal', 'on', false)`);
// Hoy: una tarea con fecha, una con bloque, una hecha (no cuenta), un recordatorio (no cuenta).
await db.query(`insert into tasks (user_id, title, due_date) values ($1, 'Fecha', now())`, [U1]);
await db.query(`insert into tasks (user_id, title, scheduled_at) values ($1, 'Bloque', now())`, [U1]);
await db.query(`insert into tasks (user_id, title, due_date, status, completed_at)
  values ($1, 'Hecha', now(), 'completed', now())`, [U1]);
await db.query(`insert into tasks (user_id, title, scheduled_at, is_reminder)
  values ($1, 'Llamar', now(), true)`, [U1]);
await db.query(`insert into tasks (user_id, title, due_date) values ($1, 'Mañana', now() + interval '1 day')`, [U1]);
// Hábitos: diario con racha 12, otro diario sin racha, uno solo mañana, uno malo (no cuenta).
const run = await ins(`insert into habits (user_id, name, type, current_streak)
  values ($1, 'Correr', 'good', 12) returning id`, [U1]);
await db.query(`insert into habits (user_id, name, type) values ($1, 'Leer', 'good')`, [U1]);
await db.query(`insert into habits (user_id, name, type, frequency, specific_days)
  values ($1, 'Yoga', 'good', 'specific_days', $2)`, [U1, [(dow + 1) % 7]]);
await db.query(`insert into habits (user_id, name, type, hp_penalty) values ($1, 'Fumar', 'bad', 5)`, [U1]);
await db.query(`update game_master_settings set notification_daily_limit = 4 where user_id = $1`, [U1]);
await db.exec(`select set_config('lifequest.internal', '', false)`);

const plan = (uid) => asUser(uid, () => one(`select sync_reminders('UTC') r`)).then((x) => x.r);
const p = await plan(U1);
assert.equal(p.days.length, 7);
assert.deepEqual(p.days[0], { day: today, tasks: 2, habits: 2, streak_habits: 1, best_streak: 12 });
assert.deepEqual({ ...p.days[1], day: undefined },
  { day: undefined, tasks: 1, habits: 3, streak_habits: 1, best_streak: 12 });
assert.equal(p.daily_limit, 4);
assert.equal(p.critical_bypass_silence, false);
assert.ok(Array.isArray(p.tasks) && Array.isArray(p.projects)); // lo de 032/042 sigue
ok('048: cuenta tareas y hábitos de cada día y la racha en peligro');

// Marcar el hábito hoy quita la racha en peligro de hoy, no la de mañana.
await db.exec(`select set_config('lifequest.internal', 'on', false)`);
await db.query(`insert into habit_records (habit_id, user_id, completed_on) values ($1, $2, $3)`,
  [run, U1, today]);
await db.exec(`select set_config('lifequest.internal', '', false)`);
const p2 = await plan(U1);
assert.equal(p2.days[0].streak_habits, 0);
assert.equal(p2.days[0].habits, 1);
assert.equal(p2.days[1].streak_habits, 1);
ok('048: al marcar el hábito, hoy ya no hay racha en peligro');

const other = await plan(U2);
assert.ok(other.days.every((d) => d.tasks === 0 && d.habits === 0));
ok('048: no ve lo de otro usuario');
