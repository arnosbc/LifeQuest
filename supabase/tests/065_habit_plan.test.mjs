// Prueba la migración 065 (plan de hábito de Nevi).
// Uso: cd supabase/tests && node 065_habit_plan.test.mjs
import assert from 'node:assert/strict';

import { U1, U2, createFullDb, migration, ok, rejects } from './bootstrap.mjs';

const { db, one, asUser } = await createFullDb();
for (const f of ['003_security.sql', '004_structure.sql', '005_rewards.sql', '006_store.sql',
  '007_daily.sql', '008_fix_exploits.sql', '009_profile_titles.sql', '010_missions.sql',
  '011_habits.sql', '065_habit_plan.sql', '065_habit_plan.sql']) {
  await db.exec(migration(f));
}
await db.exec(`insert into auth.users values ('${U1}', '{}'), ('${U2}', '{}')`);
ok('065 se aplica dos veces sin error');

const habit = (await one(
  `insert into habits (user_id, name, type) values ($1, 'Leer', 'good') returning id`, [U1])).id;
const attach = (uid, plan) => asUser(uid, () =>
  one(`select attach_habit_plan($1, $2::jsonb) r`, [habit, JSON.stringify(plan)])).then((x) => x.r);

const plan = await attach(U1, {
  tiny: '  Leer una página  ',
  cue: 'Después de cenar, abro el libro',
  reward: 'Marco el día en la app',
  why: 'x'.repeat(400),
  extra: 'se ignora',
});
assert.equal(plan.tiny, 'Leer una página');
assert.equal(plan.why.length, 300);
assert.equal(plan.extra, undefined);
const stored = await asUser(U1, () => one(`select plan from habits where id = $1`, [habit]));
assert.deepEqual(stored.plan, plan);
ok('065: guarda el plan recortado y la app lo lee de habits');

await rejects(attach(U1, { cue: 'sin versión mínima' }), /invalid_plan/);
ok('065: sin versión mínima no hay plan');

await rejects(attach(U2, { tiny: 'intruso' }), /habit_not_found/);
const seen = await asUser(U2, () => db.query(`select plan from habits where id = $1`, [habit]));
assert.equal(seen.rows.length, 0);
ok('065: nadie más escribe ni ve el plan de un hábito ajeno');
