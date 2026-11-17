// Prueba la migración 072 (Liga con personas reales y premios al top 3).
// Uso: cd supabase/tests && node 072_real_league.test.mjs
import assert from 'node:assert/strict';

import { U1, U2, createFullDb, migration, ok } from './bootstrap.mjs';

const { db, one, asUser } = await createFullDb();
for (const f of ['003_security.sql', '004_structure.sql', '005_rewards.sql', '006_store.sql',
  '007_daily.sql', '008_fix_exploits.sql', '009_profile_titles.sql', '010_missions.sql',
  '011_habits.sql', '012_dungeon.sql', '029_notifications.sql', '052_challenges_league.sql',
  '064_league_notices.sql', '072_real_league.sql', '072_real_league.sql']) {
  await db.exec(migration(f));
}
const U3 = '33333333-3333-3333-3333-333333333333';
const U4 = '44444444-4444-4444-4444-444444444444';
const U5 = '55555555-5555-5555-5555-555555555555';
const U6 = '66666666-6666-6666-6666-666666666666';
const users = [U1, U2, U3, U4, U5, U6];
for (const u of users) await db.exec(`insert into auth.users values ('${u}', '{}')`);
await db.query(`update profiles set display_name = 'Juan García Pérez' where id = $1`, [U1]);
await db.query(`update profiles set display_name = 'Ana' where id = $1`, [U2]);
await db.query(`update profiles set display_name = null where id = $1`, [U3]);
ok('072 se aplica dos veces sin error');

const monday = (await one(
  `select date_trunc('week', now() at time zone 'America/Bogota')::date::text d`)).d;
const log = (uid, xp) => db.query(
  `insert into quest_log_entries (user_id, source_type, source_id, result, xp_awarded, occurred_at)
   values ($1, 'task', gen_random_uuid(), 'completed', $2, $3::date - 5 + interval '17 hours')`,
  [uid, xp, monday]);
const overview = (uid) => asUser(uid, () => one(`select challenges_overview() r`)).then((x) => x.r);
const coins = (uid) => one(`select coins from character_stats where user_id = $1`, [uid])
  .then((x) => x?.coins ?? 0);
const passes = (uid) => one(`select count(*)::int n from recovery_passes where user_id = $1`, [uid])
  .then((x) => x.n);

// Semana pasada, división 0: 5 personas con 500, 300, 200, 100 y 0 XP.
for (const u of [U1, U2, U3, U4, U5]) {
  await db.query(`insert into league_weeks (user_id, week_start, division) values ($1, $2::date - 7, 0)`,
    [u, monday]);
}
for (const [u, xp] of [[U1, 500], [U2, 300], [U3, 200], [U4, 100]]) await log(u, xp);
const before = Object.fromEntries(await Promise.all(users.map(async (u) => [u, await coins(u)])));

let o = await overview(U1);
assert.equal(o.league.division, 1);
assert.equal(o.league.last_result, 'promoted');
assert.equal(o.league.last_rank, 1);
assert.deepEqual(o.league.prizes, [50, 35, 20]);
assert.equal(await coins(U1) - before[U1], 50);
assert.equal(await passes(U1), 1);
assert.equal((await overview(U2)).league.last_rank, 2);
assert.equal(await coins(U2) - before[U2], 35);
assert.equal(await passes(U2), 0);
assert.equal((await overview(U3)).league.last_rank, 3);
assert.equal(await coins(U3) - before[U3], 20);
o = await overview(U4);
assert.equal(o.league.last_result, 'stayed');
assert.equal(o.league.division, 0);
assert.equal(await coins(U4) - before[U4], 0);
ok('072: el top 3 sube y cobra 50 + Pase / 35 / 20; el 4.º no');

await overview(U1);
assert.equal(await coins(U1) - before[U1], 50);
assert.equal(await passes(U1), 1);
const prize = await one(
  `select count(*)::int n from notifications where user_id = $1 and event_key like 'league:prize:%'`, [U1]);
assert.equal(prize.n, 1);
ok('072: el premio se paga y se avisa una sola vez');

// Esta semana: U1, U2 y U3 están en la división 1. Se ven entre ellos, nunca a sí mismos.
o = await overview(U1);
assert.deepEqual(o.league.rivals.map((r) => r.name).sort(), ['Ana', 'Aventurero']);
assert.ok(o.league.rivals.every((r) => Object.keys(r).sort().join() === 'name,xp'));
const seenByAna = (await overview(U2)).league.rivals.map((r) => r.name);
assert.ok(seenByAna.includes('Juan G.'));
assert.ok(!JSON.stringify(seenByAna).includes('García'));
// U5 aún no entra esta semana: no aparece; al abrir la app, sí.
assert.equal((await overview(U4)).league.rivals.length, 0);
await overview(U5);
assert.equal((await overview(U4)).league.rivals.length, 1);
ok('072: solo personas reales del grupo, con nombre e inicial, sin ids');

// Sola en una división con XP: ni sube ni cobra. Sin XP en división alta: baja.
await db.query(`delete from league_weeks where user_id in ($1, $2)`, [U5, U6]);
await db.query(`insert into league_weeks (user_id, week_start, division) values
  ($1, $3::date - 7, 4), ($2, $3::date - 7, 6)`, [U5, U6, monday]);
await log(U5, 900);
o = await overview(U5);
assert.equal(o.league.division, 4);
assert.equal(o.league.last_result, 'stayed');
assert.equal(await coins(U5) - before[U5], 0);
o = await overview(U6);
assert.equal(o.league.division, 5);
assert.equal(o.league.last_result, 'demoted');
ok('072: sin rivales con XP no hay ascenso ni premio; 0 XP baja');

// La racha diaria no cuenta el premio.
const src = await one(`select count(*)::int n from quest_log_entries where source_type = 'league'`);
assert.equal(src.n, 3);
ok('072: los premios quedan en la Bitácora con fuente league');
