// Prueba la migración 043 (categoría de cada aviso) sobre 001–042.
// Uso: cd supabase/tests && node 043_notification_targets.test.mjs
import assert from 'node:assert/strict';
import { readdirSync } from 'node:fs';

import { U1, U2, createFullDb, migration, ok } from './bootstrap.mjs';

const { db, one, asUser } = await createFullDb();
const files = readdirSync(new URL('../migrations/', import.meta.url))
  .filter((f) => f >= '003' && f < '043' && f.endsWith('.sql')).sort();
for (const f of files) await db.exec(migration(f));
await db.exec(migration('043_notification_targets.sql'));
await db.exec(migration('043_notification_targets.sql')); // idempotente
await db.exec(`insert into auth.users values ('${U1}', '{}'), ('${U2}', '{}')`);
ok('043 se aplica dos veces sin error');

// Una tarea que vence hoy genera el aviso «due».
const today = (await one(`select current_date::text d`)).d;
await db.query(`insert into tasks (user_id, title, due_date) values ($1, 'Entregar', $2::date + time '20:00')`,
  [U1, today]);
const items = (await asUser(U1, () => one(`select notifications_overview($1::date) r`, [today]))).r.items;
assert.ok(items.length > 0);
assert.ok(items.every((i) => typeof i.category === 'string' && i.title));
assert.ok(items.some((i) => i.category === 'due'));
const other = (await asUser(U2, () => one(`select notifications_overview($1::date) r`, [today]))).r.items;
assert.ok(other.every((i) => i.category !== 'due'));
ok('043: cada aviso trae su categoría, sin mezclar usuarios');
