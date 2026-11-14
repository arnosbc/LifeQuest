// Prueba la migración 054 (reloj de push con _push_tick) con stubs de pg_cron,
// pg_net y Vault. Uso: cd supabase/tests && node 054_push_tick.test.mjs
import assert from 'node:assert/strict';

import { createDb, migration, ok, rejects } from './bootstrap.mjs';

const { db, one } = await createDb();
// Stubs mínimos de las extensiones de Supabase.
await db.exec(`
  create schema cron; create schema net; create schema vault;
  create table cron.job (jobid serial primary key, jobname text, schedule text, command text);
  create function cron.schedule(n text, s text, c text) returns bigint language sql as
    $$ insert into cron.job (jobname, schedule, command) values (n, s, c) returning jobid $$;
  create function cron.unschedule(id bigint) returns boolean language sql as
    $$ delete from cron.job where jobid = id returning true $$;
  create table net.calls (url text, headers jsonb, body jsonb);
  create function net.http_post(url text, body jsonb default '{}', params jsonb default '{}',
    headers jsonb default '{}', timeout_milliseconds int default 5000) returns bigint language sql as
    $$ insert into net.calls values (url, headers, body); select 7::bigint $$;
  create table vault.decrypted_secrets (name text, decrypted_secret text);`);
// PGlite no trae pg_cron: la parte del reloj solo se comprueba si existe.
const hasCron = (await one(`select exists (select 1 from pg_extension where extname = 'pg_cron') e`)).e;

await db.exec(migration('054_push_tick.sql'));
await db.exec(migration('054_push_tick.sql'));
ok('054 se aplica dos veces sin error');

await rejects(db.query(`select public._push_tick()`), /push_secrets_missing/);
await db.exec(`insert into vault.decrypted_secrets values
  ('lifequest_project_url', 'https://demo.supabase.co/'), ('lifequest_push_secret', 's3cr3t')`);
assert.equal((await one(`select public._push_tick() r`)).r, 7);
const call = await one(`select * from net.calls`);
assert.equal(call.url, 'https://demo.supabase.co/functions/v1/push-dispatch');
assert.equal(call.headers['x-push-secret'], 's3cr3t');
ok('054: _push_tick llama a push-dispatch con la clave del Vault (y avisa si falta)');

if (hasCron) {
  const jobs = await db.query(`select command from cron.job where jobname = 'lifequest_push'`);
  assert.deepEqual(jobs.rows, [{ command: 'select public._push_tick()' }]);
  ok('054: un solo reloj con un comando simple');
}
