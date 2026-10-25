// Prueba la migración 009 (Perfil: Tesoro y títulos) sobre 001–008:
// profile_overview ampliada y set_active_title.
// Uso: cd supabase/tests && node 009_profile_titles.test.mjs
import assert from 'node:assert/strict';

import { U1, U2, createFullDb, migration, ok, rejects } from './bootstrap.mjs';

const { db, one, asUser } = await createFullDb();
for (const f of ['003_security.sql', '004_structure.sql', '005_rewards.sql', '006_store.sql',
  '007_daily.sql', '008_fix_exploits.sql']) {
  await db.exec(migration(f));
}
await db.exec(migration('009_profile_titles.sql'));
await db.exec(migration('009_profile_titles.sql')); // idempotente
await db.exec(`insert into auth.users values ('${U1}', '{"username":"Ana"}'), ('${U2}', '{}')`);
ok('009 se aplica dos veces sin error');

const overview = (uid) => asUser(uid, () => one(`select profile_overview() r`)).then((x) => x.r);
const newTitle = (code, name, description = null) =>
  one(`insert into titles (code, name, description) values ($1, $2, $3) returning id`, [code, name, description])
    .then((x) => x.id);
const earn = (uid, titleId, ago) =>
  db.query(`insert into user_titles (user_id, title_id, earned_at) values ($1, $2, now() - $3::interval)`,
    [uid, titleId, ago]);

// US2 · Tesoro y títulos en profile_overview -------------------------------------
let r = await overview(U1);
assert.equal(r.treasury, 0);
assert.equal(r.active_title, null);
assert.deepEqual(r.titles, []);
assert.equal(r.display_name, 'Ana');
assert.ok(Array.isArray(r.skills));

await db.exec(`update character_stats set treasury = 12500 where user_id = '${U1}'`);
const guardian = await newTitle('guardian', 'Guardián del Huerto', 'Cuidaste tus hábitos 30 días.');
const explorer = await newTitle('explorador', 'Explorador');
await earn(U1, explorer, '1 day');
await earn(U1, guardian, '2 days');
await db.query(`update profiles set active_title_id = $1 where id = $2`, [guardian, U1]);
r = await overview(U1);
assert.equal(r.treasury, 12500);
assert.deepEqual(r.active_title, { id: guardian, name: 'Guardián del Huerto', description: 'Cuidaste tus hábitos 30 días.' });
assert.deepEqual(r.titles.map((t) => [t.id, t.name, t.description]),
  [[guardian, 'Guardián del Huerto', 'Cuidaste tus hábitos 30 días.'], [explorer, 'Explorador', null]]);
assert.ok(r.titles.every((t) => typeof t.earned_at === 'string'));

r = await overview(U2);
assert.deepEqual([r.treasury, r.active_title, r.titles], [0, null, []]);
await db.query(`delete from titles where id = $1`, [guardian]);
r = await overview(U1);
assert.equal(r.active_title, null);
assert.deepEqual(r.titles.map((t) => t.id), [explorer]);
ok('009: profile_overview trae Tesoro y títulos, aislados por jugador');

// US3 · set_active_title -------------------------------------------------------------
const foreign = await newTitle('ajeno', 'Ajeno');
await earn(U2, foreign, '1 hour');
await asUser(U1, async () => {
  await db.query(`select set_active_title($1)`, [explorer]);
  assert.equal((await one(`select profile_overview() r`)).r.active_title.id, explorer);
  await db.query(`select set_active_title(null)`);
  assert.equal((await one(`select profile_overview() r`)).r.active_title, null);
  await db.query(`select set_active_title($1)`, [explorer]);
  await rejects(db.query(`select set_active_title($1)`, [foreign]), /title_not_earned/);
  await rejects(db.query(`select set_active_title(gen_random_uuid())`), /title_not_earned/);
  await rejects(db.query(`update profiles set active_title_id = $1 where id = $2`, [foreign, U1]), /title_not_earned/);
  assert.equal((await one(`select profile_overview() r`)).r.active_title.id, explorer);
});
await db.exec('set role anon');
try {
  await rejects(db.query(`select set_active_title(null)`), /permission denied/);
} finally {
  await db.exec('reset role');
}
ok('009: set_active_title solo activa títulos ganados');

console.log('\nTodo en orden.');
