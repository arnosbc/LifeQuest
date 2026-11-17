// Prueba la migración 046 (Taller de documentos) sobre 001–045.
// Uso: cd supabase/tests && node 046_documents.test.mjs
import assert from 'node:assert/strict';

import { U1, U2, createFullDb, migration, ok, rejects } from './bootstrap.mjs';

const { db, one, asUser } = await createFullDb();
for (const f of ['003_security.sql', '004_structure.sql', '005_rewards.sql', '006_store.sql',
  '007_daily.sql', '008_fix_exploits.sql', '009_profile_titles.sql', '010_missions.sql',
  '046_documents.sql', '046_documents.sql']) {
  await db.exec(migration(f));
}
await db.exec(`insert into auth.users values ('${U1}', '{"username":"Ana"}'), ('${U2}', '{}')`);
ok('046 se aplica dos veces sin error');

const D1 = 'aaaaaaaa-0000-0000-0000-000000000001';
const task = (await one(`insert into tasks (user_id, title) values ($1, 'Ensayo') returning id`, [U1])).id;

// El dueño crea (con id del cliente y tarea), edita y marca borrado.
await asUser(U1, () => db.query(
  `insert into documents (id, task_id, title, content) values ($1, $2, 'Ensayo', '# Hola')`, [D1, task]));
await asUser(U1, () => db.query(
  `update documents set content = '# Hola mundo', updated_at = now() where id = $1`, [D1]));
const mine = await asUser(U1, () => one(`select user_id, content from documents where id = $1`, [D1]));
assert.equal(mine.user_id, U1);
assert.equal(mine.content, '# Hola mundo');
await asUser(U1, () => db.query(`update documents set deleted_at = now() where id = $1`, [D1]));
ok('046: el dueño crea, edita y marca borrado su documento');

// Otro usuario no lo ve, no lo edita y nadie borra filas desde el cliente.
assert.equal(await asUser(U2, () => one(`select count(*)::int n from documents`)).then((x) => x.n), 0);
await asUser(U2, () => db.query(`update documents set content = 'x' where id = $1`, [D1]));
assert.equal((await one(`select content from documents where id = $1`, [D1])).content, '# Hola mundo');
await rejects(asUser(U2, () => db.query(
  `insert into documents (id, user_id, title) values (gen_random_uuid(), $1, 'Robo')`, [U1])), /row-level security/);
await rejects(asUser(U1, () => db.query(`delete from documents where id = $1`, [D1])), /permission denied/);
ok('046: RLS aísla los documentos de cada usuario y no se borran filas');

// Borrar la tarea deja el documento sin vínculo.
await db.query(`delete from tasks where id = $1`, [task]);
assert.equal((await one(`select task_id from documents where id = $1`, [D1])).task_id, null);
ok('046: borrar la tarea deja el documento sin vínculo');
