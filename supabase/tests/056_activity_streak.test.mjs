// Prueba la migración 056 (racha diaria de actividad) sobre 001–041.
// Uso: cd supabase/tests && node 056_activity_streak.test.mjs
import assert from 'node:assert/strict';

import { U1, U2, createFullDb, migration, ok } from './bootstrap.mjs';

const { db, one, asUser } = await createFullDb();
for (const f of ['003_security.sql', '004_structure.sql', '005_rewards.sql', '006_store.sql',
  '007_daily.sql', '008_fix_exploits.sql', '009_profile_titles.sql', '010_missions.sql',
  '011_habits.sql', '012_dungeon.sql', '013_stage.sql', '014_goals.sql', '015_onboarding.sql',
  '016_settings.sql', '017_dungeon_breaks.sql', '018_marketplace.sql', '019_tavern.sql',
  '020_journal.sql', '021_boss_fight.sql', '022_rpgenie.sql', '023_brain_dump.sql',
  '024_vision_board.sql', '025_stats.sql', '026_inventory.sql', '027_daily_chest.sql',
  '028_edit_delete.sql', '029_notifications.sql', '030_npc_noble_mission.sql',
  '031_npc_mission_guide.sql', '033_dungeon_rewards.sql', '034_brain_dump_goal.sql',
  '037_reward_feedback.sql', '038_home_today.sql', '039_task_steps.sql', '040_focus_required.sql',
  '041_home_extras.sql', '056_activity_streak.sql', '056_activity_streak.sql']) {
  await db.exec(migration(f));
}
await db.exec(`insert into auth.users values ('${U1}', '{}'), ('${U2}', '{}')`);
ok('056 se aplica dos veces sin error');

const today = (await one(`select current_date::text d`)).d;
// Actividad «hace N días» a mediodía UTC (desfase 0 en la prueba).
const log = (uid, daysAgo, source = 'task', result = 'completed') => db.query(
  `insert into quest_log_entries (user_id, source_type, source_id, result, occurred_at)
   values ($1, $2, gen_random_uuid(), $3, current_date - $4::int + interval '12 hours')`,
  [uid, source, result, daysAgo]);
const streak = (uid) => asUser(uid, () => one(`select _activity_streak($1, $2::date, 0) s`, [uid, today])).then((x) => x.s);
const home = (uid) => asUser(uid, () => one(`select home_dashboard($1::date, 0) r`, [today])).then((x) => x.r.streak_days);

assert.equal(await streak(U1), 0);
ok('056: sin actividad la racha es 0');

await log(U1, 1); // ayer
assert.equal(await streak(U1), 1);
ok('056: con actividad ayer y nada hoy, la racha sigue viva (1)');

await log(U1, 0, 'habit'); // hoy, un hábito
await log(U1, 0, 'dungeon'); // mismo día: cuenta una vez
assert.equal(await streak(U1), 2);
assert.equal(await home(U1), 2);
ok('056: ayer y hoy = 2, y home_dashboard la muestra');

await log(U1, 3); // hace 3 días: hay un hueco (hace 2)
assert.equal(await streak(U1), 2);
ok('056: un día sin actividad corta la racha');

await log(U1, 2, 'habit', 'failed'); // mal hábito hace 2 días
await log(U1, 2, 'daily_chest');     // cofre hace 2 días
assert.equal(await streak(U1), 2);
ok('056: un mal hábito o un cofre no cuentan como actividad');

await log(U2, 0);
assert.equal(await asUser(U2, () => one(`select _activity_streak($1, $2::date, 0) s`, [U1, today])).then((x) => x.s), 0);
assert.equal(await streak(U2), 1);
ok('056: cada quien solo cuenta lo suyo (RLS)');
