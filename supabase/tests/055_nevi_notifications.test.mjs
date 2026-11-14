// Prueba la migración 055 (avisos firmados por Nevi) sobre 001–053.
// Uso: cd supabase/tests && node 055_nevi_notifications.test.mjs
import assert from 'node:assert/strict';

import { U1, createFullDb, migration, ok } from './bootstrap.mjs';

const { db, one, asUser } = await createFullDb();
await db.exec(`create role service_role nologin`);
for (const f of ['003_security.sql', '004_structure.sql', '005_rewards.sql', '006_store.sql',
  '007_daily.sql', '008_fix_exploits.sql', '009_profile_titles.sql', '010_missions.sql',
  '011_habits.sql', '012_dungeon.sql', '013_stage.sql', '014_goals.sql', '015_onboarding.sql',
  '016_settings.sql', '017_dungeon_breaks.sql', '018_marketplace.sql', '019_tavern.sql',
  '020_journal.sql', '021_boss_fight.sql', '022_rpgenie.sql', '023_brain_dump.sql',
  '024_vision_board.sql', '025_stats.sql', '026_inventory.sql', '027_daily_chest.sql',
  '028_edit_delete.sql', '029_notifications.sql', '030_npc_noble_mission.sql',
  '031_npc_mission_guide.sql', '033_dungeon_rewards.sql', '034_brain_dump_goal.sql',
  '036_device_notifications.sql', '043_settings_digest.sql', '045_more_reminders.sql',
  '048_daily_reminders.sql', '049_local_timezone.sql', '050_push_fcm.sql',
  '053_nevi_reminders.sql', '055_nevi_notifications.sql', '055_nevi_notifications.sql']) {
  await db.exec(migration(f));
}
await db.exec(`insert into auth.users values ('${U1}', '{}')`);
ok('055 se aplica dos veces sin error');

const cfg = (await one(`select proconfig::text c from pg_proc where proname = '_generate_notifications'`)).c;
assert.match(cfg, /TimeZone=America\/Bogota/i);
ok('055: los avisos siguen en hora de Colombia (049)');

const today = (await one(`select (now() at time zone 'America/Bogota')::date::text d`)).d;
await db.query(`insert into tasks (user_id, title, due_date) values ($1, 'Informe', now() - interval '2 days')`, [U1]);
await db.query(`select public._generate_notifications($1, $2::date)`, [U1, today]);
const n = await one(`select title, message from notifications where event_key like 'overdue:%'`);
assert.equal(n.title, 'Nevi: tienes tareas pendientes');
assert.equal(n.message, '1 tarea ya pasó su fecha. La retomamos cuando puedas.');
ok('055: la tarea vencida la avisa Nevi con tono de invitación');
