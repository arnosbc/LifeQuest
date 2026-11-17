// Prueba la migración 071 (hora para cada hábito con su aviso).
// Uso: cd supabase/tests && node 071_habit_time.test.mjs
import assert from 'node:assert/strict';

import { U1, U2, createFullDb, migration, ok, rejects } from './bootstrap.mjs';

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
  '051_habit_priority.sql', '056_activity_streak.sql', '058_streak_reminders.sql',
  '071_habit_time.sql', '071_habit_time.sql']) {
  await db.exec(migration(f));
}
await db.exec(`insert into auth.users values ('${U1}', '{}'), ('${U2}', '{}')`);
ok('071 se aplica dos veces sin error');

const call = (uid, sql, params) => asUser(uid, () => one(sql, params)).then((x) => x && x.r);
const today = (await one(`select (now() at time zone 'America/Bogota')::date::text d`)).d;
const token = await asUser(U1, () => one(`select register_device() r`)).then((x) => x.r);
const habitNotices = async (time) => {
  await db.exec(`set role anon; select set_config('request.jwt.claim.sub', '', false);
                 select set_config('request.jwt.claim.role', 'anon', false);`);
  try {
    return (await one(`select device_notifications($1, $2::date, $3::time) r`, [token, today, time]))
      .r.items.filter((i) => i.title.includes('es hora de'));
  } finally { await db.exec('reset role'); }
};

const leer = await call(U1, `select create_habit('Leer 10 paginas', 'good') r`);
await call(U1, `select set_habit_time($1, '20:00') r`, [leer]);
const listed = (await call(U1, `select habits_overview($1::date) r`, [today])).habits[0];
assert.equal(listed.reminder_time, '20:00');
ok('071: la hora del hábito se guarda y sale en habits_overview');

await rejects(call(U2, `select set_habit_time($1, '07:00') r`, [leer]), /habit_not_found/);
ok('071: nadie más puede ponerle hora a tu hábito');

assert.equal((await habitNotices('19:55')).length, 0);
const at = await habitNotices('20:03');
assert.equal(at.length, 1);
assert.match(at[0].title, /es hora de «Leer 10 paginas»/);
assert.match(at[0].message, /8:00 p\. m\./);
assert.equal((await habitNotices('20:40')).length, 0);
ok('071: el aviso sale una vez dentro de la hora elegida, no antes ni repetido');

const otro = await call(U1, `select create_habit('Meditar', 'good') r`);
await call(U1, `select set_habit_time($1, '21:00') r`, [otro]);
await call(U1, `select complete_habit($1, $2::date) r`, [otro, today]);
assert.equal((await habitNotices('21:10')).length, 0);
ok('071: si ya lo cumpliste hoy, no avisa');

const noche = await call(U1, `select create_habit('Preparar la ropa', 'good') r`);
await call(U1, `select set_habit_time($1, '23:30') r`, [noche]);
assert.equal((await habitNotices('23:45')).length, 1);
ok('071: una hora cerca de la medianoche (23:30) también avisa');

await call(U1, `select set_habit_time($1, null) r`, [leer]);
assert.equal((await call(U1, `select habits_overview($1::date) r`, [today])).habits
  .find((h) => h.id === leer).reminder_time, null);
ok('071: la hora se puede quitar');
