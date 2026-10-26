// Prueba la migración 011 (Hábitos) sobre 001–010: habits_overview y
// create_habit, más complete_habit y register_bad_habit de 005.
// Uso: cd supabase/tests && node 011_habits.test.mjs
import assert from 'node:assert/strict';

import { U1, U2, createFullDb, migration, ok, rejects } from './bootstrap.mjs';

const { db, one, asUser } = await createFullDb();
for (const f of ['003_security.sql', '004_structure.sql', '005_rewards.sql', '006_store.sql',
  '007_daily.sql', '008_fix_exploits.sql', '009_profile_titles.sql', '010_missions.sql']) {
  await db.exec(migration(f));
}
await db.exec(migration('011_habits.sql'));
await db.exec(migration('011_habits.sql')); // idempotente
await db.exec(`insert into auth.users values ('${U1}', '{"username":"Ana"}'), ('${U2}', '{}')`);
ok('011 se aplica dos veces sin error');

const today = (await one(`select current_date::text d`)).d;
const dow = (await one(`select extract(dow from current_date)::int d`)).d;
const overview = (uid) => asUser(uid, () => one(`select habits_overview($1::date) r`, [today])).then((x) => x.r);
const create = (uid, a) => asUser(uid, () => one(
  `select create_habit(p_name => $1, p_type => $2, p_frequency => $3, p_specific_days => $4,
     p_hp_penalty => $5, p_skill_id => $6) id`,
  [a.name, a.type, a.frequency ?? 'daily', a.days ?? null, a.hp ?? 0, a.skill ?? null])).then((x) => x.id);

const skill = (await one(`insert into skills (user_id, name) values ($1, 'Salud') returning id`, [U1])).id;
const foreignSkill = (await one(`insert into skills (user_id, name) values ($1, 'Ajena') returning id`, [U2])).id;

// Vacío ---------------------------------------------------------------------------
let r = await overview(U1);
assert.deepEqual([r.habits, r.week_xp, r.week_done, r.week_scheduled, r.bad_free_days, r.month_days],
  [[], 0, 0, 0, 7, []]);
assert.deepEqual(r.skills.map((s) => s.name), ['Salud']);
ok('011: overview vacío');

// Crear -----------------------------------------------------------------------------
const read = await create(U1, { name: '  Leer  ', type: 'good', skill, hp: 8 });
const gym = await create(U1, { name: 'Gimnasio', type: 'good', frequency: 'specific_days',
  days: [(dow + 1) % 7, (dow + 1) % 7] });
const phone = await create(U1, { name: 'Pantallas de noche', type: 'bad', hp: 5, frequency: 'specific_days', days: [1] });
const row = (id) => one(`select name, frequency, specific_days, hp_penalty from habits where id = $1`, [id]);
assert.deepEqual(await row(read), { name: 'Leer', frequency: 'daily', specific_days: null, hp_penalty: 0 });
assert.deepEqual((await row(gym)).specific_days, [(dow + 1) % 7]);
assert.deepEqual(await row(phone), { name: 'Pantallas de noche', frequency: 'daily', specific_days: null, hp_penalty: 5 });

await rejects(create(U1, { name: ' ', type: 'good' }), /invalid_name/);
await rejects(create(U1, { name: 'x', type: 'bad', hp: 4 }), /invalid_severity/);
await rejects(create(U1, { name: 'x', type: 'good', frequency: 'specific_days', days: [] }), /invalid_days/);
await rejects(create(U1, { name: 'x', type: 'good', frequency: 'specific_days', days: [7] }), /invalid_days/);
await rejects(create(U1, { name: 'x', type: 'good', skill: foreignSkill }), /skill_not_found/);
ok('011: create_habit normaliza y valida nombre, gravedad, días y skill');

// Registrar y leer --------------------------------------------------------------------
await asUser(U1, async () => {
  await db.query(`select complete_habit($1, $2::date)`, [read, today]);
  await db.query(`select register_bad_habit($1)`, [phone]);
  await db.query(`select register_bad_habit($1)`, [phone]);
});
r = await overview(U1);
const by = Object.fromEntries(r.habits.map((h) => [h.name, h]));
assert.deepEqual(r.habits.map((h) => h.type), ['good', 'good', 'bad']);
assert.deepEqual([by.Leer.scheduled_today, by.Leer.done_today, by.Leer.current_streak, by.Leer.skill_name],
  [true, true, 1, 'Salud']);
assert.deepEqual(by.Leer.week, [false, false, false, false, false, false, true]);
assert.equal(by.Gimnasio.scheduled_today, false);
assert.deepEqual([by['Pantallas de noche'].today_count, by['Pantallas de noche'].hp_penalty], [2, 5]);
assert.equal(r.week_xp, 10);
assert.deepEqual([r.week_done, r.week_scheduled], [1, 1]); // hábitos creados hoy: solo cuenta hoy
assert.equal(r.bad_free_days, 6);
assert.deepEqual(r.month_days, [Number(today.slice(8))]);
ok('011: overview refleja hoy, la semana, el resumen y el mapa de calor');

// Aislamiento -------------------------------------------------------------------------
r = await overview(U2);
assert.deepEqual([r.habits, r.week_xp, r.month_days], [[], 0, []]);
await rejects(asUser(U2, () => db.query(`select register_bad_habit($1)`, [phone])), /habit_not_found/);
ok('011: cada jugador solo ve y registra sus hábitos');
