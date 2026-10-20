// Prueba supabase/migrations/001_home.sql (Home: alta del personaje, rachas,
// anti-trampa, complete_habit y home_dashboard).
// Uso: cd supabase/tests && npm install && npm test
import assert from 'node:assert/strict';

import { U0, U1, U2, createDb, migration, ok, rejects } from './bootstrap.mjs';

const { db, one, asUser } = await createDb();
const sql001 = migration('001_home.sql');
// Usuario registrado ANTES de la migración: debe recibir perfil por backfill.
await db.exec(`insert into auth.users values ('${U0}', '{"username":"Previo"}')`);
await db.exec(sql001);
await db.exec(sql001); // idempotente
await db.exec(`insert into auth.users values ('${U1}', '{"username":"  Ana "}'), ('${U2}', '{}')`);

const today = (await one('select current_date::text d')).d;

// 3. Alta del personaje y backfill
assert.equal((await one(`select display_name from profiles where id = $1`, [U1])).display_name, 'Ana');
assert.equal((await one(`select display_name from profiles where id = $1`, [U2])).display_name, null);
assert.equal((await one(`select count(*)::int n from character_stats`)).n, 3);
assert.equal((await one(`select count(*)::int n from game_master_settings`)).n, 3);
assert.equal((await one(`select display_name from profiles where id = $1`, [U0])).display_name, 'Previo');
ok('trigger de alta + backfill + idempotencia');

// 2. is_weakened generado
await db.exec(`update character_stats set hp_current = 20 where user_id = '${U2}'`);
assert.equal((await one(`select is_weakened from character_stats where user_id = $1`, [U2])).is_weakened, true);
await db.exec(`update character_stats set hp_current = 21 where user_id = '${U2}'`);
assert.equal((await one(`select is_weakened from character_stats where user_id = $1`, [U2])).is_weakened, false);
ok('is_weakened ≤ 20 %');

// Datos de U1
const h = (await one(`insert into habits (user_id, name, type, xp_reward, coin_reward)
  values ($1, 'Leer', 'good', 10, 5) returning id`, [U1])).id;
const h2 = (await one(`insert into habits (user_id, name, type, xp_reward, coin_reward)
  values ($1, 'Agua', 'good', 10, 5) returning id`, [U1])).id;
const bad = (await one(`insert into habits (user_id, name, type) values ($1, 'Azúcar', 'bad') returning id`, [U1])).id;
const dow = (await one(`select extract(dow from current_date)::int d`)).d;
const weekly = (await one(`insert into habits (user_id, name, type, frequency, specific_days, xp_reward)
  values ($1, 'Correr', 'good', 'specific_days', $2, 10) returning id`, [U1, `{${dow}}`])).id;
const notToday = (await one(`insert into habits (user_id, name, type, frequency, specific_days)
  values ($1, 'Yoga', 'good', 'specific_days', $2) returning id`, [U1, `{${(dow + 1) % 7}}`])).id;
const h3 = (await one(`insert into habits (user_id, name, type) values ($1, 'Ajeno', 'good') returning id`, [U2])).id;

// 4. Anti-trampa
await asUser(U1, async () => {
  await db.exec(`update character_stats set coins = 999`);
  assert.equal((await one(`select coins from character_stats`)).coins, 0);
  await rejects(db.exec(`insert into quest_log_entries (user_id, source_type, source_id, result, xp_awarded)
    values ('${U1}', 'habit', '${h}', 'completed', 9999)`), /row-level security/);
  await rejects(db.exec(`insert into habit_records (habit_id, user_id, completed_on)
    values ('${h}', '${U1}', current_date - 1)`), /row-level security/);
  await rejects(db.exec(`update habits set current_streak = 500`), /permission denied/);
  await db.exec(`update habits set name = 'Leer 20 min' where id = '${h}'`);
  assert.equal((await one(`select count(*)::int n from character_stats`)).n, 1);
});
ok('cliente: solo lectura en stats/log/registros y sin tocar rachas; sí edita el hábito');

// 5. complete_habit
await asUser(U1, async () => {
  await db.query(`select complete_habit($1, current_date)`, [h]);
  let s = await one(`select current_xp, coins, level from character_stats`);
  assert.deepEqual(s, { current_xp: 10, coins: 5, level: 1 });
  assert.equal((await one(`select current_streak s from habits where id = $1`, [h])).s, 1);
  assert.equal((await one(`select count(*)::int n from quest_log_entries where source_id = $1`, [h])).n, 1);
  await rejects(db.query(`select complete_habit($1, current_date)`, [h]), /already_completed/);
  await rejects(db.query(`select complete_habit($1, current_date)`, [bad]), /not_a_good_habit/);
  await rejects(db.query(`select complete_habit($1, current_date)`, [h3]), /habit_not_found/);
  await rejects(db.query(`select complete_habit($1, current_date - 3)`, [h2]), /invalid_day/);
  await rejects(db.query(`select complete_habit($1, current_date)`, [notToday]), /not_scheduled/);

  // Racha consecutiva: ayer y hoy.
  await db.query(`select complete_habit($1, current_date - 1)`, [h2]);
  await db.query(`select complete_habit($1, current_date)`, [h2]);
  const r = await one(`select current_streak, best_streak from habits where id = $1`, [h2]);
  assert.deepEqual(r, { current_streak: 2, best_streak: 2 });
  s = await one(`select current_xp, coins from character_stats`);
  assert.deepEqual(s, { current_xp: 30, coins: 15 });
});
ok('complete_habit: recompensa, log, racha y validaciones');

// Racha semanal: el día programado anterior es hace 7 días.
await db.exec(`insert into habit_records (habit_id, user_id, completed_on) values ('${weekly}', '${U1}', current_date - 7);
               update habits set current_streak = 4, best_streak = 6 where id = '${weekly}'`);
await asUser(U1, () => db.query(`select complete_habit($1, current_date)`, [weekly]));
assert.deepEqual(await one(`select current_streak, best_streak from habits where id = $1`, [weekly]),
  { current_streak: 5, best_streak: 6 });
ok('racha de días específicos');

// Subida de nivel, dificultad y debilitado
await db.exec(`update character_stats set current_xp = 95, coins = 0 where user_id = '${U1}';
               delete from habit_records where habit_id = '${h}';
               update game_master_settings set difficulty = 'easy' where user_id = '${U1}'`);
await asUser(U1, () => db.query(`select complete_habit($1, current_date)`, [h]));
assert.deepEqual(await one(`select level, current_xp, coins from character_stats where user_id = $1`, [U1]),
  { level: 2, current_xp: 7, coins: 6 }); // 10 × 1.2 = 12 XP, 5 × 1.2 = 6 monedas
await db.exec(`update character_stats set current_xp = 0, coins = 0, hp_current = 10 where user_id = '${U1}';
               delete from habit_records where habit_id = '${h}';
               update game_master_settings set difficulty = 'normal' where user_id = '${U1}'`);
await asUser(U1, () => db.query(`select complete_habit($1, current_date)`, [h]));
assert.deepEqual(await one(`select current_xp, coins from character_stats where user_id = $1`, [U1]),
  { current_xp: 9, coins: 4 }); // −10 % debilitado
await db.exec(`update character_stats set hp_current = 100 where user_id = '${U1}'`);
ok('nivel, multiplicador de dificultad y −10 % debilitado');

// 6. home_dashboard y prioridad RF-097
await db.exec(`
  insert into tasks (user_id, title, priority, due_date) values
    ('${U1}', 'Baja lejana', 'low', now() + interval '5 days'),
    ('${U1}', 'Alta sin fecha', 'high', null),
    ('${U1}', 'Media urgente', 'medium', current_date + interval '23 hours 59 minutes'),
    ('${U1}', 'Alta cercana', 'high', now() + interval '2 days');
  insert into tasks (user_id, title, status, completed_at) values ('${U1}', 'Hecha', 'completed', now());
  insert into tasks (user_id, title, status) values ('${U2}', 'De otro', 'pending');
  insert into focus_sessions (user_id, total_minutes, cycle_minutes, started_at, ended_at)
    values ('${U1}', 60, 25, current_date + interval '1 hour', current_date + interval '1 hour 45 minutes'),
           ('${U1}', 30, 25, current_date + interval '2 hours', current_date + interval '4 hours');`);
const dash = async (uid) => (await asUser(uid, () =>
  one(`select home_dashboard(current_date, 0) d`))).d;
let d = await dash(U1);
assert.equal(d.display_name, 'Ana');
assert.equal(d.priority_mission.title, 'Media urgente');
assert.equal(d.habits_total, 3); // Leer, Agua, Correr hoy; Yoga no; malo no
assert.equal(d.habits.length, 3);
assert.equal(d.habits_done, 3);
assert.equal(d.streak_days, 5);
assert.equal(d.missions_done, 1);
assert.equal(d.missions_total, 2); // hecha hoy + la urgente que vence hoy (si no cruza medianoche)
assert.equal(d.focus_minutes, 75); // 45 + min(30, 120)
await db.exec(`update tasks set status = 'completed' where title = 'Media urgente'`);
assert.equal((await dash(U1)).priority_mission.title, 'Alta cercana');
await db.exec(`update tasks set status = 'completed' where title = 'Alta cercana'`);
assert.equal((await dash(U1)).priority_mission.title, 'Alta sin fecha');
d = await dash(U2);
assert.equal(d.priority_mission.title, 'De otro');
assert.equal(d.habits_total, 1);
assert.deepEqual(d.habits.map((x) => x.name), ['Ajeno']);
await db.exec('set role anon'); await rejects(db.query('select home_dashboard(current_date, 0)'), /permission denied/);
await db.exec('reset role');
ok('home_dashboard: datos, prioridad RF-097 y aislamiento entre usuarios');

console.log(`\nTodo en orden (hoy = ${today}).`);
