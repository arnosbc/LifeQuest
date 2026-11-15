// Prueba la migración 059 (calendario de racha del Perfil) sobre 001–056.
// Uso: cd supabase/tests && node 059_activity_month.test.mjs
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
  '041_home_extras.sql', '056_activity_streak.sql', '059_activity_month.sql',
  '059_activity_month.sql']) {
  await db.exec(migration(f));
}
await db.exec(`insert into auth.users values ('${U1}', '{}'), ('${U2}', '{}')`);
ok('059 se aplica dos veces sin error');

// Día fijo a mitad de mes para que «ayer» y «hoy» caigan en el mismo mes.
const day = '2026-11-14';
const log = (uid, at, source = 'task', result = 'completed') => db.query(
  `insert into quest_log_entries (user_id, source_type, source_id, result, occurred_at)
   values ($1, $2, gen_random_uuid(), $3, $4::timestamptz)`, [uid, source, result, at]);
const month = (uid, offset = 0) =>
  asUser(uid, () => one(`select activity_month($1::date, $2) r`, [day, offset])).then((x) => x.r);

await log(U1, '2026-11-13 12:00Z');
await log(U1, '2026-11-14 12:00Z', 'habit');
await log(U1, '2026-11-14 13:00Z', 'dungeon');
await log(U1, '2026-11-14 14:00Z', 'daily_chest'); // no cuenta
await log(U1, '2026-11-14 15:00Z', 'task', 'failed'); // no cuenta
await log(U1, '2026-10-31 12:00Z'); // otro mes
await log(U2, '2026-11-10 12:00Z');

let r = await month(U1);
assert.deepEqual(r.days, { 13: 1, 14: 2 });
ok('059: cuenta actividades reales por día del mes; cofres, fallos y otros meses no');

// 1 de noviembre 02:00 UTC = 31 de octubre en Colombia (−300).
await log(U1, '2026-11-01 02:00Z');
r = await month(U1, -300);
assert.equal(r.days['1'], undefined);
ok('059: el desfase decide el día local');

r = await month(U2);
assert.deepEqual(r.days, { 10: 1 });
ok('059: cada quien ve solo sus días (RLS)');
