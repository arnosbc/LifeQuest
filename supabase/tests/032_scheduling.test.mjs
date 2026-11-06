// Prueba la migración 032 (tareas que actúan) sobre 001–031: repetición,
// schedule_task, snooze_task, create_task con agenda, focus_minutes y RLS.
// Uso: cd supabase/tests && node 032_scheduling.test.mjs
import assert from 'node:assert/strict';
import { readdirSync } from 'node:fs';

import { U1, U2, createFullDb, migration, ok, rejects } from './bootstrap.mjs';

const { db, one, asUser } = await createFullDb();
const files = readdirSync(new URL('../migrations/', import.meta.url))
  .filter((f) => f >= '003' && f < '032' && f.endsWith('.sql')).sort();
for (const f of files) await db.exec(migration(f));
await db.exec(migration('032_scheduling.sql'));
await db.exec(migration('032_scheduling.sql')); // idempotente
await db.exec(`insert into auth.users values ('${U1}', '{"username":"Ana"}'), ('${U2}', '{}')`);
ok('032 se aplica dos veces sin error');

const as = (uid, sql, p) => asUser(uid, () => one(sql, p));
const task = (uid, title, extra = {}) => as(uid,
  `select create_task(p_title => $1, p_scheduled_at => $2, p_estimated_minutes => $3,
                      p_reminder_minutes => $4, p_repeat_rule => $5, p_due_date => $6) r`,
  [title, extra.at ?? null, extra.minutes ?? null, extra.reminder ?? null,
   extra.repeat ?? null, extra.due ?? null]).then((x) => x.r.id);
const row = (id) => one(`select * from tasks where id = $1`, [id]);
const complete = (uid, id) => as(uid, `select complete_task($1) r`, [id]);
const next = (title) => one(
  `select * from tasks where title = $1 and status = 'pending' order by created_at desc limit 1`, [title]);

// create_task con agenda ------------------------------------------------------------
const at = '2030-01-07T18:00:00Z'; // lunes
const t1 = await task(U1, 'Gimnasio', { at, minutes: 60, reminder: 15, repeat: 'weekly:1,3' });
let t = await row(t1);
assert.deepEqual([t.estimated_minutes, t.reminder_minutes, t.repeat_rule, t.focus_minutes],
  [60, 15, 'weekly:1,3', 0]);
assert.equal(t.scheduled_at.toISOString(), '2030-01-07T18:00:00.000Z');
await rejects(task(U1, 'Mal', { repeat: 'cada lunes' }), /tasks_repeat_rule_check/);
await rejects(task(U1, 'Mal', { repeat: 'weekly:7' }), /tasks_repeat_rule_check/);
await rejects(task(U1, 'Mal', { minutes: 2 }), /tasks_estimated_minutes_check/);
await rejects(task(U1, 'Mal', { reminder: -1 }), /tasks_reminder_minutes_check/);
ok('032: create_task guarda bloque, duración, aviso y repetición con formato cerrado');

// Repetición -----------------------------------------------------------------------
await complete(U1, t1);
t = await next('Gimnasio');
assert.notEqual(t.id, t1);
assert.equal(t.scheduled_at.toISOString(), '2030-01-09T18:00:00.000Z'); // miércoles
assert.deepEqual([t.estimated_minutes, t.reminder_minutes, t.repeat_rule], [60, 15, 'weekly:1,3']);
assert.ok(t.xp_reward > 0);
await complete(U1, t.id);
assert.equal((await next('Gimnasio')).scheduled_at.toISOString(), '2030-01-14T18:00:00.000Z');

// Hora local: 20:00 en Bogotá es 01:00 UTC del día siguiente.
await asUser(U1, () => db.query(`update game_master_settings set time_zone = 'America/Bogota'`));
const t2 = await task(U1, 'Leer', { at: '2030-01-04T01:00:00Z', repeat: 'weekdays' }); // jueves 20:00 local
await complete(U1, t2);
assert.equal((await next('Leer')).scheduled_at.toISOString(), '2030-01-05T01:00:00.000Z'); // viernes local
await complete(U1, (await next('Leer')).id);
assert.equal((await next('Leer')).scheduled_at.toISOString(), '2030-01-08T01:00:00.000Z'); // lunes local
await rejects(asUser(U1, () => db.query(`update game_master_settings set time_zone = 'Marte/Base'`)),
  /invalid_time_zone/);
await asUser(U1, () => db.query(`update game_master_settings set time_zone = 'UTC'`));

const t3 = await task(U1, 'Pagar renta', { due: '2030-01-31T12:00:00Z', repeat: 'monthly:31' });
await complete(U1, t3);
t = await next('Pagar renta');
assert.equal(t.due_date.toISOString(), '2030-02-28T12:00:00.000Z');
assert.equal(t.scheduled_at, null);

// Atrasada: la siguiente cae en el futuro, no en el pasado.
const t4 = await task(U1, 'Agua', { at: '2020-01-01T08:00:00Z', repeat: 'daily' });
await complete(U1, t4);
t = await next('Agua');
assert.ok(t.scheduled_at > new Date());
assert.equal(t.scheduled_at.toISOString().slice(11), '08:00:00.000Z');
assert.ok(t.scheduled_at - new Date() <= 24 * 3600 * 1000);

const t5 = await task(U1, 'Una vez');
await complete(U1, t5);
assert.equal(await next('Una vez'), undefined);
ok('032: completar crea la siguiente ocurrencia (semanal, días hábiles, mensual, en hora local y atrasada)');

// schedule_task y snooze_task ----------------------------------------------------------
const t6 = await task(U1, 'Llamar');
await asUser(U1, () => db.query(`select schedule_task($1, $2, 45)`, [t6, at]));
t = await row(t6);
assert.deepEqual([t.scheduled_at.toISOString(), t.estimated_minutes], ['2030-01-07T18:00:00.000Z', 45]);
await asUser(U1, () => db.query(`select schedule_task($1, null)`, [t6]));
t = await row(t6);
assert.deepEqual([t.scheduled_at, t.estimated_minutes], [null, 45]);

let r = await as(U1, `select snooze_task($1, 60) r`, [t6]);
assert.ok(Math.abs(r.r - Date.now() - 3600_000) < 60_000);
await asUser(U1, () => db.query(`select schedule_task($1, $2)`, [t6, at]));
r = await as(U1, `select snooze_task($1) r`, [t6]);
assert.equal(r.r.toISOString(), '2030-01-07T19:00:00.000Z');
await rejects(as(U1, `select snooze_task($1, 0)`, [t6]), /invalid_minutes/);
await rejects(as(U2, `select snooze_task($1)`, [t6]), /task_not_found/);
await rejects(asUser(U2, () => db.query(`select schedule_task($1, $2)`, [t6, at])), /task_not_found/);
await rejects(asUser(U1, () => db.query(`select schedule_task($1, $2)`, [t5, at])), /task_not_found/);
ok('032: schedule_task y snooze_task mueven el bloque solo de tareas propias y abiertas');

// focus_minutes ---------------------------------------------------------------------
await rejects(asUser(U1, () => db.query(`update tasks set focus_minutes = 999 where id = $1`, [t6])),
  /permission denied/);
const t7 = await task(U1, 'Escribir');
const s = await as(U1, `select start_dungeon(60, 25, $1::uuid[]) id`, [[t6, t7]]).then((x) => x.id);
await db.query(`update focus_sessions set started_at = now() - interval '41 minutes' where id = $1`, [s]);
const summary = await as(U1, `select end_dungeon($1) r`, [s]).then((x) => x.r);
assert.equal(summary.minutes, 41);
const mins = [(await row(t6)).focus_minutes, (await row(t7)).focus_minutes].sort();
assert.deepEqual(mins, [20, 21]);
ok('032: end_dungeon suma los minutos medidos a las tareas de la sesión (el cliente no puede)');

// RLS y overview ------------------------------------------------------------------------
const m = await as(U1, `select missions_overview() r`).then((x) => x.r.missions.find((x) => x.id === t6));
assert.deepEqual([m.estimated_minutes, m.focus_minutes, m.repeat_rule],
  [45, (await row(t6)).focus_minutes, null]);
assert.ok('scheduled_at' in m && 'reminder_minutes' in m);
assert.deepEqual((await as(U2, `select missions_overview() r`)).r.missions, []);
ok('032: missions_overview devuelve la agenda y no mezcla usuarios');

// day_agenda y sync_reminders ------------------------------------------------------
const soon = new Date(Date.now() + 3 * 3600_000);
const localDay = (d) => d.toISOString().slice(0, 10);
const t8 = await task(U1, 'Dentista', { at: soon.toISOString(), minutes: 30, reminder: 10 });
const agenda = await as(U1, `select day_agenda($1::date, 0) r`, [localDay(soon)]).then((x) => x.r);
assert.ok(agenda.scheduled.some((x) => x.id === t8 && x.done === false && x.estimated_minutes === 30));
assert.ok(agenda.unscheduled.every((x) => x.id !== t8));
assert.ok(agenda.unscheduled.some((x) => x.title === 'Escribir'));
assert.deepEqual(await as(U2, `select day_agenda($1::date, 0) r`, [localDay(soon)]).then((x) => x.r),
  { scheduled: [], unscheduled: [] });

await asUser(U1, () => db.query(`select create_habit('Meditar', 'good')`));
await db.query(`update habits set reminder_time = '07:30' where user_id = $1`, [U1]);
const sync = await as(U1, `select sync_reminders('America/Bogota') r`).then((x) => x.r);
assert.equal((await one(`select time_zone from game_master_settings where user_id = $1`, [U1])).time_zone,
  'America/Bogota');
assert.deepEqual(sync.tasks.map((x) => [x.id, x.reminder_minutes]), [[t8, 10]]);
assert.ok(sync.habits.every((h) => h.reminder_time === '07:30:00'));
await rejects(as(U1, `select sync_reminders('Nada/Nada')`), /invalid_time_zone/);
assert.deepEqual((await as(U2, `select sync_reminders('UTC') r`)).r.tasks, []);
ok('032: day_agenda da bloques y pendientes sin hora; sync_reminders guarda la zona y lista los avisos');
