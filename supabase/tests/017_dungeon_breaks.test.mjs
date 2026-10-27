// Prueba la migración 017 (descansos de la Mazmorra) sobre 001–016.
// Uso: cd supabase/tests && node 017_dungeon_breaks.test.mjs
import assert from 'node:assert/strict';

import { U1, U2, createFullDb, migration, ok } from './bootstrap.mjs';

const { db, one, asUser } = await createFullDb();
for (const f of ['003_security.sql', '004_structure.sql', '005_rewards.sql', '006_store.sql',
  '007_daily.sql', '008_fix_exploits.sql', '009_profile_titles.sql', '010_missions.sql',
  '011_habits.sql', '012_dungeon.sql', '013_stage.sql', '014_goals.sql', '015_onboarding.sql',
  '016_settings.sql']) {
  await db.exec(migration(f));
}
await db.exec(migration('017_dungeon_breaks.sql'));
await db.exec(migration('017_dungeon_breaks.sql')); // idempotente
await db.exec(`insert into auth.users values ('${U1}', '{}'), ('${U2}', '{}')`);
ok('017 se aplica dos veces sin error');

const overview = (uid) => asUser(uid, () => one(`select dungeon_overview() r`)).then((x) => x.r);

let r = await overview(U1);
assert.deepEqual(r.breaks, { short_minutes: 5, long_minutes: 15, long_every_n_cycles: 4 });
assert.equal(r.session, null);
assert.ok(Array.isArray(r.candidates));
assert.equal(typeof r.max_tasks, 'number');

await asUser(U1, () => db.query(`update game_master_settings set short_break_minutes = 10,
  long_break_minutes = 30, long_break_every_n_cycles = 3 where user_id = $1`, [U1]));
r = await overview(U1);
assert.deepEqual(r.breaks, { short_minutes: 10, long_minutes: 30, long_every_n_cycles: 3 });
assert.deepEqual((await overview(U2)).breaks, { short_minutes: 5, long_minutes: 15, long_every_n_cycles: 4 });
ok('017: dungeon_overview trae los descansos de cada jugador');
