// Prueba las migraciones 003–007 sobre el esquema desplegado completo
// (tests/deployed_v1.sql + 001 + 002): seguridad, recompensas, economía,
// tienda, rachas de 48 h, Refugio, Taverna, Mazmorra, job diario y vistas.
// Uso: cd supabase/tests && npm install && npm test
import assert from 'node:assert/strict';

import { U1, U2, createFullDb, migration, ok, rejects } from './bootstrap.mjs';

const { db, one, asUser } = await createFullDb();
const files = ['003_security.sql', '004_structure.sql', '005_rewards.sql', '006_store.sql', '007_daily.sql'];
for (const f of files) {
  await db.exec(migration(f));
  await db.exec(migration(f)); // idempotente
}
await db.exec(`insert into auth.users values ('${U1}', '{"username":"Ana"}'), ('${U2}', '{}')`);
const U3 = '33333333-3333-3333-3333-333333333333';
await db.exec(`insert into auth.users values ('${U3}', '{}')`);
const call = (sql, p) => one(sql, p);
const stats = (u) => one(`select level, current_xp, xp_to_next_level, coins, treasury, hp_current, is_weakened
  from character_stats where user_id = $1`, [u]);
ok('003–007 se aplican dos veces sin error');

// 003 · Seguridad -----------------------------------------------------------------
const skill = (await one(`insert into skills (user_id, name) values ($1, 'Inglés') returning id`, [U1])).id;
await asUser(U1, async () => {
  await rejects(db.exec(`insert into tasks (user_id, title, xp_reward) values ('${U1}', 'x', 999)`), /permission denied/);
  await rejects(db.exec(`insert into tasks (user_id, title, status) values ('${U1}', 'x', 'completed')`), /status_server_only/);
  await rejects(db.exec(`insert into habits (user_id, name, type, coin_reward) values ('${U1}', 'x', 'good', 50)`), /permission denied/);
  await rejects(db.exec(`insert into purchases (user_id, market_item_id, coins_spent)
    select '${U1}', id, 0 from market_items limit 1`), /row-level security/);
  await rejects(db.exec(`insert into market_items (category, name, coin_cost) values ('mercado', 'Café', 1)`), /row-level security/);
  await rejects(db.exec(`insert into recovery_passes (user_id) values ('${U1}')`), /row-level security/);
  await rejects(db.exec(`insert into user_consumables (user_id, kind) values ('${U1}', 'elixir')`), /row-level security/);
  await rejects(db.exec(`update game_master_settings set skill_limit = 99`), /permission denied/);
  const g = (await one(`insert into goals (user_id, title) values ($1, 'Meta') returning id`, [U1])).id;
  await rejects(db.exec(`update goals set boss_current_hp = 0 where id = '${g}'`), /permission denied/);
  await rejects(db.exec(`update goals set status = 'completed' where id = '${g}'`), /status_server_only/);
  await rejects(db.exec(`update focus_sessions set started_at = now() - interval '1 day'`), /permission denied/);
  await db.exec(`update game_master_settings set difficulty = 'normal'`);
  assert.equal((await one(`select count(*)::int n from market_items`)).n, 5);
});
ok('003: el cliente no escribe recompensas, compras, pases, catálogo, vida del jefe ni estados finales');

// 004 · Estructura ----------------------------------------------------------------
for (const t of ['hero_journal_entries', 'hp_recovery_purchases']) {
  assert.equal((await one(`select to_regclass('public.${t}') r`)).r, null);
}
for (const c of ['estimated_minutes', 'difficulty', 'category']) {
  assert.equal((await one(`select count(*)::int n from information_schema.columns
    where table_name = 'tasks' and column_name = $1`, [c])).n, 0);
}
assert.deepEqual((await one(`select enum_range(null::market_category)::text r`)).r, '{hotel,mercado}');
assert.deepEqual(await one(`select xp_multiplier::float x, coin_multiplier::float c, hp_penalty_multiplier::float h
  from difficulty_levels where level = 'hard'`), { x: 0.85, c: 1, h: 1.25 });
await db.exec(`update character_stats set hp_current = 30 where user_id = '${U2}'`);
assert.equal((await stats(U2)).is_weakened, false);
await db.exec(`update character_stats set hp_current = 29 where user_id = '${U2}'`);
assert.equal((await stats(U2)).is_weakened, true);
await db.exec(`update character_stats set hp_current = 100 where user_id = '${U2}'`);
ok('004: lo descartado se borra, catálogo nuevo, dificultad del diseño y debilitado < 30');

// 005 · Recompensa de tareas por reglas --------------------------------------------
const goal = (await one(`insert into goals (user_id, title, skill_id, boss_max_hp, boss_current_hp)
  values ($1, 'Inglés B2', $2, 50, 50) returning id`, [U1, skill])).id;
const proj = (await one(`insert into projects (user_id, title) values ($1, 'Semestre') returning id`, [U1])).id;
let t40, t10, tProj;
await asUser(U1, async () => {
  t40 = await one(`insert into tasks (user_id, title, priority, goal_id, skill_id)
    values ($1, 'Leer un capítulo del libro', 'high', $2, $3) returning id, xp_reward, coin_reward`, [U1, goal, skill]);
  t10 = await one(`insert into tasks (user_id, title) values ($1, 'Corta') returning id, xp_reward, coin_reward`, [U1]);
  tProj = await one(`insert into tasks (user_id, title, priority, project_id)
    values ($1, 'Tarea media', 'medium', $2) returning id, xp_reward, coin_reward`, [U1, proj]);
  await db.exec(`update tasks set title = 'Ahora es un título mucho más largo' where id = '${t10.id}'`);
});
assert.deepEqual([t40.xp_reward, t40.coin_reward], [40, 12]);
assert.deepEqual([t10.xp_reward, t10.coin_reward], [10, 3]);
assert.deepEqual([tProj.xp_reward, tProj.coin_reward], [20, 6]);
assert.equal((await one(`select xp_reward from tasks where id = $1`, [t10.id])).xp_reward, 10);
ok('005: XP de tarea por reglas (10–40), Monedas 30 %, editar no recalcula');

// complete_task: anti-trampa de 2 min, daño al jefe y victoria.
await asUser(U1, async () => {
  const quick = await call(`select complete_task($1) r`, [t10.id]);
  assert.deepEqual([quick.r.xp, quick.r.coins], [10, 0]);
  await rejects(db.query(`select complete_task($1)`, [t10.id]), /task_not_open/);
});
await db.exec(`update tasks set created_at = now() - interval '10 minutes' where user_id = '${U1}'`);
await asUser(U1, async () => {
  const r = (await call(`select complete_task($1) r`, [t40.id])).r;
  assert.equal(r.xp, 40);
  assert.equal(r.coins, 12);
  assert.deepEqual(r.boss, { boss_hp: 10, defeated: false });
  await rejects(db.query(`select complete_task($1)`, [t40.id]), /task_not_open/);
});
let s = await stats(U1);
assert.deepEqual([s.current_xp, s.coins], [50, 12]);
assert.equal((await one(`select skill_id from quest_log_entries where source_id = $1`, [t40.id])).skill_id, skill);
const tBoss = (await one(`insert into tasks (user_id, title, goal_id, created_at)
  values ($1, 'Golpe final', $2, now() - interval '1 hour') returning id`, [U1, goal])).id;
await db.exec(`update tasks set created_at = now() - interval '1 hour' where id = '${tBoss}'`);
await asUser(U1, async () => {
  const r = (await call(`select complete_task($1) r`, [tBoss])).r;
  assert.equal(r.boss.defeated, true);
  assert.equal(r.boss.victory.xp, 300);
});
assert.equal((await one(`select status from goals where id = $1`, [goal])).status, 'completed');
s = await stats(U1);
assert.equal(s.level, 2); // 50 + 20 + 300 = 370 → nivel 2 con 270 de 283
assert.deepEqual([s.current_xp, s.xp_to_next_level], [270, 283]);
ok('005: complete_task (2 min, Bitácora con skill, jefe, victoria +300/+90, curva 100×n^1,5)');

// complete_project (sin lo ganado hoy: la victoria ya llenó el tope diario)
assert.equal((await one(`select sum(coin_awarded)::int n from quest_log_entries where user_id = $1`, [U1])).n, 75);
await db.exec(`delete from quest_log_entries where user_id = '${U1}'`);
await asUser(U1, async () => {
  await rejects(db.query(`select complete_project($1)`, [proj]), /project_has_open_tasks/);
  await db.query(`select complete_task($1)`, [tProj.id]);
  const r = (await call(`select complete_project($1) r`, [proj])).r;
  assert.equal(r.coins + r.treasury, 36);
  await rejects(db.query(`select complete_project($1)`, [proj]), /project_not_open/);
});
ok('005: complete_project da +36 Monedas');

// _award: tope suave diario, bolsa y Tesoro, dificultad y debilitado (U3).
const award = (xp, coins) => one(`select _award($1, 'task', gen_random_uuid(), $2, $3) r`, [U3, xp, coins]).then((x) => x.r);
assert.equal((await award(0, 40)).coins, 40);
assert.equal((await award(0, 20)).coins, 15); // 10 completas + 10/2
assert.equal((await award(0, 100)).coins, 20); // llega a 75
assert.equal((await award(0, 100)).coins, 0);
await db.exec(`delete from quest_log_entries where user_id = '${U3}'`);
await db.exec(`update character_stats set coins = 420 where user_id = '${U3}'`);
const purse = await award(0, 10);
assert.deepEqual([purse.coins, purse.treasury], [5, 5]); // bolsa nivel 1 = 425
await db.exec(`update game_master_settings set difficulty = 'hard' where user_id = '${U3}'`);
assert.equal((await award(100, 0)).xp, 85);
await db.exec(`update character_stats set hp_current = 20 where user_id = '${U3}'`);
assert.equal((await award(100, 0)).xp, 63); // 100 × 0,85 × 0,75
await db.exec(`update game_master_settings set difficulty = 'normal' where user_id = '${U3}';
  update character_stats set hp_current = 100 where user_id = '${U3}'`);
ok('005: tope suave 75/día, bolsa 400+25/nivel con Tesoro, dificultad ×0,85 y debilitado −25 %');

// Hábitos
const good = (await one(`insert into habits (user_id, name, type, skill_id) values ($1, 'Leer', 'good', $2) returning id`, [U1, skill])).id;
const bad = (await one(`insert into habits (user_id, name, type, hp_penalty) values ($1, 'Azúcar', 'bad', 5) returning id`, [U1])).id;
await rejects(db.exec(`insert into habits (user_id, name, type, hp_penalty) values ('${U1}', 'x', 'bad', 4)`), /habits_hp_penalty_by_type/);
await db.exec(`update game_master_settings set difficulty = 'hard' where user_id = '${U1}'`);
const before = await stats(U1);
await asUser(U1, async () => {
  await db.query(`select complete_habit($1, current_date)`, [good]);
  const r = (await call(`select register_bad_habit($1) r`, [bad])).r;
  assert.equal(r.hp_change, -6); // −5 × 1,25
  await db.query(`select register_bad_habit($1)`, [bad]); // varias veces al día
});
const after = await stats(U1);
assert.equal(after.hp_current, before.hp_current - 12);
assert.equal((await one(`select xp_awarded x, coin_awarded c from quest_log_entries
  where source_id = $1 and result = 'completed'`, [good])).c, 3);
await db.exec(`update game_master_settings set difficulty = 'normal' where user_id = '${U1}'`);
ok('005: hábito bueno 3 Monedas por reglas; mal hábito −3/−5/−8 × dificultad, varios al día');

// Cofre del día
await asUser(U2, async () => {
  await rejects(db.query(`select claim_daily_chest()`), /chest_locked/);
});
await db.exec(`insert into quest_log_entries (user_id, source_type, source_id, result)
  select '${U2}', 'task', gen_random_uuid(), 'completed' from generate_series(1, 3)`);
await asUser(U2, async () => {
  assert.equal((await call(`select claim_daily_chest() r`)).r.coins, 15);
  await rejects(db.query(`select claim_daily_chest()`), /chest_already_claimed/);
});
ok('005: cofre del día (15 Monedas con ≥ 3 misiones, uno al día)');

// 15 tareas con Monedas al día
await db.exec(`insert into quest_log_entries (user_id, source_type, source_id, result, coin_awarded)
  select '${U2}', 'task', gen_random_uuid(), 'completed', 1 from generate_series(1, 15)`);
const t16 = (await one(`insert into tasks (user_id, title) values ($1, 'La dieciséis') returning id`, [U2])).id;
await db.exec(`update tasks set created_at = now() - interval '1 hour' where id = '${t16}'`);
await asUser(U2, async () => {
  const r = (await call(`select complete_task($1) r`, [t16])).r;
  assert.deepEqual([r.xp, r.coins], [10, 0]);
});
ok('005: máximo 15 tareas con Monedas al día');

// 006 · Tienda -----------------------------------------------------------------------
await db.exec(`update character_stats set coins = 400, hp_current = 50 where user_id = '${U3}'`);
await asUser(U3, async () => {
  const r = (await call(`select purchase('siesta') r`)).r;
  assert.deepEqual([r.coins, r.hp_current], [370, 60]);
  await db.query(`select purchase('banquete')`);
  assert.equal((await one(`select hp_current from character_stats`)).hp_current, 100);
  await db.query(`select purchase('cofre')`);
  await rejects(db.query(`select purchase('cofre')`), /daily_limit_reached/);
  await db.query(`select purchase('elixir')`);
  await rejects(db.query(`select purchase('elixir')`), /active_limit_reached/);
  assert.equal((await one(`select count(*)::int n from user_consumables`)).n, 2);
  assert.equal((await one(`select count(*)::int n from purchases`)).n, 4);
  await rejects(db.query(`select purchase('banquete')`), /not_enough_coins/); // quedan 120
});
ok('006: Hotel cura, Cofre 1/día, Elixir 1 activo, sin saldo no se compra');

// Rachas de 48 h y Pase de Recuperación
const streakH = (await one(`insert into habits (user_id, name, type, created_at)
  values ($1, 'Agua', 'good', now() - interval '10 days') returning id`, [U2])).id;
await db.exec(`insert into habit_records (habit_id, user_id, completed_on)
  select '${streakH}', '${U2}', current_date - d from generate_series(2, 4) d;
  update habits set current_streak = 3, best_streak = 3 where id = '${streakH}'`);
let d = (await call(`select daily_maintenance(current_date - 1) r`)).r;
assert.ok(d.streaks_broken >= 1);
assert.deepEqual(await one(`select current_streak, broken_streak, broken_on = current_date - 1 b from habits where id = $1`, [streakH]),
  { current_streak: 0, broken_streak: 3, b: true });
await db.exec(`update character_stats set coins = 400 where user_id = '${U2}'`);
await asUser(U2, async () => {
  await rejects(db.query(`select use_recovery_pass($1)`, [streakH]), /no_pass/);
  await db.query(`select buy_black_market('pase_recuperacion')`);
  await rejects(db.query(`select buy_black_market('pase_recuperacion')`), /monthly_limit_reached/);
  assert.equal((await call(`select use_recovery_pass($1) r`, [streakH])).r.streak, 3);
  await db.query(`select complete_habit($1, current_date)`, [streakH]);
  assert.equal((await one(`select current_streak from habits where id = $1`, [streakH])).current_streak, 4);
  await rejects(db.query(`select use_recovery_pass($1)`, [streakH]), /no_pass/);
});
ok('006/007: racha rota guardada 48 h; Pase (1/mes) la restaura y sigue contando');

const streak2 = (await one(`insert into habits (user_id, name, type, created_at)
  values ($1, 'Correr', 'good', now() - interval '10 days') returning id`, [U2])).id;
await db.exec(`update habits set broken_streak = 7, broken_on = current_date - 1 where id = '${streak2}'`);
await asUser(U2, async () => {
  assert.equal((await call(`select buy_black_market('recuperar_racha', $1) r`, [streak2])).r.streak, 7);
  await rejects(db.query(`select buy_black_market('recuperar_racha', $1)`, [streak2]), /monthly_limit_reached/);
});
await db.exec(`update habits set broken_streak = 2, broken_on = current_date - 4 where id = '${streak2}'`);
await db.exec(`insert into recovery_passes (user_id) values ('${U2}')`);
await asUser(U2, async () => {
  await rejects(db.query(`select use_recovery_pass($1)`, [streak2]), /nothing_to_recover/);
});
ok('006: Recuperar racha (150, 1/mes) y fuera de las 48 h ya no se recupera');

// Refugio
await db.exec(`update character_stats set coins = 400 where user_id = '${U3}'`);
await asUser(U3, async () => {
  assert.equal((await call(`select upgrade_refuge('estandarte') r`)).r.price, 120);
  assert.equal((await call(`select upgrade_refuge('estandarte') r`)).r.price, 162);
});
ok('006: Refugio con precio 120 × 1,35^nivel');

// Taverna: límite y cooldown
const s3 = (await one(`insert into skills (user_id, name) values ($1, 'Salud') returning id`, [U3])).id;
await asUser(U3, async () => {
  for (const n of ['Búho', 'Zorra', 'Tortuga', 'Ciervo', 'Oso']) {
    await db.query(`insert into npcs (user_id, name, skill_id, frequency) values ($1, $2, $3, 'daily')`, [U3, n, s3]);
  }
  await rejects(db.query(`insert into npcs (user_id, name, skill_id, frequency) values ($1, 'Lobo', $2, 'daily')`, [U3, s3]), /npc_limit_reached/);
  const npc = (await one(`select id from npcs limit 1`)).id;
  assert.equal((await call(`select request_npc_mission($1) r`, [npc])).r.cost, 0);
  assert.equal((await call(`select request_npc_mission($1) r`, [npc])).r.cost, 15);
  await rejects(db.query(`update npcs set last_mission_at = null`), /permission denied/);
});
ok('006: máx. 3 NPC + Estandarte (2 niveles → 5); misión gratis cada 3 h, si no 15 Monedas');

// Mazmorra
await asUser(U3, async () => {
  await rejects(db.query(`insert into focus_sessions (user_id, total_minutes, cycle_minutes) values ($1, 45, 25)`, [U3]), /focus_sessions_shape/);
});
const session = (await asUser(U3, () => one(`insert into focus_sessions (user_id, total_minutes, cycle_minutes)
  values ($1, 90, 25) returning id`, [U3]))).id;
const dTasks = [];
for (let i = 0; i < 6; i++) dTasks.push((await one(`insert into tasks (user_id, title) values ($1, $2) returning id`, [U3, `T${i}`])).id);
await asUser(U3, async () => {
  for (const t of dTasks.slice(0, 5)) await db.query(`insert into focus_session_tasks values ($1, $2)`, [session, t]);
  await rejects(db.query(`insert into focus_session_tasks values ($1, $2)`, [session, dTasks[5]]), /session_task_limit/);
  await rejects(db.query(`select complete_dungeon_cycle($1, $2)`, [session, dTasks[0]]), /cycle_not_finished/);
  await db.query(`select activate_elixir()`);
});
await db.exec(`update focus_sessions set started_at = now() - interval '60 minutes' where id = '${session}'`);
await asUser(U3, async () => {
  const r1 = (await call(`select complete_dungeon_cycle($1, $2) r`, [session, dTasks[0]])).r;
  assert.deepEqual([r1.xp, r1.cycle], [15, 1]); // 10 × 1,5 con Elixir
  const r2 = (await call(`select complete_dungeon_cycle($1, $2) r`, [session, dTasks[1]])).r;
  assert.deepEqual([r2.xp, r2.cycle], [15, 2]);
  await rejects(db.query(`select complete_dungeon_cycle($1, $2)`, [session, dTasks[1]]), /cycle_not_finished/);
  assert.equal((await one(`select status from user_consumables where kind = 'elixir'`)).status, 'used');
});
ok('006: Mazmorra en bloques de 30, máx. 5 tareas, ciclos a su tiempo, Elixir ×1,5');

// 007 · Job diario -----------------------------------------------------------------
const late = (await one(`insert into tasks (user_id, title, due_date) values ($1, 'Tarde', now() - interval '2 days') returning id`, [U2])).id;
await db.exec(`update character_stats set hp_current = 80 where user_id = '${U2}'`);
await db.exec(`delete from daily_runs`);
await db.exec(`update profiles set created_at = now() - interval '30 days'`);
d = (await call(`select daily_maintenance(current_date - 1) r`)).r;
assert.ok(d.expired >= 1);
assert.equal((await one(`select status from tasks where id = $1`, [late])).status, 'expired');
const hp1 = (await stats(U2)).hp_current;
assert.equal(hp1, 75 - 5); // −5 plazo y −5 por no jugar ayer
await call(`select daily_maintenance(current_date - 1) r`);
assert.equal((await stats(U2)).hp_current, hp1);
await asUser(U2, async () => {
  await rejects(db.query(`select daily_maintenance()`), /permission denied/);
});
ok('007: vence plazos (−5), día sin jugar −5, una sola vez por día, solo el servidor');

// Notificaciones y vistas
const nIds = [];
for (let i = 0; i < 5; i++) {
  nIds.push((await one(`insert into notifications (user_id, type, title, message, category, event_key)
    values ($1, 'informational', 'Hola', 'Recordatorio', 'reminder', $2) returning id`, [U1, `reminder:x:${i}`])).id);
}
await rejects(db.exec(`insert into notifications (user_id, type, title, message, event_key)
  values ('${U1}', 'critical', 'x', 'x', 'reminder:x:0')`), /duplicate key/);
for (const id of nIds) await db.exec(`update notifications set ignored = true where id = '${id}'`);
assert.deepEqual(await one(`select consecutive_ignored n, reduced from notification_category_state where user_id = $1`, [U1]),
  { n: 5, reduced: true });
await db.exec(`update notifications set read_at = now() where id = '${nIds[0]}'`);
assert.equal((await one(`select reduced from notification_category_state where user_id = $1`, [U1])).reduced, false);
ok('007: event_key único y frecuencia decreciente tras 5 ignoradas');

await db.exec(`insert into tasks (user_id, title, priority, due_date) values
  ('${U1}', 'Urgente', 'low', now() + interval '2 hours'),
  ('${U1}', 'Alta', 'high', now() + interval '5 days')`);
await db.exec(`insert into tasks (user_id, title, status) values ('${U1}', 'Delegada', 'delegated')`);
await asUser(U1, async () => {
  const rows = (await db.query(`select title, bucket from v_daily_highlight order by bucket_order, title`)).rows;
  assert.deepEqual(rows.map((r) => r.bucket).filter((b, i, a) => a.indexOf(b) === i), ['urgent', 'high', 'pending']);
  assert.equal((await one(`select count(*)::int n from v_user_store`)).n, 5);
  await db.query(`insert into user_market_selection select $1, id from market_items where code = 'siesta'`, [U1]);
  assert.equal((await one(`select count(*)::int n from v_user_store`)).n, 1);
});
await asUser(U2, async () => {
  assert.equal((await one(`select count(*)::int n from v_daily_highlight where title = 'Urgente'`)).n, 0);
  assert.equal((await one(`select count(*)::int n from user_consumables`)).n, 0);
  assert.equal((await one(`select count(*)::int n from v_user_store`)).n, 5);
});
ok('007: v_daily_highlight (urgent → high → pending) y v_user_store, aislados por usuario');

// Lo anterior sigue funcionando.
await asUser(U1, async () => {
  const h = (await call(`select home_dashboard(current_date, 0) r`)).r;
  assert.equal(h.display_name, 'Ana');
  const p = (await call(`select profile_overview() r`)).r;
  assert.equal(p.skills.length, 1);
});
ok('home_dashboard y profile_overview siguen funcionando');

console.log('\nTodo en orden.');
