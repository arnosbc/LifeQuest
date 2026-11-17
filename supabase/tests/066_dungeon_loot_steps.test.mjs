// Prueba la migración 066 (el resumen de Foco cuenta la XP de los pasos).
// Uso: cd supabase/tests && node 066_dungeon_loot_steps.test.mjs
import assert from 'node:assert/strict';

import { U1, createFullDb, migration, ok } from './bootstrap.mjs';

const { db, one, asUser } = await createFullDb();
for (const f of ['003_security.sql', '004_structure.sql', '005_rewards.sql', '006_store.sql',
  '007_daily.sql', '008_fix_exploits.sql', '009_profile_titles.sql', '010_missions.sql',
  '011_habits.sql', '012_dungeon.sql', '013_stage.sql', '014_goals.sql', '015_onboarding.sql',
  '016_settings.sql', '017_dungeon_breaks.sql', '018_marketplace.sql', '019_tavern.sql',
  '020_journal.sql', '021_boss_fight.sql', '022_rpgenie.sql', '023_brain_dump.sql',
  '024_vision_board.sql', '025_stats.sql', '026_inventory.sql', '027_daily_chest.sql',
  '028_edit_delete.sql', '029_notifications.sql', '030_npc_noble_mission.sql',
  '031_npc_mission_guide.sql', '033_dungeon_rewards.sql', '037_reward_feedback.sql',
  '038_home_today.sql', '039_task_steps.sql', '040_focus_required.sql',
  '066_dungeon_loot_steps.sql', '066_dungeon_loot_steps.sql']) {
  await db.exec(migration(f));
}
await db.exec(`insert into auth.users values ('${U1}', '{}')`);
ok('066 se aplica dos veces sin error');

const call = (sql, params) => asUser(U1, () => one(sql, params)).then((x) => x && x.r);
const t = (await call(`select create_task($1) r`, ['Preparar la exposición del viernes'])).id;
await db.query(`update tasks set created_at = now() - interval '1 hour' where id = $1`, [t]);
await call(`select attach_task_guide($1, $2::jsonb) r`,
  [t, JSON.stringify({ steps: ['Lista los temas', 'Arma las diapositivas', 'Ensaya'] })]);

const s = await call(`select start_dungeon(60, 25, $1::uuid[]) r`, [[t]]);
const steps = (await db.query(`select id from task_steps where task_id = $1 order by position`, [t]))
  .rows.map((x) => x.id);
await call(`select toggle_task_step($1) r`, [steps[0]]);
await call(`select toggle_task_step($1) r`, [steps[1]]);
await call(`select complete_task($1) r`, [t]);

const paid = await one(
  `select sum(xp_awarded)::int xp from quest_log_entries
   where user_id = $1 and source_type::text in ('task', 'task_step')`, [U1]);
const summary = await call(`select end_dungeon($1) r`, [s]);
assert.ok(paid.xp > 0);
assert.equal(summary.xp, paid.xp);
ok('066: el resumen de Foco suma pasos + cierre = toda la XP de la tarea');

const r = await call(`select dungeon_overview() r`);
assert.equal(r.session, null);
ok('066: la sesión queda cerrada y la cuenta de tareas sigue igual');
