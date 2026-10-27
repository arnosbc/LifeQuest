// Prueba la migración 015 (Onboarding) sobre 001–014: marca onboarded_at,
// onboarding_overview y complete_onboarding.
// Uso: cd supabase/tests && node 015_onboarding.test.mjs
import assert from 'node:assert/strict';

import { U1, U2, createFullDb, migration, ok, rejects } from './bootstrap.mjs';

const { db, one, asUser } = await createFullDb();
for (const f of ['003_security.sql', '004_structure.sql', '005_rewards.sql', '006_store.sql',
  '007_daily.sql', '008_fix_exploits.sql', '009_profile_titles.sql', '010_missions.sql',
  '011_habits.sql', '012_dungeon.sql', '013_stage.sql', '014_goals.sql']) {
  await db.exec(migration(f));
}
await db.exec(migration('015_onboarding.sql'));
await db.exec(migration('015_onboarding.sql')); // idempotente
await db.exec(`insert into auth.users values ('${U1}', '{"username":"Ana"}'), ('${U2}', '{}')`);
ok('015 se aplica dos veces sin error');

const call = (uid, sql, params) => asUser(uid, () => one(sql, params));
const overview = (uid) => call(uid, `select onboarding_overview() r`).then((x) => x.r);
const complete = (uid, identity, skill, difficulty) =>
  call(uid, `select complete_onboarding($1, $2, $3::difficulty_level)`, [identity, skill, difficulty]);
const state = (uid) => one(`select p.identity_statement, p.onboarded_at is not null done, g.difficulty,
  (select coalesce(array_agg(name order by name), '{}') from skills where user_id = p.id) skills
  from profiles p join game_master_settings g on g.user_id = p.id where p.id = $1`, [uid]);

// Overview: pendiente y multiplicadores vigentes ---------------------------------------
let r = await overview(U1);
assert.equal(r.pending, true);
assert.deepEqual(r.difficulties.map((d) => [d.level, d.xp_multiplier, d.hp_penalty_multiplier, d.coin_multiplier]),
  [['easy', 1.2, 0.75, 1], ['normal', 1, 1, 1], ['hard', 0.85, 1.25, 1]]);
ok('015: onboarding_overview pendiente con los multiplicadores de difficulty_levels');

// Errores deshacen todo -----------------------------------------------------------------
await rejects(complete(U1, 'x'.repeat(281), null, 'hard'), /profiles_identity_length/);
await rejects(complete(U1, 'Ana', 'y'.repeat(41), 'hard'), /skills_name_length/);
assert.deepEqual(await state(U1), { identity_statement: null, done: false, difficulty: 'normal', skills: [] });
ok('015: identidad > 280 o skill > 40 no guarda nada');

// US1 · Completar ------------------------------------------------------------------------
await complete(U1, '  Guardiana del huerto  ', '  Salud física ', 'hard');
assert.deepEqual(await state(U1),
  { identity_statement: 'Guardiana del huerto', done: true, difficulty: 'hard', skills: ['Salud física'] });
assert.equal((await overview(U1)).pending, false);
assert.equal((await one(`select count(*)::int n from quest_log_entries where user_id = $1`, [U1])).n, 0);
assert.equal((await one(`select current_xp + coins n from character_stats where user_id = $1`, [U1])).n, 0);
await rejects(complete(U1, 'Otra', null, 'easy'), /onboarding_done/);
assert.equal((await state(U1)).difficulty, 'hard');
ok('015: completar guarda identidad, skill y dificultad una sola vez y sin recompensas');

// US2 · Saltar con todo vacío ----------------------------------------------------------
assert.equal((await overview(U2)).pending, true);
await complete(U2, '   ', '', null);
assert.deepEqual(await state(U2), { identity_statement: null, done: true, difficulty: 'normal', skills: [] });
assert.equal((await overview(U2)).pending, false);
ok('015: saltar sin datos deja Normal y marca el Onboarding como visto');

// Marca fija ---------------------------------------------------------------------------------
await asUser(U2, async () => {
  await rejects(db.query(`update profiles set onboarded_at = null where id = $1`, [U2]), /onboarding_locked/);
  await rejects(db.query(`update profiles set onboarded_at = now() - interval '1 day' where id = $1`, [U2]),
    /onboarding_locked/);
});
const U3 = '33333333-3333-3333-3333-333333333333';
await db.exec(`insert into auth.users values ('${U3}', '{}')`);
await asUser(U3, () => db.query(`update profiles set onboarded_at = '2000-01-01' where id = $1`, [U3]));
assert.ok((await one(`select onboarded_at > now() - interval '1 minute' fresh from profiles where id = $1`, [U3])).fresh);
ok('015: la marca solo se pone con la fecha actual y no se cambia ni se borra');

// FR-008 · jugadores anteriores ------------------------------------------------------------
const U4 = '44444444-4444-4444-4444-444444444444';
const U5 = '55555555-5555-5555-5555-555555555555';
await db.exec(`insert into auth.users values ('${U4}', '{}'), ('${U5}', '{}')`);
await db.query(`update profiles set identity_statement = 'Viajera' where id = $1`, [U4]);
await db.query(`insert into skills (user_id, name) values ($1, 'Estudio')`, [U5]);
assert.equal((await overview(U4)).pending, false);
assert.equal((await overview(U5)).pending, false);
await rejects(complete(U5, null, ' estudio ', null), /skill_exists/);
ok('015: quien ya tiene identidad o skill no está pendiente; no se duplica la skill');

// Aislamiento y permisos --------------------------------------------------------------------
await asUser(U2, () => db.query(`update profiles set onboarded_at = now() where id = $1`, [U1]));
assert.equal((await state(U1)).identity_statement, 'Guardiana del huerto');
await db.exec('set role anon');
await rejects(db.query('select complete_onboarding(null, null, null)'), /permission denied/);
await db.exec(`reset role`);
ok('015: un jugador no toca el perfil de otro y anon no puede llamar la RPC');
