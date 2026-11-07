// Prueba la migración 039 (cierre del día y versión mínima) sobre 001–038.
// Uso: cd supabase/tests && node 039_day_close_habits.test.mjs
import assert from 'node:assert/strict';
import { readdirSync } from 'node:fs';

import { U1, U2, createFullDb, migration, ok, rejects } from './bootstrap.mjs';

const { db, one, asUser } = await createFullDb();
const files = readdirSync(new URL('../migrations/', import.meta.url))
  .filter((f) => f >= '003' && f < '039' && f.endsWith('.sql')).sort();
for (const f of files) await db.exec(migration(f));
await db.exec(migration('039_day_close_habits.sql'));
await db.exec(migration('039_day_close_habits.sql')); // idempotente
await db.exec(`insert into auth.users values ('${U1}', '{}'), ('${U2}', '{}')`);
ok('039 se aplica dos veces sin error');

const as = (uid, sql, p) => asUser(uid, () => one(sql, p));

// Posponer: 1 día para el cierre del día; sin p_days sigue siendo 7.
const future = '2030-01-09T12:00:00Z';
const t1 = (await as(U1, `select create_task(p_title => 'Uno', p_due_date => $1) r`, [future])).r.id;
const t2 = (await as(U1, `select create_task(p_title => 'Dos', p_due_date => $1) r`, [future])).r.id;
assert.equal((await as(U1, 'select postpone_task($1, 1) r', [t1])).r.toISOString(), '2030-01-10T12:00:00.000Z');
assert.equal((await as(U1, 'select postpone_task($1) r', [t2])).r.toISOString(), '2030-01-16T12:00:00.000Z');
await rejects(as(U1, 'select postpone_task($1, 0)', [t1]), /invalid_days/);
await rejects(as(U2, 'select postpone_task($1, 1)', [t1]), /task_not_found/);
ok('039: postpone_task mueve N días (por defecto 7) y valida dueño y rango');

// Versión mínima.
const h = (await as(U1, `select create_habit(p_name => 'Leer', p_type => 'good',
  p_min_version => '  Leer 1 página ') r`)).r;
await as(U1, `select create_habit('Correr', 'good')`); // firma vieja por posición
await rejects(as(U1, `select create_habit(p_name => 'Fumar', p_type => 'bad', p_hp_penalty => 5,
  p_min_version => 'algo')`), /invalid_min_version/);
await rejects(as(U1, `select create_habit(p_name => 'X', p_type => 'good',
  p_min_version => $1)`, ['a'.repeat(101)]), /invalid_min_version/);
const list = (await as(U1, `select habits_overview(current_date) r`)).r.habits;
assert.equal(list.find((x) => x.id === h).min_version, 'Leer 1 página');
assert.equal(list.find((x) => x.name === 'Correr').min_version, null);
assert.equal((await as(U2, `select habits_overview(current_date) r`)).r.habits.length, 0);
ok('039: create_habit guarda la versión mínima (solo hábitos buenos) y habits_overview la devuelve');
