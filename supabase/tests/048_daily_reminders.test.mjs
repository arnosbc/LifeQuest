// Prueba la migración 048 (recordatorios del día) sobre 001–047.
// Uso: cd supabase/tests && node 048_daily_reminders.test.mjs
import assert from 'node:assert/strict';

import { U1, createFullDb, migration, ok } from './bootstrap.mjs';

const { db, one, asUser } = await createFullDb();
for (const f of ['003_security.sql', '004_structure.sql', '005_rewards.sql', '006_store.sql',
  '007_daily.sql', '008_fix_exploits.sql', '009_profile_titles.sql', '010_missions.sql',
  '011_habits.sql', '012_dungeon.sql', '013_stage.sql', '014_goals.sql', '015_onboarding.sql',
  '016_settings.sql', '017_dungeon_breaks.sql', '018_marketplace.sql', '019_tavern.sql',
  '020_journal.sql', '021_boss_fight.sql', '022_rpgenie.sql', '023_brain_dump.sql',
  '024_vision_board.sql', '025_stats.sql', '026_inventory.sql', '027_daily_chest.sql',
  '028_edit_delete.sql', '029_notifications.sql', '030_npc_noble_mission.sql',
  '031_npc_mission_guide.sql', '033_dungeon_rewards.sql', '034_brain_dump_goal.sql',
  '036_device_notifications.sql', '043_settings_digest.sql', '045_more_reminders.sql',
  '048_daily_reminders.sql', '048_daily_reminders.sql']) {
  await db.exec(migration(f));
}
await db.exec(`insert into auth.users values ('${U1}', '{"username":"Ana"}')`);
ok('048 se aplica dos veces sin error');

const today = (await one(`select current_date::text d`)).d;
const token = await asUser(U1, () => one(`select register_device() r`)).then((x) => x.r);
const deliver = async (time) => {
  await db.exec(`set role anon; select set_config('request.jwt.claim.sub', '', false);
                 select set_config('request.jwt.claim.role', 'anon', false);`);
  try {
    return (await one(`select device_notifications($1, $2::date, $3::time) r`,
      [token, today, time])).r.items.filter((i) => i.type === 'critical' && i.title !== 'Tienes tareas pendientes');
  } finally { await db.exec('reset role'); }
};
// La regla de 90 min usa la hora real: se «envejecen» las entregas entre pasos.
const later = () => db.query(`update notifications set delivered_at = now() - interval '3 hours'`);

// Sin nada pendiente: ningún recordatorio.
assert.deepEqual(await deliver('09:05'), []);
ok('048: sin pendientes no se molesta');

const habit = (await one(`insert into habits (user_id, name, type, current_streak)
  values ($1, 'Leer', 'good', 4) returning id`, [U1])).id;
await db.query(`insert into tasks (user_id, title, due_date) values ($1, 'Informe', $2::date + interval '20 hours')`, [U1, today]);
await db.query(`delete from notifications`);

let items = await deliver('09:05');
assert.equal(items.length, 1);
assert.equal(items[0].type, 'critical');
assert.match(items[0].message, /^Hoy tienes 1 hábito y 1 tarea\./);
assert.deepEqual(await deliver('09:40'), []); // mismo momento y < 90 min
ok('048: recordatorio de la mañana con lo pendiente, una sola vez');

await later();
items = await deliver('13:10');
assert.match(items[0].message, /^Te quedan 1 hábito y 1 tarea/);
ok('048: recordatorio del mediodía');

// Móvil apagado de 13:10 a 21:40: solo llega el de las 21:30 (racha), no todos.
await later();
items = (await deliver('21:40')).filter((i) => i.title.includes('racha') && i.type === 'critical');
const reminders = items.filter((i) => i.title.startsWith('Última oportunidad'));
assert.equal(reminders.length, 1);
assert.match(reminders[0].message, /Llevas 4 días/);
const slots = (await one(`select array_agg(split_part(event_key, ':', 4) order by created_at) s
  from notifications where category = 'reminder'`)).s;
assert.deepEqual(slots, ['morning', 'midday', 'last_call']);
ok('048: tras horas sin conexión llega solo el último momento (racha a las 21:30)');

// Hecho el hábito, la última llamada no llega; y el interruptor los apaga.
await db.query(`delete from notifications`);
await db.query(`insert into habit_records (habit_id, user_id, completed_on) values ($1, $2, $3)`, [habit, U1, today]);
await db.query(`delete from tasks`);
assert.deepEqual(await deliver('21:45'), []);
await db.query(`delete from habit_records`);
await db.query(`update game_master_settings set daily_reminders = false`);
assert.deepEqual((await deliver('16:10')).filter((i) => i.type === 'critical' && !i.title.includes('racha')), []);
ok('048: sin pendientes de racha no hay última llamada, y el interruptor los apaga');

const overview = await asUser(U1, () => one(`select settings_overview() r`)).then((x) => x.r);
assert.equal(overview.daily_reminders, false);
ok('048: Configuración devuelve el interruptor');

// Noche: con solo una tarea de hoy llega el recordatorio; con un hábito cuyo
// aviso de racha (036) sale en esta revisión, no se duplica.
await db.query(`delete from notifications`);
await db.query(`update game_master_settings set daily_reminders = true`);
await db.query(`delete from habits`);
await db.query(`insert into tasks (user_id, title, due_date) values ($1, 'Ensayo', $2::date + interval '23 hours')`, [U1, today]);
items = await deliver('19:40');
assert.equal(items.length, 1);
assert.equal(items[0].message, 'Te queda 1 tarea.');
ok('048: de noche, con una tarea de hoy, llega el recordatorio');

await db.query(`delete from notifications`);
await db.query(`delete from tasks`);
await db.query(`insert into habits (user_id, name, type, current_streak) values ($1, 'Correr', 'good', 2)`, [U1]);
items = await deliver('19:40');
assert.deepEqual(items.map((i) => i.title), ['Tu racha te está esperando 🔥']);
ok('048: de noche no se duplica con el aviso de racha de 036');
