// Prueba la migración 034 (Brain Dump → Meta S.M.A.R.T.) sobre 001–033.
// Uso: cd supabase/tests && node 034_brain_dump_goal.test.mjs
import assert from 'node:assert/strict';

import { U1, U2, createFullDb, migration, ok, rejects } from './bootstrap.mjs';

const { db, one, asUser } = await createFullDb();
// 032 necesita el esquema storage de Supabase; aquí no hace falta.
for (const f of ['003_security.sql', '004_structure.sql', '005_rewards.sql', '006_store.sql',
  '007_daily.sql', '008_fix_exploits.sql', '009_profile_titles.sql', '010_missions.sql',
  '011_habits.sql', '012_dungeon.sql', '013_stage.sql', '014_goals.sql', '015_onboarding.sql',
  '016_settings.sql', '017_dungeon_breaks.sql', '018_marketplace.sql', '019_tavern.sql',
  '020_journal.sql', '021_boss_fight.sql', '022_rpgenie.sql', '023_brain_dump.sql',
  '024_vision_board.sql', '025_stats.sql', '026_inventory.sql', '027_daily_chest.sql',
  '028_edit_delete.sql', '029_notifications.sql', '030_npc_noble_mission.sql',
  '031_npc_mission_guide.sql', '033_dungeon_rewards.sql']) {
  await db.exec(migration(f));
}
await db.exec(migration('034_brain_dump_goal.sql'));
await db.exec(migration('034_brain_dump_goal.sql')); // idempotente
await db.exec(`insert into auth.users values ('${U1}', '{}'), ('${U2}', '{}')`);
ok('034 se aplica dos veces sin error');

const call = (uid, sql, params) => asUser(uid, () => one(sql, params)).then((x) => x && x.r);
const skill = (await one(`insert into skills (user_id, name) values ($1, 'Salud') returning id`, [U1])).id;
const thought = await call(U1, `select capture_thought('Correr una media maratón') r`);

let b = await call(U1, `select brain_dump_overview() r`);
assert.deepEqual(b.skills, [{ id: skill, name: 'Salud' }]);
assert.equal(b.inbox.length, 1);
assert.deepEqual((await call(U2, `select brain_dump_overview() r`)).skills, []);
ok('034: brain_dump_overview trae las skills del jugador');

const toGoal = (uid, id, extra = {}) => {
  const a = { title: 'Correr 21 km', s: 'Terminar una media maratón', m: 'Cruzar la meta',
    a: 'Entreno 3 veces por semana', r: 'Quiero más energía', due: '2099-06-01',
    t: null, skill: null, ...extra };
  return call(uid, `select convert_thought_to_goal($1, $2, $3, $4, $5, $6, $7::date, $8, $9) r`,
    [id, a.title, a.s, a.m, a.a, a.r, a.due, a.t, a.skill]);
};

// Las validaciones de create_goal (014) se aplican y no tocan la idea.
await rejects(toGoal(U1, thought, { m: ' ' }), /smart_incomplete/);
await rejects(toGoal(U1, thought, { due: '2000-01-01' }), /invalid_due_date/);
await rejects(toGoal(U2, thought), /thought_not_found/);
assert.equal((await call(U1, `select brain_dump_overview() r`)).inbox.length, 1);
assert.equal((await one(`select count(*)::int n from goals`)).n, 0);

const res = await toGoal(U1, thought, { skill, t: 'Mitad de camino en marzo' });
assert.equal(res.type, 'goal');
assert.deepEqual(await one(`select title, skill_id, smart_measurable, smart_timebound from goals where id = $1`,
  [res.id]), { title: 'Correr 21 km', skill_id: skill, smart_measurable: 'Cruzar la meta',
  smart_timebound: 'Mitad de camino en marzo' });
assert.deepEqual(await one(`select status, converted_to_type, converted_to_id from brain_dump_entries
  where id = $1`, [thought]), { status: 'converted', converted_to_type: 'goal', converted_to_id: res.id });
b = await call(U1, `select brain_dump_overview() r`);
assert.deepEqual([b.inbox.length, b.converted_today], [0, 1]);
await rejects(toGoal(U1, thought), /thought_not_found/);
ok('034: convert_thought_to_goal crea la Meta, saca la idea de la bandeja y no se repite');
