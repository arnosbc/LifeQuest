// Prueba la migración 047 (imágenes de los documentos) sobre 001–046.
// Simula el esquema storage de Supabase como 035.
// Uso: cd supabase/tests && node 047_document_images.test.mjs
import assert from 'node:assert/strict';

import { U1, U2, createFullDb, migration, ok, rejects } from './bootstrap.mjs';

const STORAGE_STUB = `
create schema storage;
create table storage.buckets (id text primary key, name text not null, public boolean default false,
  file_size_limit bigint, allowed_mime_types text[]);
create table storage.objects (id uuid primary key default gen_random_uuid(), bucket_id text,
  name text not null, owner uuid default auth.uid());
alter table storage.objects enable row level security;
create function storage.foldername(name text) returns text[] language sql immutable as
  $$ select (string_to_array(name, '/'))[1:array_length(string_to_array(name, '/'), 1) - 1] $$;
grant usage on schema storage to anon, authenticated;
grant select, insert, update, delete on storage.objects to authenticated;
`;

const { db, one, asUser } = await createFullDb();
await db.exec(STORAGE_STUB);
for (const f of ['003_security.sql', '004_structure.sql', '005_rewards.sql', '006_store.sql',
  '007_daily.sql', '008_fix_exploits.sql', '009_profile_titles.sql', '010_missions.sql',
  '046_documents.sql', '047_document_images.sql', '047_document_images.sql']) {
  await db.exec(migration(f));
}
await db.exec(`insert into auth.users values ('${U1}', '{}'), ('${U2}', '{}')`);
ok('047 se aplica dos veces sin error');

const bucket = await one(`select public, file_size_limit, allowed_mime_types from storage.buckets where id = 'documents'`);
assert.equal(bucket.public, false);
assert.equal(Number(bucket.file_size_limit), 10485760);
assert.ok(bucket.allowed_mime_types.includes('image/png'));
ok('047: bucket privado de imágenes con límite de 10 MB');

const mine = `${U1}/doc1/foto.jpg`;
await asUser(U1, () => db.query(`insert into storage.objects (bucket_id, name) values ('documents', $1)`, [mine]));
assert.equal(await asUser(U1, () => one(`select count(*)::int n from storage.objects`)).then((x) => x.n), 1);
assert.equal(await asUser(U2, () => one(`select count(*)::int n from storage.objects`)).then((x) => x.n), 0);
await rejects(asUser(U2, () => db.query(
  `insert into storage.objects (bucket_id, name) values ('documents', $1)`, [`${U1}/doc1/intruso.jpg`])), /row-level security/);
await asUser(U2, () => db.query(`delete from storage.objects where name = $1`, [mine]));
assert.equal((await one(`select count(*)::int n from storage.objects`)).n, 1);
ok('047: cada usuario solo ve y escribe en su carpeta');
