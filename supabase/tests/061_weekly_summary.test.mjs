// Prueba la migración 061 (resumen semanal de Nevi).
// Uso: cd supabase/tests && node 061_weekly_summary.test.mjs
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
  '061_weekly_summary.sql', '061_weekly_summary.sql']) {
  await db.exec(migration(f));
}
await db.exec(`insert into auth.users values ('${U1}', '{}'), ('${U2}', '{}')`);
ok('061 se aplica dos veces sin error');

const monday = (await one(
  `select date_trunc('week', now() at time zone 'America/Bogota')::date::text d`)).d;
// Al mediodía de Colombia (17:00 UTC), N días después del lunes (negativo: semana pasada).
const log = (uid, day, xp, source = 'task') => db.query(
  `insert into quest_log_entries (user_id, source_type, source_id, result, xp_awarded, occurred_at)
   values ($1, $2, gen_random_uuid(), 'completed', $3, $4::date + $5::int + interval '17 hours')`,
  [uid, source, xp, monday, day]);

// U1: esta semana 2 tareas y un hábito el lunes (1 día, 50 XP); la pasada 20 XP.
await log(U1, 0, 20); await log(U1, 0, 20); await log(U1, 0, 10, 'habit');
await log(U1, -3, 20);
// U2: solo la semana pasada.
await log(U2, -2, 15);

assert.equal((await one(`select _weekly_summary() n`)).n, 2);
const n1 = await one(`select type::text, title, message from notifications where user_id = $1`, [U1]);
assert.equal(n1.type, 'motivational');
assert.equal(n1.title, 'Nevi: tu semana en LifeQuest 📊');
assert.match(n1.message, /^50 XP, 1 de 7 días con actividad y 2 tareas\. ¡30 XP más que la semana pasada!/);
assert.match(n1.message, /¡Vamos por otra semana!$/);
ok('061: resume XP, días, tareas y la mejora frente a la semana pasada');

const n2 = await one(`select title, message from notifications where user_id = $1`, [U2]);
assert.equal(n2.title, 'Nevi: una semana tranquila 🌙');
assert.ok(!/culpa|perdiste|fallaste/i.test(n2.message));
ok('061: una semana sin actividad recibe ánimo, nunca culpa');

await one(`select _weekly_summary() n`);
assert.equal((await one(`select count(*)::int c from notifications`)).c, 2);
ok('061: correr dos veces no duplica el aviso (event_key por semana)');
