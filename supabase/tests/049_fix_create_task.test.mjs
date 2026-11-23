// Prueba la migración 049 (una sola create_task) sobre 001–048.
// Reproduce el choque con la create_task de 8 parámetros de la rama LifeQuest (040).
// Uso: cd supabase/tests && node 049_fix_create_task.test.mjs
import assert from 'node:assert/strict';
import { readdirSync } from 'node:fs';

import { U1, createFullDb, migration, ok, rejects } from './bootstrap.mjs';

const { db, one, asUser } = await createFullDb();
const files = readdirSync(new URL('../migrations/', import.meta.url))
  .filter((f) => f >= '003' && f < '049' && f.endsWith('.sql')).sort();
for (const f of files) await db.exec(migration(f));
await db.exec(`insert into auth.users values ('${U1}', '{}')`);

// Versiones sobrantes: la de 032 (12 parámetros, si 032 se volvió a ejecutar después
// de 038) y la de 010 que recrea la 040 de LifeQuest (8 parámetros).
await db.exec(`create function public.create_task(
  p_title text, p_description text default null,
  p_priority public.urgency_level default 'low', p_due_date timestamptz default null,
  p_skill_id uuid default null, p_project_id uuid default null,
  p_goal_id uuid default null, p_subtasks text[] default '{}',
  p_scheduled_at timestamptz default null, p_estimated_minutes integer default null,
  p_reminder_minutes integer default null, p_repeat_rule text default null)
returns jsonb language sql as $$ select jsonb_build_object('id', null) $$`);
await db.exec(`create function public.create_task(
  p_title text, p_description text default null,
  p_priority public.urgency_level default 'low', p_due_date timestamptz default null,
  p_skill_id uuid default null, p_project_id uuid default null,
  p_goal_id uuid default null, p_subtasks text[] default '{}')
returns jsonb language sql as $$ select jsonb_build_object('id', null) $$`);

// Igual que la app (TaskDraftModel.toParams) y que el SQL Editor.
const call = `select create_task(p_title => 'Prueba', p_priority => 'low',
  p_due_date => now() + interval '1 day', p_scheduled_at => null, p_estimated_minutes => null,
  p_reminder_minutes => null, p_repeat_rule => null, p_skill_id => null) r`;
await rejects(asUser(U1, () => one(call)), /is not unique/);
ok('049: reproduce «is not unique» como en Supabase');

await db.exec(migration('049_fix_create_task.sql'));
await db.exec(migration('049_fix_create_task.sql')); // idempotente
const n = await one(`select count(*)::int n from pg_proc where proname = 'create_task'`);
assert.equal(n.n, 1);
const r = await asUser(U1, () => one(call));
assert.ok(r.r.id);
ok('049: queda una sola create_task y crear tarea funciona');

// La firma vieja (solo los 8 nombres de LifeQuest) sigue funcionando.
const old = await asUser(U1, () => one(`select create_task(p_title => 'Vieja',
  p_subtasks => array['a']) r`));
assert.ok(old.r.id);
ok('049: quien llame con los parámetros viejos sigue creando tareas');
