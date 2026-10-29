// Prueba la migración 030 (noble misión obligatoria) sobre 001–029.
// Uso: cd supabase/tests && node 030_npc_noble_mission.test.mjs
import assert from 'node:assert/strict';

import { U1, createFullDb, migration, ok, rejects } from './bootstrap.mjs';

const { db, one, asUser } = await createFullDb();
for (const f of ['003_security.sql', '004_structure.sql', '005_rewards.sql', '006_store.sql',
  '007_daily.sql', '008_fix_exploits.sql', '009_profile_titles.sql', '010_missions.sql',
  '011_habits.sql', '012_dungeon.sql', '013_stage.sql', '014_goals.sql', '015_onboarding.sql',
  '016_settings.sql', '017_dungeon_breaks.sql', '018_marketplace.sql', '019_tavern.sql',
  '020_journal.sql', '021_boss_fight.sql', '022_rpgenie.sql', '023_brain_dump.sql',
  '024_vision_board.sql', '025_stats.sql', '026_inventory.sql', '027_daily_chest.sql',
  '028_edit_delete.sql', '029_notifications.sql']) {
  await db.exec(migration(f));
}
await db.exec(migration('030_npc_noble_mission.sql'));
await db.exec(migration('030_npc_noble_mission.sql')); // idempotente
await db.exec(`insert into auth.users values ('${U1}', '{}')`);
ok('030 se aplica dos veces sin error');

const call = (sql, params) => asUser(U1, () => one(sql, params)).then((x) => x && x.r);
const skill = (await one(`insert into skills (user_id, name) values ($1, 'Diseño') returning id`, [U1])).id;
const npc = (mission) => call(`select create_npc('Iris', $1, 'weekly', $2) r`, [skill, mission]);

await rejects(npc(null), /invalid_noble_mission/);
await rejects(npc('   '), /invalid_noble_mission/);
await rejects(npc('x'.repeat(301)), /invalid_noble_mission/);
const id = await npc('  Fundamentos de diseño gráfico  ');
assert.equal((await one(`select noble_mission from npcs where id = $1`, [id])).noble_mission,
  'Fundamentos de diseño gráfico');
ok('030: create_npc exige la noble misión (1–300 caracteres) y la guarda sin espacios');
