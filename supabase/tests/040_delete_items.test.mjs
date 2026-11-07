// Prueba la migración 040 (borrar proyectos, metas y recursos) sobre 001–039.
// Uso: cd supabase/tests && node 040_delete_items.test.mjs
import assert from 'node:assert/strict';
import { readdirSync } from 'node:fs';

import { U1, U2, createFullDb, migration, ok, rejects } from './bootstrap.mjs';

const { db, one, asUser } = await createFullDb();
const files = readdirSync(new URL('../migrations/', import.meta.url))
  .filter((f) => f >= '003' && f < '040' && f.endsWith('.sql')).sort();
for (const f of files) await db.exec(migration(f));
await db.exec(migration('040_delete_items.sql'));
await db.exec(migration('040_delete_items.sql')); // idempotente
await db.exec(`insert into auth.users values ('${U1}', '{}'), ('${U2}', '{}')`);
ok('040 se aplica dos veces sin error');

const as = (uid, sql, p) => asUser(uid, () => one(sql, p));
const ins = async (sql, p) => (await one(sql, p)).id;

const goal = await ins(`insert into goals (user_id, title) values ($1, 'Meta') returning id`, [U1]);
const project = await ins(`insert into projects (user_id, title, goal_id) values ($1, 'Proy', $2) returning id`, [U1, goal]);
const task = await ins(`insert into tasks (user_id, title, project_id, goal_id) values ($1, 'T', $2, $3) returning id`,
  [U1, project, goal]);
// Solo el servidor completa (003): el fixture entra como función interna.
await db.exec(`select set_config('lifequest.internal', 'on', false)`);
const done = await ins(`insert into projects (user_id, title, status) values ($1, 'Hecho', 'completed') returning id`, [U1]);
await db.exec(`select set_config('lifequest.internal', '', false)`);
const res = await ins(`insert into resources (user_id, title, file_url) values ($1, 'R', 'https://x.y') returning id`, [U1]);

await rejects(as(U2, `select delete_item('project', $1)`, [project]), /item_not_found/);
await rejects(as(U1, `select delete_item('project', $1)`, [done]), /item_completed/);
await rejects(as(U1, `select delete_item('nada', $1)`, [project]), /invalid_kind/);
ok('040: solo el dueño borra, y nunca lo completado');

await as(U1, `select delete_item('project', $1)`, [project]);
let t = await one('select project_id, goal_id from tasks where id = $1', [task]);
assert.deepEqual([t.project_id, t.goal_id], [null, goal]);
await as(U1, `select delete_item('goal', $1)`, [goal]);
t = await one('select goal_id from tasks where id = $1', [task]);
assert.equal(t.goal_id, null);
assert.equal((await one('select count(*)::int n from goals where id = $1', [goal])).n, 0);
await as(U1, `select delete_item('resource', $1)`, [res]);
assert.equal((await one('select count(*)::int n from resources where id = $1', [res])).n, 0);
ok('040: borrar proyecto o meta deja sus tareas sueltas; el recurso se borra');
