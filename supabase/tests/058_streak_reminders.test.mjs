// Prueba la migración 058 (recordatorios con la racha diaria de actividad).
// Uso: cd supabase/tests && node 058_streak_reminders.test.mjs
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
  '036_device_notifications.sql', '037_reward_feedback.sql', '038_home_today.sql',
  '039_task_steps.sql', '040_focus_required.sql', '041_home_extras.sql',
  '043_settings_digest.sql', '045_more_reminders.sql', '048_daily_reminders.sql',
  '049_local_timezone.sql', '050_push_fcm.sql', '053_nevi_reminders.sql',
  '056_activity_streak.sql', '058_streak_reminders.sql', '058_streak_reminders.sql']) {
  await db.exec(migration(f));
}
await db.exec(`insert into auth.users values ('${U1}', '{}')`);
ok('058 se aplica dos veces sin error');

const cfg = (await one(`select proconfig::text c from pg_proc where proname = '_generate_reminders'`)).c;
assert.match(cfg, /TimeZone=America\/Bogota/i);
ok('058: los recordatorios siguen en hora de Colombia (049)');

const today = (await one(`select (now() at time zone 'America/Bogota')::date::text d`)).d;
const token = await asUser(U1, () => one(`select register_device() r`)).then((x) => x.r);
const deliver = async (time) => {
  await db.exec(`set role anon; select set_config('request.jwt.claim.sub', '', false);
                 select set_config('request.jwt.claim.role', 'anon', false);`);
  try {
    return (await one(`select device_notifications($1, $2::date, $3::time) r`, [token, today, time]))
      .r.items.filter((i) => i.type === 'critical' && i.title.startsWith('Nevi'));
  } finally { await db.exec('reset role'); }
};
const log = (when) => db.query(
  `insert into quest_log_entries (user_id, source_type, source_id, result, occurred_at)
   values ($1, 'task', gen_random_uuid(), 'completed', ${when})`, [U1]);

// Sin hábitos: antes no había racha que defender; ahora cuenta la actividad de ayer.
await db.query(`insert into tasks (user_id, title, due_date) values ($1, 'Informe', $2::date + interval '20 hours')`, [U1, today]);
await log(`'${today}'::date - 1 + interval '17 hours'`); // ayer al mediodía en Colombia
await db.query(`delete from notifications`);

let items = await deliver('21:40');
assert.equal(items.length, 1);
assert.equal(items[0].title, 'Nevi: tu racha de 1 día sigue encendida 🔥');
ok('058: la última llamada defiende la racha diaria aunque no haya hábitos (y dice «1 día»)');

await db.query(`delete from notifications`);
await log('now()');
items = await deliver('21:40');
assert.equal(items.length, 0);
ok('058: con una actividad hoy, la última llamada no molesta');
