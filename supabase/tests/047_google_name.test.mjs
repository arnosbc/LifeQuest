// Prueba supabase/migrations/047_google_name.sql (nombre del perfil al entrar con Google).
// Uso: cd supabase/tests && npm install && npm test
import assert from 'node:assert/strict';

import { U1, U2, createDb, migration, ok } from './bootstrap.mjs';

const { db, one } = await createDb();
await db.exec(migration('001_home.sql'));
await db.exec(migration('002_profile.sql'));
await db.exec(migration('047_google_name.sql'));
await db.exec(migration('047_google_name.sql')); // idempotente
const U3 = '00000000-0000-0000-0000-000000000003';
await db.exec(`insert into auth.users values
  ('${U1}', '{"username":" Ana "}'),
  ('${U2}', '{"full_name":"Leo Pérez","name":"Leo"}'),
  ('${U3}', '{"username":"","name":"${'x'.repeat(50)}"}')`);

const name = async (id) => (await one(`select display_name from profiles where id = $1`, [id])).display_name;
assert.equal(await name(U1), 'Ana');
assert.equal(await name(U2), 'Leo Pérez');
assert.equal(await name(U3), 'x'.repeat(40));
ok('display_name: username, luego full_name/name de Google, recortado a 40');
