// Prueba las migraciones 018–022 sobre 001–017: market_overview, Taverna
// (tavern_overview, create_npc, accept_npc_mission), journal_overview,
// goals_overview y current_mission.
// Uso: cd supabase/tests && node 018_022.test.mjs
import assert from 'node:assert/strict';

import { U1, U2, createFullDb, migration, ok, rejects } from './bootstrap.mjs';

const { db, one, asUser } = await createFullDb();
for (const f of ['003_security.sql', '004_structure.sql', '005_rewards.sql', '006_store.sql',
  '007_daily.sql', '008_fix_exploits.sql', '009_profile_titles.sql', '010_missions.sql',
  '011_habits.sql', '012_dungeon.sql', '013_stage.sql', '014_goals.sql', '015_onboarding.sql',
  '016_settings.sql', '017_dungeon_breaks.sql']) {
  await db.exec(migration(f));
}
const mine = ['018_marketplace.sql', '019_tavern.sql', '020_journal.sql', '021_boss_fight.sql',
  '022_rpgenie.sql'];
for (const f of [...mine, ...mine]) await db.exec(migration(f)); // idempotentes
await db.exec(`insert into auth.users values ('${U1}', '{"username":"Ana"}'), ('${U2}', '{}')`);
ok('018–022 se aplican dos veces sin error');

const today = (await one(`select current_date::text d`)).d;
const call = (uid, sql, params) => asUser(uid, () => one(sql, params)).then((x) => x && x.r);
const setCoins = (uid, coins) => db.query(`update character_stats set coins = $2 where user_id = $1`, [uid, coins]);

// 018 · Marketplace ------------------------------------------------------------------
let m = await call(U1, `select market_overview() r`);
assert.deepEqual([m.coins, m.passes, m.elixirs_stored, m.elixir_active, m.broken_streaks], [0, 0, 0, false, []]);
assert.deepEqual(m.items.map((i) => i.code), ['siesta', 'posada', 'banquete', 'elixir']);
assert.deepEqual(m.black_market.map((i) => [i.code, i.available]),
  [['pase_recuperacion', true], ['recuperar_racha', true]]);
assert.deepEqual(m.refuge.map((b) => [b.building, b.level, b.price]),
  [['huerto', 0, 120], ['biblioteca', 0, 120], ['estandarte', 0, 120]]);

await setCoins(U1, 500);
await db.query(`update character_stats set hp_current = 50 where user_id = $1`, [U1]);
await call(U1, `select purchase('elixir') r`);
await call(U1, `select buy_black_market('pase_recuperacion') r`);
await call(U1, `select upgrade_refuge('estandarte') r`);
m = await call(U1, `select market_overview() r`);
assert.deepEqual([m.coins, m.elixirs_stored, m.passes], [500 - 40 - 90 - 120, 1, 1]);
assert.equal(m.items.find((i) => i.code === 'elixir').available, false);
assert.equal(m.black_market.find((i) => i.code === 'pase_recuperacion').available, false);
assert.deepEqual(m.refuge.find((b) => b.building === 'estandarte'), {
  building: 'estandarte', level: 1, max_level: 4, price: 162 });

const habit = (await one(`insert into habits (user_id, name, type, broken_streak, broken_on)
  values ($1, 'Leer', 'good', 6, current_date - 1) returning id`, [U1])).id;
m = await call(U1, `select market_overview() r`);
assert.deepEqual(m.broken_streaks.map((b) => [b.name, b.streak]), [['Leer', 6]]);
await call(U1, `select use_recovery_pass($1) r`, [habit]);
m = await call(U1, `select market_overview() r`);
assert.deepEqual([m.passes, m.broken_streaks], [0, []]);

m = await call(U2, `select market_overview() r`);
assert.deepEqual([m.coins, m.elixirs_stored, m.passes, m.refuge[2].level], [0, 0, 0, 0]);
ok('018: market_overview refleja compras, límites, rachas por salvar y Refugio por jugador');

// 019 · Taverna -----------------------------------------------------------------------
const skill = (await one(`insert into skills (user_id, name) values ($1, 'Salud') returning id`, [U1])).id;
const foreign = (await one(`insert into skills (user_id, name) values ($1, 'Ajena') returning id`, [U2])).id;
const npc = (s, name = 'Vera') => call(U1,
  `select create_npc(p_name => $1, p_skill_id => $2, p_frequency => 'daily', p_noble_mission => $3) r`,
  [name, s, '  Que corras sin dolor  ']);

const vera = await npc(skill, '  Vera  ');
assert.deepEqual(await one(`select name, noble_mission, frequency from npcs where id = $1`, [vera]),
  { name: 'Vera', noble_mission: 'Que corras sin dolor', frequency: 'daily' });
await rejects(npc(foreign), /skill_not_found/);
await rejects(npc(null), /skill_not_found/);
await rejects(npc(skill, ' '), /invalid_name/);
await npc(skill, 'Orión');
await npc(skill, 'Brann');
await npc(skill, 'Cuarto'); // 3 + Estandarte nivel 1 = 4
await rejects(npc(skill, 'Quinto'), /npc_limit_reached/);
ok('019: create_npc valida nombre, skill propia y el límite con el Estandarte');

let t = await call(U1, `select tavern_overview() r`);
assert.deepEqual([t.npcs.length, t.npc_limit, t.instant_cost], [4, 4, 15]);
assert.deepEqual([t.npcs[0].skill_name, t.npcs[0].open_mission, t.npcs[0].free_at], ['Salud', null, null]);

await setCoins(U1, 100);
let res = await call(U1, `select accept_npc_mission($1, '  Correr 5 km  ') r`, [vera]);
assert.equal(res.cost, 0);
const task = await one(`select title, source, npc_id, skill_id from tasks where id = $1`, [res.task_id]);
assert.deepEqual(task, { title: 'Correr 5 km', source: 'npc', npc_id: vera, skill_id: skill });
await rejects(call(U1, `select accept_npc_mission($1, 'Otra') r`, [vera]), /npc_mission_open/);
await rejects(call(U1, `select accept_npc_mission($1, ' ') r`, [vera]), /invalid_title/);
await rejects(call(U2, `select accept_npc_mission($1, 'x') r`, [vera]), /npc_not_found/);

t = await call(U1, `select tavern_overview() r`);
assert.equal(t.npcs[0].open_mission.title, 'Correr 5 km');
assert.ok(t.npcs[0].free_at);

await db.query(`update tasks set created_at = now() - interval '1 hour' where id = $1`, [res.task_id]);
await call(U1, `select complete_task($1) r`, [res.task_id]);
res = await call(U1, `select accept_npc_mission($1, 'Estirar') r`, [vera]); // antes de 3 h: cuesta
assert.deepEqual([res.cost, res.coins], [15, 85 + 3]); // + Monedas de la misión cumplida
t = await call(U1, `select tavern_overview() r`);
assert.equal(t.npcs[0].completed, 1);
assert.deepEqual((await call(U2, `select tavern_overview() r`)).npcs, []);
ok('019: accept_npc_mission crea la tarea, cobra el atajo y bloquea la segunda abierta');

// 020 · Diario ----------------------------------------------------------------------------
const j = await call(U1, `select journal_overview($1::date) r`, [today]);
const titles = j.entries.map((e) => [e.source, e.title]);
assert.ok(titles.some(([s, n]) => s === 'npc' && n === 'Correr 5 km'));
assert.equal(j.summary.missions, 1);
assert.ok(j.summary.xp > 0);
assert.equal(j.summary.xp_prev, 0);
assert.deepEqual((await call(U2, `select journal_overview($1::date) r`, [today])).entries, []);
ok('020: journal_overview nombra cada entrada y resume la semana por jugador');

// 021 · Boss Fight ------------------------------------------------------------------------
const g = (await asUser(U1, () => one(`select create_goal('Media maratón', 's', 'm', 'a', 'r',
  current_date + 30, null, $1) id`, [skill]))).id;
const p = (await call(U1, `select create_project('Plan', null, null, null, $1) r`, [g])) ?? null;
const hit = (await call(U1, `select create_task('Primera salida larga del plan', null, 'high', null, null, null, $1) r`, [g])).id;
let b = (await call(U1, `select goals_overview() r`)).goals.find((x) => x.id === g);
assert.deepEqual([b.boss_current_hp, b.status, b.smart.specific, b.skill_name], [100, 'not_started', 's', 'Salud']);
assert.deepEqual(b.attacks.map((a) => [a.kind, a.damage]), [['task', 40], ['project', 30]]);
assert.ok(p);

await db.query(`update tasks set created_at = now() - interval '1 hour' where id = $1`, [hit]);
await call(U1, `select complete_task($1) r`, [hit]);
b = (await call(U1, `select goals_overview() r`)).goals.find((x) => x.id === g);
assert.deepEqual([b.boss_current_hp, b.status, b.attacks.length], [60, 'in_progress', 1]);
assert.deepEqual(b.hits.map((h) => [h.title, h.damage]), [['Primera salida larga del plan', 40]]);
assert.deepEqual((await call(U2, `select goals_overview() r`)).goals, []);
ok('021: goals_overview muestra vida, ataques, golpes y estado por jugador');

// 022 · RPGenie -----------------------------------------------------------------------------
const mk = (title, prio, due) => call(U1,
  `select create_task($1, null, $2, $3::timestamptz) r`, [title, prio, due]).then((x) => x.id);
await mk('Ordenar', 'low', null);
const high = await mk('Informe', 'high', null);
const soon = await mk('Pagar luz', 'low', new Date(Date.now() + 3600e3).toISOString());
let c = await call(U1, `select current_mission() r`);
assert.deepEqual([c.mission.id, c.mission.reason], [soon, 'critical']);
c = await call(U1, `select current_mission($1::uuid[]) r`, [[soon]]);
assert.deepEqual([c.mission.id, c.mission.reason, c.skipped_count], [high, 'high', 1]);
c = await call(U1, `select current_mission($1::uuid[]) r`, [[soon, high]]);
assert.equal(c.mission.reason, 'next');
assert.equal((await call(U2, `select current_mission() r`)).mission, null);
ok('022: current_mission sigue RF-097, respeta "Ahora no" y aísla jugadores');
