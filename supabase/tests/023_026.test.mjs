// Prueba las migraciones 023–026 sobre 001–022: Brain Dump (G.T.D.),
// Vision Board, Estadísticas e Inventario.
// Uso: cd supabase/tests && node 023_026.test.mjs
import assert from 'node:assert/strict';

import { U1, U2, createFullDb, migration, ok, rejects } from './bootstrap.mjs';

const { db, one, asUser } = await createFullDb();
for (const f of ['003_security.sql', '004_structure.sql', '005_rewards.sql', '006_store.sql',
  '007_daily.sql', '008_fix_exploits.sql', '009_profile_titles.sql', '010_missions.sql',
  '011_habits.sql', '012_dungeon.sql', '013_stage.sql', '014_goals.sql', '015_onboarding.sql',
  '016_settings.sql', '017_dungeon_breaks.sql', '018_marketplace.sql', '019_tavern.sql',
  '020_journal.sql', '021_boss_fight.sql', '022_rpgenie.sql']) {
  await db.exec(migration(f));
}
const mine = ['023_brain_dump.sql', '024_vision_board.sql', '025_stats.sql', '026_inventory.sql'];
for (const f of [...mine, ...mine]) await db.exec(migration(f)); // idempotentes
await db.exec(`insert into auth.users values ('${U1}', '{"username":"Ana"}'), ('${U2}', '{}')`);
ok('023–026 se aplican dos veces sin error');

const today = (await one(`select current_date::text d`)).d;
const call = (uid, sql, params) => asUser(uid, () => one(sql, params)).then((x) => x && x.r);
const capture = (uid, text) => call(uid, `select capture_thought($1) r`, [text]);

// 023 · Brain Dump ----------------------------------------------------------------------
const a = await capture(U1, '  Llamar al dentista  ');
const b = await capture(U1, 'Leer sobre jardines');
const c = await capture(U1, 'Organizar la mudanza');
const d = await capture(U1, 'Responder correo');
const e = await capture(U1, 'Pedir presupuesto');
await rejects(capture(U1, '   '), /invalid_content/);

let bd = await call(U1, `select brain_dump_overview() r`);
assert.equal(bd.inbox.length, 5);
assert.equal(bd.inbox.find((x) => x.id === a).content, 'Llamar al dentista');

await call(U1, `select file_thought($1, 'someday') r`, [b]);
await rejects(call(U1, `select file_thought($1, 'converted') r`, [b]), /invalid_status/);
await rejects(call(U2, `select file_thought($1, 'reference') r`, [a]), /thought_not_found/);

const conv = (id, kind, title, extra = {}) => call(U1,
  `select convert_thought(p_id => $1, p_kind => $2, p_title => $3, p_priority => 'high',
     p_delegated_to => $4) r`, [id, kind, title, extra.to ?? null]);
let r = await conv(a, 'task', 'Llamar al dentista');
assert.deepEqual(await one(`select source, priority, status from tasks where id = $1`, [r.id]),
  { source: 'gtd_diagnosis', priority: 'high', status: 'pending' });
r = await conv(c, 'project', 'Mudanza');
assert.equal(r.type, 'project');
assert.equal((await one(`select title from projects where id = $1`, [r.id])).title, 'Mudanza');
r = await conv(d, 'done', 'Responder correo');
assert.equal((await one(`select status from tasks where id = $1`, [r.id])).status, 'completed');
assert.deepEqual([r.reward.xp, r.reward.coins], [10, 0]); // regla de 2 min: mínimo, sin Monedas
r = await conv(e, 'delegated', 'Pedir presupuesto', { to: 'Luis' });
assert.deepEqual(await one(`select status, delegated_to from tasks where id = $1`, [r.id]),
  { status: 'delegated', delegated_to: 'Luis' });
await rejects(conv(a, 'task', 'Otra vez'), /thought_not_found/);
await rejects(conv(b, 'meta', 'x'), /invalid_kind/);

bd = await call(U1, `select brain_dump_overview() r`);
assert.deepEqual([bd.inbox.length, bd.someday.length, bd.converted_today], [0, 1, 4]);
await call(U1, `select delete_thought($1) r`, [b]);
assert.deepEqual((await call(U1, `select brain_dump_overview() r`)).someday, []);
assert.deepEqual((await call(U2, `select brain_dump_overview() r`)).inbox, []);
ok('023: capturar, archivar, convertir (tarea, proyecto, hecha, delegada) y borrar');

// 024 · Vision Board ----------------------------------------------------------------------
let v = await call(U1, `select vision_overview() r`);
assert.equal(v.content, null);
assert.deepEqual(v.items.map((i) => [i.kind, i.title, i.linked]), [['project', 'Mudanza', false]]);
await call(U1, `select save_vision('  Vivir con calma y salud  ') r`);
await call(U1, `select save_vision('Vivir con calma, salud y tiempo') r`);
const pid = v.items[0].id;
await call(U1, `select set_vision_link('project', $1, true) r`, [pid]);
await rejects(call(U2, `select set_vision_link('project', $1, true) r`, [pid]), /item_not_found/);
await rejects(call(U1, `select set_vision_link('task', $1, true) r`, [pid]), /invalid_kind/);
v = await call(U1, `select vision_overview() r`);
assert.equal(v.content, 'Vivir con calma, salud y tiempo');
assert.equal(v.items[0].linked, true);
assert.equal((await call(U2, `select vision_overview() r`)).content, null);
ok('024: guardar la visión y vincular Metas y Proyectos');

// 025 · Estadísticas -----------------------------------------------------------------------
const skill = (await one(`insert into skills (user_id, name) values ($1, 'Salud') returning id`, [U1])).id;
const h = (await one(`insert into habits (user_id, name, type, skill_id) values ($1, 'Leer', 'good', $2) returning id`,
  [U1, skill])).id;
await call(U1, `select complete_habit($1, $2::date) r`, [h, today]);
let s = await call(U1, `select stats_overview($1::date) r`, [today]);
assert.equal(s.missions, 1);
assert.equal(s.xp, 20);
assert.equal(s.xp_by_day.length, 7);
assert.equal(s.xp_by_day[6].xp, 20);
assert.deepEqual(s.xp_by_skill, [{ name: 'Salud', xp: 10 }]);
assert.deepEqual(s.top_habits, [{ name: 'Leer', days: 1, streak: 1 }]);
s = await call(U2, `select stats_overview($1::date) r`, [today]);
assert.deepEqual([s.xp, s.missions, s.xp_by_skill, s.top_habits], [0, 0, [], []]);
ok('025: stats_overview compara semanas, reparte XP por día y Área y aísla jugadores');

// 026 · Inventario -------------------------------------------------------------------------
await db.query(`update character_stats set coins = 500 where user_id = $1`, [U1]);
await call(U1, `select purchase('elixir') r`);
await db.query(`insert into achievements (code, name, reward_coins) values ('first', 'Primer paso', 50),
  ('secret', 'Secreto', 0)`);
await db.query(`update achievements set is_hidden = true where code = 'secret'`);
await db.query(`insert into user_achievements (user_id, achievement_id)
  select $1, id from achievements where code = 'first'`, [U1]);
let inv = await call(U1, `select inventory_overview() r`);
assert.deepEqual([inv.elixirs, inv.chests, inv.passes], [1, 0, 0]);
assert.deepEqual(inv.achievements.map((x) => [x.name, !!x.unlocked_at]), [['Primer paso', true]]);
inv = await call(U2, `select inventory_overview() r`);
assert.deepEqual([inv.elixirs, inv.achievements.map((x) => !!x.unlocked_at)], [0, [false]]);
ok('026: inventory_overview lista objetos, logros visibles y desbloqueos por jugador');
