// Prueba la migración 063 (meta diaria de XP).
// Uso: cd supabase/tests && node 063_daily_xp_goal.test.mjs
import assert from 'node:assert/strict';

import { U1, U2, createFullDb, migration, ok, rejects } from './bootstrap.mjs';

const { db, one, asUser } = await createFullDb();
for (const f of ['003_security.sql', '004_structure.sql', '005_rewards.sql', '006_store.sql',
  '007_daily.sql', '008_fix_exploits.sql', '009_profile_titles.sql', '010_missions.sql',
  '011_habits.sql', '012_dungeon.sql', '013_stage.sql', '014_goals.sql', '015_onboarding.sql',
  '016_settings.sql', '017_dungeon_breaks.sql', '036_device_notifications.sql',
  '043_settings_digest.sql', '045_more_reminders.sql', '048_daily_reminders.sql',
  '052_challenges_league.sql', '063_daily_xp_goal.sql', '063_daily_xp_goal.sql']) {
  await db.exec(migration(f));
}
await db.exec(`insert into auth.users values ('${U1}', '{}'), ('${U2}', '{}')`);
ok('063 se aplica dos veces sin error');

const call = (uid, sql, params) => asUser(uid, () => one(sql, params)).then((x) => x && x.r);
const goal = (uid) => call(uid, `select daily_goal() r`);
const xpTarget = (uid) => call(uid, `select challenges_overview() r`).then((o) => o.daily[0].target);
const setGoal = (uid, n) => asUser(uid, () => db.query(
  `update game_master_settings set daily_xp_goal = $1 where user_id = $2`, [n, uid]));
const log = (uid, xp) => db.query(
  `insert into quest_log_entries (user_id, source_type, source_id, result, xp_awarded)
   values ($1, 'task', gen_random_uuid(), 'completed', $2)`, [uid, xp]);

assert.deepEqual(await goal(U1), { xp: 0, goal: 30 });
assert.equal((await call(U1, `select settings_overview() r`)).daily_xp_goal, 30);
ok('063: la meta por defecto es 30 XP (igual que antes)');

await setGoal(U1, 50);
await log(U1, 40);
assert.deepEqual(await goal(U1), { xp: 40, goal: 50 });
assert.equal(await xpTarget(U1), 50);
assert.equal(await xpTarget(U2), 30);
assert.equal((await call(U1, `select settings_overview() r`)).daily_xp_goal, 50);
ok('063: cada quien tiene su meta; el desafío «Gana N XP» la usa');

await rejects(call(U1, `select claim_challenge('xp') r`), /challenge_locked/);
await log(U1, 10);
await call(U1, `select claim_challenge('xp') r`);
ok('063: el cofre de XP se abre al llegar a la meta elegida, no antes');

await rejects(setGoal(U1, 10), /daily_xp_goal_check/);
ok('063: solo 30, 50 o 100 (nunca una meta que abarate el cofre)');
