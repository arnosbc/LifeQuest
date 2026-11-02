// Prueba la migración 045 (hábitos pendientes y tareas vencidas) sobre 001–044.
// Uso: cd supabase/tests && node 045_more_reminders.test.mjs
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
  '036_device_notifications.sql', '045_more_reminders.sql', '045_more_reminders.sql']) {
  await db.exec(migration(f));
}
await db.exec(`insert into auth.users values ('${U1}', '{"username":"Ana"}')`);
ok('045 se aplica dos veces sin error');

const today = (await one(`select current_date::text d`)).d;
const token = await asUser(U1, () => one(`select register_device() r`)).then((x) => x.r);
const deliver = async (time) => {
  await db.exec(`set role anon; select set_config('request.jwt.claim.sub', '', false);
                 select set_config('request.jwt.claim.role', 'anon', false);`);
  try {
    return (await one(`select device_notifications($1, $2::date, $3::time) r`,
      [token, today, time])).r.items;
  } finally { await db.exec('reset role'); }
};

await db.query(`insert into habits (user_id, name, type) values ($1, 'Meditar', 'good'), ($1, 'Agua', 'good')`, [U1]);
await db.query(`insert into tasks (user_id, title, due_date) values ($1, 'Informe', $2::date - 2)`, [U1, today]);

// Mañana: la tarea vencida al momento; los hábitos esperan a la tarde.
let items = await deliver('09:00');
assert.deepEqual(items.map((i) => [i.type, i.title, i.message]),
  [['critical', 'Tienes tareas pendientes', '1 tarea ya pasó su fecha. Retómala cuando puedas.']]);
items = await deliver('18:30');
assert.deepEqual(items.map((i) => [i.title, i.message]),
  [['Tienes hábitos pendientes hoy', 'Te faltan 2 hábitos: Agua, Meditar.']]);
assert.deepEqual(await deliver('19:00'), []); // nunca se repite el mismo día
ok('045: tareas vencidas al momento y hábitos pendientes juntos por la tarde');
