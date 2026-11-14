// Prueba la migración 051 (prioridad de hábitos) sobre 001–042.
// Uso: cd supabase/tests && node 051_habit_priority.test.mjs
import assert from 'node:assert/strict';

import { U1, U2, createFullDb, migration, ok, rejects } from './bootstrap.mjs';

const { db, one, asUser } = await createFullDb();
await db.exec(`create role service_role nologin`);
for (const f of ['003_security.sql', '004_structure.sql', '005_rewards.sql', '006_store.sql',
  '007_daily.sql', '008_fix_exploits.sql', '011_habits.sql', '028_edit_delete.sql',
  '042_habits_growth.sql', '051_habit_priority.sql', '051_habit_priority.sql']) {
  await db.exec(migration(f));
}
await db.exec(`insert into auth.users values ('${U1}', '{}'), ('${U2}', '{}')`);
ok('051 se aplica dos veces sin error');

const create = (uid, name, priority) => asUser(uid, () => one(
  `select create_habit($1, 'good', 'daily', null, 0, null${priority ? ", $2" : ''}) id`,
  priority ? [name, priority] : [name]));
await create(U1, 'Leer', 'high');
await create(U1, 'Agua');
await rejects(create(U1, 'Mal', 'urgente'), /invalid input value for enum/);
ok('051: create_habit guarda la prioridad (media por defecto) y rechaza otras');

const habits = await asUser(U1, () => one(`select habits_overview(current_date) r`)).then((x) => x.r.habits);
assert.deepEqual(Object.fromEntries(habits.map((h) => [h.name, h.priority])), { Leer: 'high', Agua: 'medium' });
assert.equal((await asUser(U2, () => one(`select habits_overview(current_date) r`))).r.habits.length, 0);
ok('051: habits_overview devuelve la prioridad y solo los hábitos propios');
