// Prueba la migración 045 (recursos adjuntos, Dónde lo dejé, prueba de paso).
// Uso: cd supabase/tests && node 045_resources.test.mjs
import assert from 'node:assert/strict';
import { readdirSync } from 'node:fs';

import { U1, U2, createFullDb, migration, ok } from './bootstrap.mjs';

const { db, one, asUser } = await createFullDb();
const files = readdirSync(new URL('../migrations/', import.meta.url))
  .filter((f) => f >= '003' && f < '045' && f.endsWith('.sql')).sort();
for (const f of files) await db.exec(migration(f));
await db.exec(migration('045_resources.sql'));
await db.exec(migration('045_resources.sql')); // idempotente
await db.exec(`insert into auth.users values ('${U1}', '{}'), ('${U2}', '{}')`);
ok('045 se aplica dos veces sin error');

const as = (uid, sql, p) => asUser(uid, () => one(sql, p));
const fails = (uid, sql, p, code) =>
  assert.rejects(as(uid, sql, p), (e) => (code ? e.message.includes(code) : true));

const task = (await as(U1, `select create_task('Estudiar cálculo') r`)).r.id;
const path = `${U1}/0b8f6a1c-3d2e-4f5a-9b7c-1e2d3c4b5a69.pdf`;

await as(U1, `select attach_resource('task', $1, 'link', 'Apuntes', 'https://ejemplo.com/a')`, [task]);
await as(U1, `select attach_resource('task', $1, 'pdf', 'Guía', null, $2, 2048)`, [task, path]);
await as(U1, `select attach_resource('task', $1, 'note', '', null, null, null, 'Repasar límites')`, [task]);
const list = (await as(U1, `select item_resources('task', $1) r`, [task])).r;
assert.deepEqual(list.map((x) => x.kind).sort(), ['link', 'note', 'pdf']);
assert.equal(list.find((x) => x.kind === 'note').title, 'Nota');
ok('045: una tarea guarda enlace, PDF y nota');

await fails(U1, `select attach_resource('task', $1, 'link', 'Mal', 'ftp://x')`, [task], 'invalid_url');
await fails(U1, `select attach_resource('task', $1, 'pdf', 'Ajeno', null, $2, 10)`,
  [task, `${U2}/0b8f6a1c-3d2e-4f5a-9b7c-1e2d3c4b5a69.pdf`], 'invalid_path');
await fails(U1, `select attach_resource('task', $1, 'image', 'Foto', null, $2, 10)`, [task, path], 'invalid_path');
await fails(U1, `select attach_resource('task', $1, 'pdf', 'Grande', null, $2, 20000000)`, [task, path], 'invalid_size');
await fails(U1, `select attach_resource('task', $1, 'video', 'X')`, [task], 'invalid_kind');
await fails(U2, `select attach_resource('task', $1, 'link', 'Intruso', 'https://x.com')`, [task], 'not_found');
assert.deepEqual((await as(U2, `select item_resources('task', $1) r`, [task])).r, []);
ok('045: valida enlace, ruta propia, tamaño y tipo; otro usuario ni adjunta ni ve');

// Borrar devuelve la ruta para limpiar Storage; otro usuario no puede.
const pdfId = list.find((x) => x.kind === 'pdf').id;
await fails(U2, 'select delete_resource($1)', [pdfId], 'not_found');
assert.equal((await as(U1, 'select delete_resource($1) r', [pdfId])).r, path);
ok('045: delete_resource borra lo propio y devuelve la ruta del archivo');

// Dónde lo dejé + prueba de paso en dungeon_overview.
const step = (await as(U1, `insert into tasks (user_id, parent_task_id, title) values ($1, $2, 'Ejercicios 1-5') returning id`, [U1, task])).id;
await as(U1, 'select complete_task($1)', [step]);
await as(U1, `select attach_resource('task', $1, 'note', '', null, null, null, 'Me trabé en el 4')`, [step]);
await as(U1, `select set_resume_note($1, '  Sigo en el ejercicio 6  ')`, [task]);
await fails(U2, `select set_resume_note($1, 'x')`, [task], 'not_found');
await as(U1, 'select start_dungeon(60, 25, $1::uuid[])', [[task]]);
const t = (await as(U1, 'select dungeon_overview() r')).r.session.tasks[0];
assert.equal(t.resume_note, 'Sigo en el ejercicio 6');
assert.ok(t.resume_at);
assert.equal(t.resources, 2); // enlace y nota (el PDF se borró)
assert.equal(t.steps[0].proof, 'Me trabé en el 4');
assert.equal(t.steps[0].proof_photo, false);
await as(U1, `select set_resume_note($1, '')`, [task]);
assert.equal((await as(U1, 'select resume_note n, resume_at a from tasks where id = $1', [task])).a, null);
ok('045: dungeon_overview trae Dónde lo dejé, recursos y la prueba del paso; vacío la borra');

// Stage: los adjuntos no salen en la lista de Recursos; los sueltos sí.
await as(U1, `select create_resource('Suelto', 'https://suelto.com')`);
const res = (await as(U1, 'select stage_overview(current_date) r')).r.resources;
assert.deepEqual(res.map((x) => x.title), ['Suelto']);
ok('045: stage_overview solo lista los enlaces sueltos');

// Borrar la tarea se lleva sus recursos.
await db.exec(`delete from focus_session_tasks; delete from dungeon_runs; delete from focus_sessions;
  delete from quest_log_entries; delete from tasks where parent_task_id = '${task}'; delete from tasks where id = '${task}'`);
assert.equal(Number((await one('select count(*) n from resources where task_id is not null')).n), 0);
ok('045: borrar la tarea borra sus recursos por cascada');
