// Prueba la migración 052 (Desafíos y Liga) sobre 001–012.
// Uso: cd supabase/tests && node 052_challenges_league.test.mjs
import assert from 'node:assert/strict';

import { U1, U2, createFullDb, migration, ok, rejects } from './bootstrap.mjs';

const { db, one, asUser } = await createFullDb();
for (const f of ['003_security.sql', '004_structure.sql', '005_rewards.sql', '006_store.sql',
  '007_daily.sql', '008_fix_exploits.sql', '009_profile_titles.sql', '010_missions.sql',
  '011_habits.sql', '012_dungeon.sql']) {
  await db.exec(migration(f));
}
await db.exec(migration('052_challenges_league.sql'));
await db.exec(migration('052_challenges_league.sql')); // idempotente
await db.exec(`insert into auth.users values ('${U1}', '{}'), ('${U2}', '{}')`);
ok('052 se aplica dos veces sin error');

const call = (uid, sql, params) => asUser(uid, () => one(sql, params)).then((x) => x && x.r);
const overview = (uid) => call(uid, `select challenges_overview() r`);
const claim = (uid, key) => call(uid, `select claim_challenge($1) r`, [key]);
// Lo que ya pagó el servidor: filas de la Bitácora (las RPC se prueban en su migración).
const log = (uid, source, xp, when = 'now()') => db.query(
  `insert into quest_log_entries (user_id, source_type, source_id, result, xp_awarded, occurred_at)
   values ($1, $2, gen_random_uuid(), 'completed', $3, ${when})`, [uid, source, xp]);
const coins = (uid) => one(`select coins from character_stats where user_id = $1`, [uid])
  .then((x) => x?.coins ?? 0);

let o = await overview(U1);
assert.deepEqual(o.daily.map((d) => [d.key, d.progress, d.target, d.claimed]),
  [['xp', 0, 30, false], ['tasks', 0, 2, false], ['focus', 0, 1, false]]);
assert.deepEqual(o.month, { progress: 0, target: 30, coins: 60, claimed: false, days_left: o.month.days_left });
assert.equal(o.league.division, 0);
assert.equal(o.league.rivals.length, 10);
assert.equal(new Set(o.league.rivals.map((r) => r.name)).size, 10);
ok('052: overview vacío con 3 desafíos, mes y liga de 10 rivales sin nombres repetidos');

await rejects(claim(U1, 'xp'), /challenge_locked/);
await rejects(claim(U1, 'nada'), /challenge_not_found/);
await log(U1, 'task', 20);
await log(U1, 'task', 15);
o = await overview(U1);
assert.deepEqual(o.daily.slice(0, 2).map((d) => d.progress), [35, 2]);
const before = await coins(U1);
await claim(U1, 'xp');
await claim(U1, 'tasks');
assert.equal(await coins(U1), before + 10);
await rejects(claim(U1, 'xp'), /challenge_already_claimed/);
o = await overview(U1);
assert.deepEqual(o.daily.map((d) => d.claimed), [true, true, false]);
assert.equal(o.month.progress, 2);
ok('052: cobra cada desafío una vez, paga Monedas y suma puntos al mes');

assert.deepEqual((await overview(U2)).daily.map((d) => [d.progress, d.claimed]),
  [[0, false], [0, false], [0, false]]);
await rejects(claim(U2, 'xp'), /challenge_locked/);
ok('052: los desafíos de un jugador no cuentan para otro');

await rejects(claim(U1, 'month'), /challenge_locked/);
await db.query(`insert into quest_log_entries (user_id, source_type, source_id, result, occurred_at)
  select $1, 'challenge', gen_random_uuid(), 'completed', now() from generate_series(1, 28)`, [U1]);
await claim(U1, 'month');
await rejects(claim(U1, 'month'), /challenge_already_claimed/);
ok('052: el Desafío del mes se cobra con 30 puntos, una sola vez');

const rivals1 = (await overview(U1)).league.rivals;
assert.deepEqual((await overview(U1)).league.rivals, rivals1);
ok('052: los rivales son estables entre recargas');

// Semana pasada con mucha XP → sube; un jugador sin XP en división alta → baja.
await db.query(`delete from league_weeks`);
await db.query(`insert into league_weeks (user_id, week_start, division) values
  ($1, date_trunc('week', current_date)::date - 7, 0),
  ($2, date_trunc('week', current_date)::date - 7, 5)`, [U1, U2]);
await log(U1, 'task', 5000, `date_trunc('week', current_date) - interval '3 days'`);
o = await overview(U1);
assert.equal(o.league.division, 1);
assert.equal(o.league.last_result, 'promoted');
o = await overview(U2);
assert.equal(o.league.division, 4);
assert.equal(o.league.last_result, 'demoted');
ok('052: top 3 sube de división y los últimos 3 bajan');

const own = await asUser(U2, () => db.query(`select user_id from league_weeks`));
assert.ok(own.rows.every((r) => r.user_id === U2));
ok('052: league_weeks solo muestra las filas propias');
