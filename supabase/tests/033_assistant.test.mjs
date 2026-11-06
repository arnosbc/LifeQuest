// Prueba la migración 033 (asistente con IA) sobre 001–032: interruptor
// apagado por defecto, tope diario, estado y aislamiento entre usuarios.
// Uso: cd supabase/tests && node 033_assistant.test.mjs
import assert from 'node:assert/strict';
import { readdirSync } from 'node:fs';

import { U1, U2, createFullDb, migration, ok, rejects } from './bootstrap.mjs';

const { db, one, asUser } = await createFullDb();
const files = readdirSync(new URL('../migrations/', import.meta.url))
  .filter((f) => f >= '003' && f < '033' && f.endsWith('.sql')).sort();
for (const f of files) await db.exec(migration(f));
await db.exec(migration('033_assistant.sql'));
await db.exec(migration('033_assistant.sql')); // idempotente
await db.exec(`insert into auth.users values ('${U1}', '{"username":"Ana"}'), ('${U2}', '{}')`);
ok('033 se aplica dos veces sin error');

const as = (uid, sql) => asUser(uid, () => one(sql));
const status = (uid) => as(uid, 'select assistant_status() r').then((x) => x.r);

assert.deepEqual(await status(U1), { ai_enabled: false, calls_left: 40 });
assert.equal((await as(U1, 'select settings_overview() r')).r.ai_enabled, false);
await rejects(as(U1, 'select consume_ai_call()'), /ai_disabled/);
ok('033: la IA viene apagada y sin activarla no se gasta nada');

await asUser(U1, () => db.query('update game_master_settings set ai_enabled = true'));
assert.equal((await as(U1, 'select consume_ai_call() r')).r, 39);
assert.deepEqual(await status(U1), { ai_enabled: true, calls_left: 39 });
assert.equal((await as(U1, 'select settings_overview() r')).r.ai_enabled, true);
assert.deepEqual(await status(U2), { ai_enabled: false, calls_left: 40 });
await rejects(as(U2, 'select consume_ai_call()'), /ai_disabled/);
ok('033: activarla es por usuario y cada llamada se cuenta');

await db.query(`update ai_usage set calls = 39 where user_id = $1`, [U1]);
assert.equal((await as(U1, 'select consume_ai_call() r')).r, 0);
await rejects(as(U1, 'select consume_ai_call()'), /ai_limit/);
assert.equal((await one(`select calls from ai_usage where user_id = $1`, [U1])).calls, 40);
await rejects(asUser(U1, () => db.query(`update ai_usage set calls = 0`)), /permission denied/);
await rejects(asUser(U1, () => db.query(
  `insert into ai_usage values ('${U1}', current_date + 1, 0)`)), /permission denied/);
assert.equal((await asUser(U2, () => db.query('select * from ai_usage'))).rows.length, 0);
ok('033: el tope de 40 al día corta sin contar de más y el cliente no puede reiniciarlo');
