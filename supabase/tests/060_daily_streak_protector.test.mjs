// Prueba la migración 060 (Protector de la racha diaria).
// Uso: cd supabase/tests && node 060_daily_streak_protector.test.mjs
import assert from 'node:assert/strict';

import { U1, U2, createFullDb, migration, ok } from './bootstrap.mjs';

const { db, one } = await createFullDb();
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
  '056_activity_streak.sql', '060_daily_streak_protector.sql',
  '060_daily_streak_protector.sql']) {
  await db.exec(migration(f));
}
await db.exec(`insert into auth.users values ('${U1}', '{}'), ('${U2}', '{}')`);
ok('060 se aplica dos veces sin error');

const today = (await one(`select (now() at time zone 'America/Bogota')::date::text d`)).d;
// Actividad «hace N días» al mediodía de Colombia (17:00 UTC).
const log = (uid, daysAgo) => db.query(
  `insert into quest_log_entries (user_id, source_type, source_id, result, occurred_at)
   values ($1, 'task', gen_random_uuid(), 'completed', $2::date - $3::int + interval '17 hours')`,
  [uid, today, daysAgo]);
const pass = (uid) => db.query(`insert into recovery_passes (user_id) values ($1)`, [uid]);
const streak = (uid) => one(`select _activity_streak($1, $2::date, -300) s`, [uid, today]).then((x) => x.s);
const protect = () => one(`select _protect_daily_streaks() n`).then((x) => x.n);

// U1: 3 días seguidos hasta anteayer, ayer nada, 1 protector.
await log(U1, 4); await log(U1, 3); await log(U1, 2);
await pass(U1);
// U2: actividad ayer y un protector: no hace falta gastarlo.
await log(U2, 1);
await pass(U2);
assert.equal(await streak(U1), 0);

assert.equal(await protect(), 1);
const used = await one(`select used_at is not null used, protected_day::text as day, habit_id
                        from recovery_passes where user_id = $1`, [U1]);
assert.ok(used.used);
assert.equal(used.day, (await one(`select ($1::date - 1)::text d`, [today])).d);
assert.equal(used.habit_id, null);
ok('060: sin actividad ayer, se gasta un protector y protege ayer');

assert.equal(await streak(U1), 3);
ok('060: la racha sigue viva y el día protegido no suma (3, no 4)');

const n = await one(`select type::text, title, message from notifications where user_id = $1`, [U1]);
assert.equal(n.type, 'informational');
assert.equal(n.title, 'Nevi: usé un Protector y tu racha sigue viva 🛡️');
assert.match(n.message, /Tus 3 días de racha siguen en pie/);
ok('060: Nevi lo cuenta en el resumen de la mañana (informativo)');

assert.equal(await protect(), 0);
assert.equal((await one(`select count(*)::int c from recovery_passes where used_at is not null`)).c, 1);
ok('060: correr otra vez no gasta más, y quien tuvo actividad ayer conserva su protector');

await log(U1, 0);
assert.equal(await streak(U1), 4);
ok('060: con actividad hoy la racha sigue sumando a través del día protegido');
