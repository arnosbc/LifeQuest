// Prueba la migración 038 (recordatorios) sobre 001–037.
// Uso: cd supabase/tests && node 038_reminders.test.mjs
import assert from 'node:assert/strict';
import { readdirSync } from 'node:fs';

import { U1, createFullDb, migration, ok, rejects } from './bootstrap.mjs';

const { db, one, asUser } = await createFullDb();
const files = readdirSync(new URL('../migrations/', import.meta.url))
  .filter((f) => f >= '003' && f < '038' && f.endsWith('.sql')).sort();
for (const f of files) await db.exec(migration(f));
await db.exec(migration('038_reminders.sql'));
await db.exec(migration('038_reminders.sql')); // idempotente
await db.exec(`insert into auth.users values ('${U1}', '{}')`);
ok('038 se aplica dos veces sin error');

const as = (sql, p) => asUser(U1, () => one(sql, p));
const at = new Date(Date.now() + 60 * 60 * 1000).toISOString();

// Con nombres: la firma vieja (sin p_is_reminder) sigue sirviendo.
const task = (await as(`select create_task('Escribir el informe largo de este mes') r`)).r;
const rem = (await as(`select create_task(p_title => 'Llamar a mamá', p_scheduled_at => $1,
  p_is_reminder => true) r`, [at])).r;
assert.ok(task.xp_reward > 0);
assert.deepEqual([rem.xp_reward, rem.coin_reward], [0, 0]);
const row = await as('select is_reminder, reminder_minutes from tasks where id = $1', [rem.id]);
assert.deepEqual([row.is_reminder, row.reminder_minutes], [true, 0]);
await rejects(as(`select create_task(p_title => 'Pagar luz', p_is_reminder => true)`), /reminder_needs_time/);
ok('038: el recordatorio nace sin XP, con aviso a su hora, y exige hora');

const ids = (list) => list.map((t) => t.id);
const missions = (await as('select missions_overview() r')).r.missions;
assert.deepEqual(ids(missions), [task.id]);
const focus = (await as('select dungeon_overview() r')).r.candidates;
assert.ok(!ids(focus).includes(rem.id));
const today = new Date().toISOString().slice(0, 10);
const home = (await as(`select home_dashboard($1::date, 0) r`, [today])).r;
assert.equal(home.priority_mission.id, task.id);
const agenda = (await as(`select day_agenda($1::date, 0) r`, [at.slice(0, 10)])).r;
assert.equal(agenda.scheduled.find((b) => b.id === rem.id).is_reminder, true);
ok('038: fuera de Tareas, Foco y la sugerencia de Hoy; en la agenda con su marca');

// Hecho: sin XP ni Historial. Al repetirse, la siguiente sigue siendo recordatorio.
await db.exec(`update tasks set repeat_rule = 'daily' where id = '${rem.id}'`);
const before = await as('select current_xp, coins from character_stats where user_id = $1', [U1]);
const res = (await as('select complete_task($1) r', [rem.id])).r;
assert.equal(res.reminder, true);
const after = await as('select current_xp, coins from character_stats where user_id = $1', [U1]);
assert.deepEqual(after, before);
assert.equal((await as('select count(*)::int n from quest_log_entries where source_id = $1', [rem.id])).n, 0);
const next = await as(`select is_reminder, xp_reward from tasks
  where title = 'Llamar a mamá' and status = 'pending'`);
assert.deepEqual([next.is_reminder, next.xp_reward], [true, 0]);
ok('038: marcarlo hecho no paga ni deja Historial; su repetición sigue siendo recordatorio');
