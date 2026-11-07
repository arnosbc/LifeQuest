// Prueba la migración 044 (Bandeja en el cierre del día) sobre 001–043.
// Uso: cd supabase/tests && node 044_review_inbox.test.mjs
import assert from 'node:assert/strict';
import { readdirSync } from 'node:fs';

import { U1, U2, createFullDb, migration, ok } from './bootstrap.mjs';

const { db, one, asUser } = await createFullDb();
const files = readdirSync(new URL('../migrations/', import.meta.url))
  .filter((f) => f >= '003' && f < '044' && f.endsWith('.sql')).sort();
for (const f of files) await db.exec(migration(f));
await db.exec(migration('044_review_inbox.sql'));
await db.exec(migration('044_review_inbox.sql')); // idempotente
await db.exec(`insert into auth.users values ('${U1}', '{}'), ('${U2}', '{}')`);
ok('044 se aplica dos veces sin error');

const as = (uid, sql, p) => asUser(uid, () => one(sql, p));
await as(U1, `select capture_thought('Idea uno')`);
await as(U1, `select capture_thought('Idea dos')`);
await as(U2, `select capture_thought('Ajena')`);
const r = (await as(U1, `select weekly_review(current_date, 0) r`)).r;
assert.equal(r.inbox, 2);
assert.ok(Array.isArray(r.pending)); // lo de antes sigue igual
assert.equal((await as(U2, `select weekly_review(current_date, 0) r`)).r.inbox, 1);
ok('044: la revisión cuenta las notas pendientes de la Bandeja de cada usuario');
