// Prueba la migración 041 (orden estable de tareas) sobre 001–040.
// Uso: cd supabase/tests && node 041_task_order.test.mjs
import assert from 'node:assert/strict';
import { readdirSync } from 'node:fs';

import { U1, createFullDb, migration, ok } from './bootstrap.mjs';

const { db, one, asUser } = await createFullDb();
const files = readdirSync(new URL('../migrations/', import.meta.url))
  .filter((f) => f >= '003' && f < '041' && f.endsWith('.sql')).sort();
for (const f of files) await db.exec(migration(f));
await db.exec(`insert into auth.users values ('${U1}', '{}')`);

// Empate viejo: tres tareas en la misma transacción, fechas al revés del id.
await db.exec(`begin;
  insert into tasks (id, user_id, title, due_date) values
    ('00000000-0000-0000-0000-00000000000c', '${U1}', 'Primera', '2030-01-01'),
    ('00000000-0000-0000-0000-00000000000b', '${U1}', 'Segunda', '2030-01-02'),
    ('00000000-0000-0000-0000-00000000000a', '${U1}', 'Tercera', '2030-01-03');
  commit;`);
await db.exec(migration('041_task_order.sql'));
await db.exec(migration('041_task_order.sql')); // idempotente
ok('041 se aplica dos veces sin error');

const order = async () =>
  (await db.query(`select title from tasks where user_id = $1 order by created_at`, [U1]))
    .rows.map((r) => r.title);
assert.deepEqual(await order(), ['Primera', 'Segunda', 'Tercera']);
ok('041: los empates viejos se ordenan por fecha límite');

// Nuevo: create_task con subtareas las deja en el orden escrito.
const t = (await asUser(U1, () => one(`select create_task(p_title => 'Informe largo de este mes',
  p_subtasks => array['Uno', 'Dos', 'Tres', 'Cuatro']) r`))).r;
const steps = (await db.query(`select title from tasks where parent_task_id = $1 order by created_at`,
  [t.id])).rows.map((r) => r.title);
assert.deepEqual(steps, ['Uno', 'Dos', 'Tres', 'Cuatro']);
ok('041: las subtareas nuevas salen en el orden en que se escribieron');
