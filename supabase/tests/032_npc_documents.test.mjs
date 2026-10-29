// Prueba la migración 032 (documentos de contexto del NPC) sobre 001–031.
// Simula el esquema storage de Supabase (buckets, objects, foldername) para
// probar también las políticas del bucket.
// Uso: cd supabase/tests && node 032_npc_documents.test.mjs
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
grant select, insert, delete on storage.objects to authenticated;
`;

const { db, one, asUser } = await createFullDb();
await db.exec(STORAGE_STUB);
for (const f of ['003_security.sql', '004_structure.sql', '005_rewards.sql', '006_store.sql',
  '007_daily.sql', '008_fix_exploits.sql', '009_profile_titles.sql', '010_missions.sql',
  '011_habits.sql', '012_dungeon.sql', '013_stage.sql', '014_goals.sql', '015_onboarding.sql',
  '016_settings.sql', '017_dungeon_breaks.sql', '018_marketplace.sql', '019_tavern.sql',
  '020_journal.sql', '021_boss_fight.sql', '022_rpgenie.sql', '023_brain_dump.sql',
  '024_vision_board.sql', '025_stats.sql', '026_inventory.sql', '027_daily_chest.sql',
  '028_edit_delete.sql', '029_notifications.sql', '030_npc_noble_mission.sql',
  '031_npc_mission_guide.sql']) {
  await db.exec(migration(f));
}
await db.exec(migration('032_npc_documents.sql'));
await db.exec(migration('032_npc_documents.sql')); // idempotente
await db.exec(`insert into auth.users values ('${U1}', '{}'), ('${U2}', '{}')`);
assert.deepEqual(await one(`select public, file_size_limit::int size from storage.buckets where id = 'npc-context'`),
  { public: false, size: 10485760 });
ok('032 se aplica dos veces sin error y crea el bucket privado de 10 MB');

const call = (uid, sql, params) => asUser(uid, () => one(sql, params)).then((x) => x && x.r);
const skill = (await one(`insert into skills (user_id, name) values ($1, 'Programación') returning id`, [U1])).id;
const npc = (await call(U1, `select create_npc('Ada', $1, 'weekly', 'Programación móvil') r`, [skill]));
const path = (file) => `${U1}/${npc}/${file}`;
const add = (uid, title, p, summary = 'Unidad 1: Flutter. Unidad 2: estado.') =>
  call(uid, `select add_npc_document($1, $2, $3, $4) r`, [npc, title, p, summary]);

const doc = await add(U1, '  Plan de asignatura  ', path('plan.docx'));
assert.deepEqual(await one(`select title, file_url, ai_summary, npc_id from resources where id = $1`, [doc]),
  { title: 'Plan de asignatura', file_url: path('plan.docx'),
    ai_summary: 'Unidad 1: Flutter. Unidad 2: estado.', npc_id: npc });
let t = await call(U1, `select tavern_overview() r`);
assert.deepEqual(t.npcs[0].documents, [{ id: doc, title: 'Plan de asignatura' }]);
ok('032: add_npc_document guarda el resumen y tavern_overview lista los documentos');

await rejects(add(U1, ' ', path('a.pdf')), /invalid_title/);
await rejects(add(U1, 'Ajeno', `${U2}/${npc}/a.pdf`), /invalid_path/);
await rejects(add(U1, 'Otro NPC', `${U1}/otro/a.pdf`), /invalid_path/);
await rejects(add(U1, 'Vacío', path('a.pdf'), '  '), /invalid_summary/);
await rejects(add(U1, 'Largo', path('a.pdf'), 'x'.repeat(8001)), /invalid_summary/);
await rejects(add(U2, 'Intruso', `${U2}/${npc}/a.pdf`), /npc_not_found/);
await add(U1, 'Rúbrica', path('rubrica.pdf'));
await add(U1, 'Notas', path('notas.md'));
await rejects(add(U1, 'Cuarto', path('cuarto.pdf')), /npc_document_limit/);
ok('032: valida título, ruta propia, resumen, NPC ajeno y máx. 3 documentos por NPC');

assert.equal(await call(U1, `select remove_npc_document($1) r`, [doc]), path('plan.docx'));
await rejects(call(U1, `select remove_npc_document($1) r`, [doc]), /document_not_found/);
const other = (await one(`select id from resources where title = 'Rúbrica'`)).id;
await rejects(call(U2, `select remove_npc_document($1) r`, [other]), /document_not_found/);
t = await call(U1, `select tavern_overview() r`);
assert.deepEqual(t.npcs[0].documents.map((d) => d.title), ['Rúbrica', 'Notas']);
ok('032: remove_npc_document borra solo lo propio y devuelve la ruta del archivo');

// Storage: cada usuario solo ve, sube y borra en su carpeta del bucket.
const put = (uid, name) => asUser(uid, () => db.query(
  `insert into storage.objects (bucket_id, name) values ('npc-context', $1)`, [name]));
await put(U1, path('plan.pdf'));
await rejects(put(U1, `${U2}/x/plan.pdf`), /row-level security/);
await put(U2, `${U2}/x/suyo.pdf`);
const seen = (uid) => asUser(uid, () => db.query(`select name from storage.objects order by name`))
  .then((r) => r.rows.map((x) => x.name));
assert.deepEqual(await seen(U1), [path('plan.pdf')]);
assert.deepEqual(await seen(U2), [`${U2}/x/suyo.pdf`]);
await asUser(U2, () => db.query(`delete from storage.objects where name = $1`, [path('plan.pdf')]));
assert.deepEqual(await seen(U1), [path('plan.pdf')]);
ok('032: las políticas del bucket aíslan los archivos entre usuarios');
