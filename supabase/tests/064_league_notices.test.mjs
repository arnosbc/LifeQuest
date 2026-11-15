// Prueba la migración 064 (avisos de Liga de Nevi).
// Uso: cd supabase/tests && node 064_league_notices.test.mjs
import assert from 'node:assert/strict';

import { U1, U2, createFullDb, migration, ok } from './bootstrap.mjs';

const { db, one } = await createFullDb();
for (const f of ['003_security.sql', '004_structure.sql', '005_rewards.sql', '006_store.sql',
  '007_daily.sql', '008_fix_exploits.sql', '009_profile_titles.sql', '010_missions.sql',
  '011_habits.sql', '012_dungeon.sql', '029_notifications.sql', '052_challenges_league.sql',
  '064_league_notices.sql', '064_league_notices.sql']) {
  await db.exec(migration(f));
}
await db.exec(`insert into auth.users values ('${U1}', '{}'), ('${U2}', '{}')`);
ok('064 se aplica dos veces sin error');

const monday = (await one(
  `select date_trunc('week', now() at time zone 'America/Bogota')::date::text d`)).d;
const wednesday = (await one(`select ($1::date + 2)::text d`, [monday])).d;
const log = (uid, xp, when) => db.query(
  `insert into quest_log_entries (user_id, source_type, source_id, result, xp_awarded, occurred_at)
   values ($1, 'task', gen_random_uuid(), 'completed', $2, ${when})`, [uid, xp]);
const notices = (uid) => db.query(
  `select title from notifications where user_id = $1 and category = 'league' order by created_at`,
  [uid]).then((r) => r.rows.map((x) => x.title));

// U1 jugó la semana pasada en la división 0 con mucha XP: sube.
await db.query(`insert into league_weeks (user_id, week_start, division) values ($1, $2::date - 7, 0)`,
  [U1, monday]);
await log(U1, 1000, `'${monday}'::date - 5 + interval '17 hours'`);
// U2 estaba en la división 3 y no ganó XP: baja (tiene actividad sin XP esta semana).
await db.query(`insert into league_weeks (user_id, week_start, division) values ($1, $2::date - 7, 3)`,
  [U2, monday]);
await log(U2, 0, 'now()');

await one(`select _league_notices($1::date) n`, [monday]);
assert.deepEqual(await notices(U1), ['Nevi: ¡subiste de división! 🏆']);
assert.deepEqual(await notices(U2), ['Nevi: nueva semana, nueva oportunidad 🌱']);
ok('064: al empezar la semana, Nevi cuenta si subiste o bajaste (con ánimo)');

await one(`select _league_notices($1::date) n`, [monday]);
assert.equal((await notices(U1)).length, 1);
ok('064: el resultado de la semana se avisa una sola vez');

await log(U1, 900, 'now()');
await one(`select _league_notices($1::date) n`, [wednesday]);
assert.deepEqual((await notices(U1))[1], 'Nevi: ¡vas #1 en la Liga! 🏆');
assert.equal((await notices(U2)).length, 1);
await one(`select _league_notices($1::date) n`, [wednesday]);
assert.equal((await notices(U1)).length, 2);
ok('064: desde el miércoles avisa una vez la zona de ascenso; sin XP no hay aviso');
