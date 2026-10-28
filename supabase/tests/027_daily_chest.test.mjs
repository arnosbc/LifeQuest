// Prueba la migración 027 (Cofre del día) sobre 001–026: daily_chest_status
// sigue la misma regla que claim_daily_chest (008).
// Uso: cd supabase/tests && node 027_daily_chest.test.mjs
import assert from 'node:assert/strict';

import { U1, U2, createFullDb, migration, ok, rejects } from './bootstrap.mjs';

const { db, one, asUser } = await createFullDb();
for (const f of ['003_security.sql', '004_structure.sql', '005_rewards.sql', '006_store.sql',
  '007_daily.sql', '008_fix_exploits.sql', '009_profile_titles.sql', '010_missions.sql',
  '011_habits.sql', '012_dungeon.sql', '013_stage.sql', '014_goals.sql', '015_onboarding.sql',
  '016_settings.sql', '017_dungeon_breaks.sql', '018_marketplace.sql', '019_tavern.sql',
  '020_journal.sql', '021_boss_fight.sql', '022_rpgenie.sql', '023_brain_dump.sql',
  '024_vision_board.sql', '025_stats.sql', '026_inventory.sql']) {
  await db.exec(migration(f));
}
await db.exec(migration('027_daily_chest.sql'));
await db.exec(migration('027_daily_chest.sql')); // idempotente
await db.exec(`insert into auth.users values ('${U1}', '{"username":"Ana"}'), ('${U2}', '{}')`);
ok('027 se aplica dos veces sin error');

const call = (uid, sql, params) => asUser(uid, () => one(sql, params)).then((x) => x && x.r);
const status = (uid) => call(uid, `select daily_chest_status() r`);

assert.deepEqual(await status(U1), { progress: 0, required: 3, coins: 15, claimed: false });

// Misiones "con trabajo real" (creadas hace más de 2 min) dan Monedas y cuentan.
for (const title of ['Una', 'Dos', 'Tres']) {
  const id = (await call(U1, `select create_task($1) r`, [title])).id;
  await db.query(`update tasks set created_at = now() - interval '1 hour' where id = $1`, [id]);
  await call(U1, `select complete_task($1) r`, [id]);
}
// Completada al instante: 0 Monedas, no cuenta.
const fast = (await call(U1, `select create_task('Rápida') r`)).id;
await call(U1, `select complete_task($1) r`, [fast]);

assert.deepEqual(await status(U1), { progress: 3, required: 3, coins: 15, claimed: false });
await rejects(call(U2, `select claim_daily_chest() r`), /chest_locked/);
await call(U1, `select claim_daily_chest() r`);
assert.equal((await status(U1)).claimed, true);
assert.deepEqual(await status(U2), { progress: 0, required: 3, coins: 15, claimed: false });
ok('027: daily_chest_status cuenta igual que claim_daily_chest y aísla jugadores');
