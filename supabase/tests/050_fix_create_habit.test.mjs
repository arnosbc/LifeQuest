// Prueba la migración 050 (una sola create_habit) sobre 001–049.
// Uso: cd supabase/tests && node 050_fix_create_habit.test.mjs
import assert from 'node:assert/strict';
import { readdirSync } from 'node:fs';

import { U1, createFullDb, migration, ok, rejects } from './bootstrap.mjs';

const { db, one, asUser } = await createFullDb();
const files = readdirSync(new URL('../migrations/', import.meta.url))
  .filter((f) => f >= '003' && f < '050' && f.endsWith('.sql')).sort();
for (const f of files) await db.exec(migration(f));
await db.exec(`insert into auth.users values ('${U1}', '{}')`);

// Lo que deja volver a ejecutar 011 después de 039.
await db.exec(migration('011_habits.sql'));
// Como la app sin «versión mínima» (habits_remote_datasource.dart).
const call = `select create_habit(p_name => 'Leer', p_type => 'good', p_frequency => 'daily',
  p_specific_days => '{}', p_hp_penalty => 0, p_skill_id => null) id`;
await rejects(asUser(U1, () => one(call)), /is not unique/);
ok('050: reproduce «is not unique» como en Supabase');

await db.exec(migration('050_fix_create_habit.sql'));
await db.exec(migration('050_fix_create_habit.sql')); // idempotente
assert.equal((await one(`select count(*)::int n from pg_proc where proname = 'create_habit'`)).n, 1);
assert.ok((await asUser(U1, () => one(call))).id);
const withMin = await asUser(U1, () => one(`select create_habit(p_name => 'Correr',
  p_type => 'good', p_min_version => 'Ponerme los tenis') id`));
assert.ok(withMin.id);
ok('050: queda una sola create_habit y crear hábito funciona con y sin versión mínima');
