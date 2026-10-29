// Prueba supabase/migrations/018_social_login.sql (nombre del perfil para las
// cuentas de Google y Apple), aplicada sobre 001_home.sql y 002_profile.sql.
// Uso: cd supabase/tests && npm install && npm test
import assert from 'node:assert/strict';

import { createDb, migration, ok } from './bootstrap.mjs';

const { db, one } = await createDb();
await db.exec(migration('001_home.sql'));
await db.exec(migration('002_profile.sql'));
await db.exec(migration('018_social_login.sql'));
await db.exec(migration('018_social_login.sql')); // idempotente

const ids = {
  email: '00000000-0000-0000-0000-0000000000a1',
  google: '00000000-0000-0000-0000-0000000000a2',
  apple: '00000000-0000-0000-0000-0000000000a3',
  blank: '00000000-0000-0000-0000-0000000000a4',
  long: '00000000-0000-0000-0000-0000000000a5',
  empty: '00000000-0000-0000-0000-0000000000a6',
};
const longName = 'A'.repeat(60);
await db.query(
  `insert into auth.users values
    ($1, '{"username":"Ana","full_name":"Ana Pérez"}'),
    ($2, '{"full_name":"  Leo Gómez  ","name":"Leo"}'),
    ($3, '{"name":"Sol"}'),
    ($4, '{"username":"   ","full_name":"Mar Ruiz"}'),
    ($5, $7),
    ($6, '{}')`,
  [ids.email, ids.google, ids.apple, ids.blank, ids.long, ids.empty,
    JSON.stringify({ full_name: longName })],
);

const name = async (id) =>
  (await one(`select display_name from profiles where id = $1`, [id])).display_name;

// 1. El registro con correo sigue usando el nombre de usuario.
assert.equal(await name(ids.email), 'Ana');
ok('correo: manda username');

// 2. Google trae full_name (recortado); Apple puede traer solo name.
assert.equal(await name(ids.google), 'Leo Gómez');
assert.equal(await name(ids.apple), 'Sol');
ok('Google y Apple: full_name o name');

// 3. Un username en blanco no tapa el nombre de la cuenta externa.
assert.equal(await name(ids.blank), 'Mar Ruiz');
ok('username vacío pasa al siguiente');

// 4. Nunca falla el alta: nombres largos se recortan y sin nombre queda null.
assert.equal(await name(ids.long), 'A'.repeat(40));
assert.equal(await name(ids.empty), null);
assert.ok(await one(`select 1 as ok from character_stats where user_id = $1`, [ids.empty]));
assert.ok(await one(`select 1 as ok from game_master_settings where user_id = $1`, [ids.empty]));
ok('nombres largos recortados; sin nombre, el alta sigue');
