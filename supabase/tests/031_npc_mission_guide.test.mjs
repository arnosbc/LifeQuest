// Prueba la migración 031 (guía de la misión del NPC) sobre 001–030.
// Uso: cd supabase/tests && node 031_npc_mission_guide.test.mjs
import assert from 'node:assert/strict';

import { U1, U2, createFullDb, migration, ok, rejects } from './bootstrap.mjs';

const { db, one, asUser } = await createFullDb();
for (const f of ['003_security.sql', '004_structure.sql', '005_rewards.sql', '006_store.sql',
  '007_daily.sql', '008_fix_exploits.sql', '009_profile_titles.sql', '010_missions.sql',
  '011_habits.sql', '012_dungeon.sql', '013_stage.sql', '014_goals.sql', '015_onboarding.sql',
  '016_settings.sql', '017_dungeon_breaks.sql', '018_marketplace.sql', '019_tavern.sql',
  '020_journal.sql', '021_boss_fight.sql', '022_rpgenie.sql', '023_brain_dump.sql',
  '024_vision_board.sql', '025_stats.sql', '026_inventory.sql', '027_daily_chest.sql',
  '028_edit_delete.sql', '029_notifications.sql', '030_npc_noble_mission.sql']) {
  await db.exec(migration(f));
}
await db.exec(migration('031_npc_mission_guide.sql'));
await db.exec(migration('031_npc_mission_guide.sql')); // idempotente
await db.exec(`insert into auth.users values ('${U1}', '{}'), ('${U2}', '{}')`);
ok('031 se aplica dos veces sin error');

const versions = (await one(`select count(*)::int n from pg_proc where proname = 'accept_npc_mission'`)).n;
assert.equal(versions, 1);
ok('031: queda una sola versión de accept_npc_mission');

const call = (uid, sql, params) => asUser(uid, () => one(sql, params)).then((x) => x && x.r);
const skill = (await one(`insert into skills (user_id, name) values ($1, 'Matemáticas') returning id`, [U1])).id;
const npc = (name) => call(U1, `select create_npc($1, $2, 'weekly', 'Álgebra lineal') r`, [name, skill]);
const ada = await npc('Ada');
const gauss = await npc('Gauss');

const guide = 'Objetivo: escalonar una matriz.\n\nPasos:\n1. Resuelve x + y = 3, x - y = 1';
let res = await call(U1, `select accept_npc_mission($1, 'Eliminación gaussiana', $2) r`, [ada, `  ${guide}  `]);
assert.deepEqual(await one(`select title, description, source from tasks where id = $1`, [res.task_id]),
  { title: 'Eliminación gaussiana', description: guide, source: 'npc' });

let t = await call(U1, `select tavern_overview() r`);
assert.equal(t.npcs.find((n) => n.id === ada).open_mission.description, guide);
ok('031: accept_npc_mission guarda la guía y tavern_overview la devuelve');

// Sin guía (llamada antigua de dos argumentos) o con guía vacía: sin descripción.
res = await call(U1, `select accept_npc_mission($1, 'Matrices') r`, [gauss]);
assert.equal((await one(`select description from tasks where id = $1`, [res.task_id])).description, null);
t = await call(U1, `select tavern_overview() r`);
assert.equal(t.npcs.find((n) => n.id === gauss).open_mission.description, null);
ok('031: la llamada de dos argumentos sigue funcionando y deja la guía vacía');

const euler = await npc('Euler');
await rejects(call(U1, `select accept_npc_mission($1, 'Larga', $2) r`, [euler, 'x'.repeat(4001)]),
  /invalid_description/);
res = await call(U1, `select accept_npc_mission($1, 'Vacía', '   ') r`, [euler]);
assert.equal((await one(`select description from tasks where id = $1`, [res.task_id])).description, null);
await rejects(call(U2, `select accept_npc_mission($1, 'Ajena', 'x') r`, [ada]), /npc_not_found/);
assert.deepEqual((await call(U2, `select tavern_overview() r`)).npcs, []);
ok('031: limita la guía a 4000 caracteres y aísla los NPC entre usuarios');
