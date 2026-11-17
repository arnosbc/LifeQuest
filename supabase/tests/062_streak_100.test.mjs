// Prueba la migración 062 (logro de 100 días de racha) sobre 057 y 060.
// Uso: cd supabase/tests && node 062_streak_100.test.mjs
import assert from 'node:assert/strict';

import { U1, U2, createFullDb, migration, ok } from './bootstrap.mjs';

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
  '037_reward_feedback.sql', '038_home_today.sql', '039_task_steps.sql', '040_focus_required.sql',
  '041_home_extras.sql', '052_challenges_league.sql', '056_activity_streak.sql',
  '057_achievements.sql', '060_daily_streak_protector.sql',
  '062_streak_100.sql', '062_streak_100.sql']) {
  await db.exec(migration(f));
}
await db.exec(`insert into auth.users values ('${U1}', '{}'), ('${U2}', '{}')`);
assert.equal((await one(`select count(*)::int n from achievements`)).n, 13);
ok('062 se aplica dos veces sin error y deja 13 logros');

const has100 = () => one(
  `select exists (select 1 from user_achievements ua join achievements a on a.id = ua.achievement_id
                  where ua.user_id = $1 and a.code = 'streak_100') x`, [U1]).then((r) => r.x);
// 99 días seguidos hasta ayer (hora de Colombia, 17:00 UTC).
await db.query(
  `insert into quest_log_entries (user_id, source_type, source_id, result, occurred_at)
   select $1, 'habit', gen_random_uuid(), 'completed',
          (now() at time zone 'America/Bogota')::date - g + interval '17 hours'
   from generate_series(1, 99) g`, [U1]);
assert.equal(await has100(), false);
ok('062: con 99 días aún no hay «Leyenda»');

await db.query(
  `insert into quest_log_entries (user_id, source_type, source_id, result, occurred_at)
   values ($1, 'habit', gen_random_uuid(), 'completed', now())`, [U1]);
assert.equal(await has100(), true);
const n = await one(`select title from notifications where user_id = $1 and title like '%Leyenda%'`, [U1]);
assert.equal(n.title, 'Nevi: ¡desbloqueaste «Leyenda»! 🏅');
ok('062: el día 100 desbloquea «Leyenda» y Nevi avisa');
