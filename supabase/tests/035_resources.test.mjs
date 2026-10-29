// Prueba la migración 035 (recursos: enlaces, notas, documentos y vínculos)
// sobre 001–034. Simula el esquema storage de Supabase como 032.
// Uso: cd supabase/tests && node 035_resources.test.mjs
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
  '031_npc_mission_guide.sql', '032_npc_documents.sql', '033_dungeon_rewards.sql',
  '034_brain_dump_goal.sql']) {
  await db.exec(migration(f));
}
await db.exec(`insert into auth.users values ('${U1}', '{}'), ('${U2}', '{}')`);

// Datos de antes: un enlace (013) y un documento de NPC (032).
const call = (uid, sql, params) => asUser(uid, () => one(sql, params)).then((x) => x && x.r);
const skill = (await one(`insert into skills (user_id, name) values ($1, 'Estudio') returning id`, [U1])).id;
const oldLink = await call(U1, `select create_resource('Docs de Flutter', 'https://docs.flutter.dev') r`);
const npc = await call(U1, `select create_npc('Ada', $1, 'weekly', 'Programación móvil') r`, [skill]);
const npcDoc = await call(U1, `select add_npc_document($1, 'Plan', $2, 'Unidad 1') r`,
  [npc, `${U1}/${npc}/plan.pdf`]);

await db.exec(migration('035_resources.sql'));
await db.exec(migration('035_resources.sql')); // idempotente
assert.deepEqual(await one(`select kind, storage_bucket from resources where id = $1`, [oldLink]),
  { kind: 'link', storage_bucket: null });
assert.deepEqual(await one(`select kind, storage_bucket from resources where id = $1`, [npcDoc]),
  { kind: 'document', storage_bucket: 'npc-context' });
assert.deepEqual(await one(`select public, file_size_limit::int size from storage.buckets where id = 'resources'`),
  { public: false, size: 10485760 });
ok('035 se aplica dos veces y migra enlaces y documentos de NPC existentes');

// La llamada antigua de dos argumentos sigue funcionando.
assert.ok(await call(U1, `select create_resource('Pub.dev', 'https://pub.dev') r`));
// Los documentos nuevos de NPC ya entran como 'document'.
const npcDoc2 = await call(U1, `select add_npc_document($1, 'Rúbrica', $2, 'Criterios') r`,
  [npc, `${U1}/${npc}/rubrica.pdf`]);
assert.equal((await one(`select kind from resources where id = $1`, [npcDoc2])).kind, 'document');
ok('035: create_resource(p_title, p_url) y add_npc_document siguen funcionando');

const project = await call(U1, `select create_project('App móvil', null, null, $1) r`, [skill]);
const create = (uid, args) => call(uid, `select create_resource(p_title => $1, p_kind => $2::resource_kind,
  p_url => $3, p_content => $4, p_path => $5, p_project_id => $6, p_goal_id => $7, p_skill_id => $8) r`,
  [args.title ?? 'Recurso', args.kind, args.url ?? null, args.content ?? null, args.path ?? null,
   args.project ?? null, args.goal ?? null, args.skill ?? null]);

const note = await create(U1, { title: 'Apuntes de Bloc', kind: 'note',
  content: '  Un Bloc recibe eventos y emite estados.  ', project, skill });
const doc = await create(U1, { title: 'Enunciado', kind: 'document', path: `${U1}/enunciado.pdf`, project });
assert.deepEqual(await one(`select kind, content, file_url, project_id, skill_id from resources where id = $1`,
  [note]), { kind: 'note', content: 'Un Bloc recibe eventos y emite estados.', file_url: null,
  project_id: project, skill_id: skill });
assert.deepEqual(await one(`select kind, file_url, storage_bucket from resources where id = $1`, [doc]),
  { kind: 'document', file_url: `${U1}/enunciado.pdf`, storage_bucket: 'resources' });
ok('035: crea notas y documentos vinculados a proyecto y skill');

await rejects(create(U1, { kind: 'note', content: '  ' }), /invalid_content/);
await rejects(create(U1, { kind: 'note', content: 'x'.repeat(10001) }), /invalid_content/);
await rejects(create(U1, { kind: 'link', url: 'ftp://x' }), /invalid_url/);
await rejects(create(U1, { kind: 'document', path: `${U2}/ajeno.pdf` }), /invalid_path/);
await rejects(create(U1, { kind: 'document' }), /invalid_path/);
const foreignSkill = (await one(`insert into skills (user_id, name) values ($1, 'Ajena') returning id`, [U2])).id;
await rejects(create(U1, { kind: 'note', content: 'x', skill: foreignSkill }), /skill_not_found/);
await rejects(create(U2, { kind: 'note', content: 'x', project }), /project_not_found/);
await rejects(create(U1, { kind: 'note', content: 'x', goal: project }), /goal_not_found/);
ok('035: valida el contenido de cada tipo, la ruta propia y que los vínculos sean del jugador');

const today = (await one(`select current_date::text d`)).d;
const board = await call(U1, `select stage_overview($1::date) r`, [today]);
const byTitle = Object.fromEntries(board.resources.map((r) => [r.title, r]));
assert.deepEqual(
  [byTitle['Apuntes de Bloc'].kind, byTitle['Apuntes de Bloc'].content,
   byTitle['Apuntes de Bloc'].project_title, byTitle['Apuntes de Bloc'].skill_name],
  ['note', 'Un Bloc recibe eventos y emite estados.', 'App móvil', 'Estudio']);
assert.deepEqual([byTitle.Enunciado.kind, byTitle.Enunciado.path, byTitle.Enunciado.bucket, byTitle.Enunciado.url],
  ['document', `${U1}/enunciado.pdf`, 'resources', null]);
assert.deepEqual([byTitle.Plan.bucket, byTitle.Plan.npc_name], ['npc-context', 'Ada']);
assert.equal(byTitle['Docs de Flutter'].url, 'https://docs.flutter.dev');
assert.deepEqual((await call(U2, `select stage_overview($1::date) r`, [today])).resources, []);
ok('035: stage_overview devuelve tipo, nota, ruta y vínculos, aislado por jugador');

// Borrar el proyecto deja el recurso sin vínculo (ON DELETE SET NULL).
await db.query(`delete from tasks where project_id = $1`, [project]);
await db.query(`delete from projects where id = $1`, [project]);
assert.equal((await one(`select project_id from resources where id = $1`, [note])).project_id, null);

// Storage: el bucket `resources` aísla las carpetas.
const put = (uid, name) => asUser(uid, () => db.query(
  `insert into storage.objects (bucket_id, name) values ('resources', $1)`, [name]));
await put(U1, `${U1}/a.pdf`);
await rejects(put(U1, `${U2}/b.pdf`), /row-level security/);
ok('035: los vínculos se sueltan al borrar el proyecto y el bucket aísla a cada jugador');
