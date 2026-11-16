// Prueba la migración 073 (tareas que se repiten).
// Uso: cd supabase/tests && node 073_repeating_tasks.test.mjs
import assert from 'node:assert/strict';

import { U1, U2, createFullDb, migration, ok, rejects } from './bootstrap.mjs';

const { db, one, asUser } = await createFullDb();
for (const f of ['003_security.sql', '004_structure.sql', '005_rewards.sql', '006_store.sql',
  '007_daily.sql', '008_fix_exploits.sql', '009_profile_titles.sql', '010_missions.sql',
  '011_habits.sql', '012_dungeon.sql', '013_stage.sql', '014_goals.sql', '015_onboarding.sql',
  '016_settings.sql', '017_dungeon_breaks.sql', '018_marketplace.sql', '019_tavern.sql',
  '020_journal.sql', '021_boss_fight.sql', '022_rpgenie.sql', '023_brain_dump.sql',
  '024_vision_board.sql', '025_stats.sql', '026_inventory.sql', '027_daily_chest.sql',
  '028_edit_delete.sql', '029_notifications.sql', '030_npc_noble_mission.sql',
  '031_npc_mission_guide.sql', '033_dungeon_rewards.sql', '037_reward_feedback.sql',
  '038_home_today.sql', '039_task_steps.sql', '040_focus_required.sql', '066_dungeon_loot_steps.sql',
  '067_adapt_task_guide.sql', '068_focus_unified.sql', '069_dungeon_loot_habits.sql',
  '073_repeating_tasks.sql', '073_repeating_tasks.sql']) {
  await db.exec(migration(f));
}
await db.exec(`insert into auth.users values ('${U1}', '{}'), ('${U2}', '{}')`);
ok('073 se aplica dos veces sin error');

const call = (uid, sql, params) => asUser(uid, () => one(sql, params)).then((x) => x && x.r);
const today = (await one(`select (now() at time zone 'America/Bogota')::date::text d`)).d;
const day = (n) => one(`select ($1::date + $2::int)::text d`, [today, n]).then((x) => x.d);
const next = (rule, after) => one(`select _next_repeat($1, $2::date, $3::date)::text d`,
  [rule, after, today]).then((x) => x.d);
// Cerrar una tarea como lo haría complete_task (la RPC se prueba en su migración).
const complete = (id) => db.exec(`select set_config('lifequest.internal', 'on', false);
  update tasks set status = 'completed', completed_at = now() where id = '${id}';
  select set_config('lifequest.internal', '', false);`);
const spawn = (d) => one(`select _spawn_repeating_tasks($1::date) n`, [d]).then((x) => x.n);
const open = (series) => db.query(
  `select id, (due_date at time zone 'America/Bogota')::date::text d from tasks where series_id = $1 and status = 'pending'`, [series])
  .then((r) => r.rows);

// Reglas: el día siguiente nunca cae antes de hoy; entre semana salta el finde.
assert.equal(await next('daily', await day(-10)), today);
assert.equal(await next('daily', today), await day(1));
assert.equal(await next('weekly', today), await day(7));
const sat = (await one(`select ($1::date + (6 - extract(isodow from $1::date))::int)::text d`, [today])).d;
assert.equal(await one(`select extract(isodow from _next_repeat('weekdays', $1::date, $1::date)) n`,
  [sat]).then((x) => Number(x.n)), 1);
ok('073: _next_repeat salta lo ya pasado y el fin de semana');

const t = (await call(U1, `select create_task($1) r`, ['Repasar inglés'])).id;
await call(U1, `select attach_task_guide($1, $2::jsonb) r`, [t, JSON.stringify({ steps: ['Leer', 'Escribir'] })]);
await rejects(call(U2, `select set_task_repeat($1, 'daily') r`, [t]), /task_not_open/);
await rejects(call(U1, `select set_task_repeat($1, 'hourly') r`, [t]), /invalid_repeat_rule/);
await call(U1, `select set_task_repeat($1, 'daily') r`, [t]);
let row = await one(`select repeat_rule, series_id, (due_date at time zone 'America/Bogota')::date::text d from tasks where id = $1`, [t]);
assert.deepEqual([row.repeat_rule, row.series_id, row.d], ['daily', t, today]);
const m = (await call(U1, `select missions_overview() r`)).missions.find((x) => x.id === t);
assert.equal(m.repeat_rule, 'daily');
ok('073: set_task_repeat solo del dueño, con regla válida; sin fecha toma hoy');

// Abierta: no se duplica. Completada: la siguiente aparece cuando llega su día, no antes.
assert.equal(await spawn(today), 0);
await complete(t);
assert.equal(await spawn(today), 0);
assert.equal((await open(t)).length, 0);
assert.equal(await spawn(await day(1)), 1);
const copies = await open(t);
assert.equal(copies.length, 1);
assert.equal(copies[0].d, await day(1));
const steps = await db.query(`select title, done_at from task_steps where task_id = $1 order by position`,
  [copies[0].id]);
assert.deepEqual(steps.rows.map((s) => [s.title, s.done_at]), [['Leer', null], ['Escribir', null]]);
assert.equal(await spawn(await day(1)), 0);
ok('073: la copia nace en su día, con los pasos sin hacer, y una sola vez');

// Quitar la repetición o borrar la copia abierta detiene la serie.
await call(U1, `select delete_task($1) r`, [copies[0].id]);
assert.equal(await spawn(await day(5)), 0);
const t2 = (await call(U1, `select create_task($1) r`, ['Lavar ropa'])).id;
await call(U1, `select set_task_repeat($1, 'weekly') r`, [t2]);
await call(U1, `select set_task_repeat($1, null) r`, [t2]);
await complete(t2);
assert.equal(await spawn(await day(30)), 0);
ok('073: borrar la copia o quitar la repetición detiene la serie');
