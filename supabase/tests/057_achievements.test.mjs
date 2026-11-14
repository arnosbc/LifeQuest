// Prueba la migración 057 (logros) sobre 001–056.
// Uso: cd supabase/tests && node 057_achievements.test.mjs
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
  '057_achievements.sql', '057_achievements.sql']) {
  await db.exec(migration(f));
}
await db.exec(`insert into auth.users values ('${U1}', '{}'), ('${U2}', '{}')`);
assert.equal((await one(`select count(*)::int n from achievements`)).n, 12);
ok('057 se aplica dos veces sin error y deja 12 logros');

const log = (uid, source, daysAgo = 0) => db.query(
  `insert into quest_log_entries (user_id, source_type, source_id, result, occurred_at)
   values ($1, $2, gen_random_uuid(), 'completed', now() - make_interval(days => $3))`,
  [uid, source, daysAgo]);
const unlocked = (uid) => db.query(
  `select a.code from user_achievements ua join achievements a on a.id = ua.achievement_id
   where ua.user_id = $1 order by a.code`, [uid]).then((r) => r.rows.map((x) => x.code));
const coins = (uid) => one(`select coins from character_stats where user_id = $1`, [uid]).then((x) => x?.coins ?? 0);

await log(U1, 'task');
assert.deepEqual(await unlocked(U1), ['first_task']);
assert.equal(await coins(U1), 10);
const n = await one(`select title from notifications where user_id = $1 and category = 'achievement'`, [U1]);
assert.equal(n.title, 'Nevi: ¡desbloqueaste «Primer paso»! 🏅');
ok('057: la primera tarea desbloquea «Primer paso», paga 10 Monedas y Nevi avisa');

await log(U1, 'task');
assert.equal(await coins(U1), 10);
assert.equal((await one(`select count(*)::int n from quest_log_entries where user_id = $1 and source_type = 'achievement'`, [U1])).n, 1);
ok('057: un logro nunca se cobra dos veces');

await log(U1, 'habit', 1);
await log(U1, 'habit', 2);
assert.deepEqual(await unlocked(U1), ['first_habit', 'first_task', 'streak_3']);
ok('057: hábito y racha de 3 días con actividad');

assert.deepEqual(await unlocked(U2), []);
await asUser(U2, async () => {
  assert.deepEqual((await db.query(`select * from user_achievements`)).rows, []);
});
ok('057: los logros de uno no aparecen para otro');

const inv = await asUser(U1, () => one(`select inventory_overview() r`)).then((x) => x.r.achievements);
assert.equal(inv.length, 12);
assert.equal(inv.filter((a) => a.unlocked_at).length, 3);
ok('057: la pantalla de Logros (inventory_overview) muestra 3 de 12');
