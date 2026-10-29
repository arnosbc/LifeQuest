// Prueba la migración 036 (avisos en el dispositivo) sobre 001–035.
// Uso: cd supabase/tests && node 036_device_notifications.test.mjs
import assert from 'node:assert/strict';

import { U1, U2, createFullDb, migration, ok, rejects } from './bootstrap.mjs';

const { db, one, asUser } = await createFullDb();
// 032 y 035 necesitan el esquema storage de Supabase; aquí no hacen falta.
for (const f of ['003_security.sql', '004_structure.sql', '005_rewards.sql', '006_store.sql',
  '007_daily.sql', '008_fix_exploits.sql', '009_profile_titles.sql', '010_missions.sql',
  '011_habits.sql', '012_dungeon.sql', '013_stage.sql', '014_goals.sql', '015_onboarding.sql',
  '016_settings.sql', '017_dungeon_breaks.sql', '018_marketplace.sql', '019_tavern.sql',
  '020_journal.sql', '021_boss_fight.sql', '022_rpgenie.sql', '023_brain_dump.sql',
  '024_vision_board.sql', '025_stats.sql', '026_inventory.sql', '027_daily_chest.sql',
  '028_edit_delete.sql', '029_notifications.sql', '030_npc_noble_mission.sql',
  '031_npc_mission_guide.sql', '033_dungeon_rewards.sql', '034_brain_dump_goal.sql']) {
  await db.exec(migration(f));
}
await db.exec(migration('036_device_notifications.sql'));
await db.exec(migration('036_device_notifications.sql')); // idempotente
await db.exec(`insert into auth.users values ('${U1}', '{"username":"Ana"}'), ('${U2}', '{}')`);
ok('036 se aplica dos veces sin error');

const today = (await one(`select current_date::text d`)).d;
const call = (uid, sql, params) => asUser(uid, () => one(sql, params)).then((x) => x && x.r);
// El proceso de fondo llama como anon, solo con el código del dispositivo.
const asAnon = async (fn) => {
  await db.exec(`set role anon; select set_config('request.jwt.claim.sub', '', false);
                 select set_config('request.jwt.claim.role', 'anon', false);`);
  try { return await fn(); } finally { await db.exec('reset role'); }
};
const deliver = (token, time) => asAnon(() =>
  one(`select device_notifications($1, $2::date, $3::time) r`, [token, today, time])).then((x) => x.r.items);
const titles = (items) => items.map((i) => i.title).sort();
const reset = async () => {
  await db.query(`delete from notifications`);
  await db.query(`update game_master_settings set notification_daily_limit = null,
    silence_window_start = null, silence_window_end = null, critical_bypass_silence = false,
    digest_time = null`);
};

// Registro: un código por dispositivo, solo se guarda el hash, máximo 5.
const token = await call(U1, `select register_device() r`);
assert.match(token, /^[0-9a-f]{64}$/);
const stored = await one(`select encode(token_hash, 'hex') h from device_registrations where user_id = $1`, [U1]);
assert.notEqual(stored.h, token);
for (let i = 0; i < 6; i++) await call(U2, `select register_device() r`);
assert.equal((await one(`select count(*)::int n from device_registrations where user_id = $1`, [U2])).n, 5);
await rejects(asAnon(() => one(`select register_device() r`)), /permission denied/);
await rejects(asUser(U1, () => one(`select * from device_registrations`)), /permission denied/);
await rejects(deliver('codigo-falso', '12:00'), /device_not_registered/);
await rejects(asUser(U1, () => one(`select _generate_notifications($1, $2::date)`, [U1, today])), /permission denied/);
ok('036: registro de dispositivos con código aleatorio y sin acceso directo');

// Datos de 029: racha (▲), proyecto en 🔴 (▲), cerca de nivel (●) y misión de hoy (○).
await db.query(`insert into habits (user_id, name, type, current_streak) values ($1, 'Leer', 'good', 12)`, [U1]);
const p = (await one(`insert into projects (user_id, title, start_date, end_date)
  values ($1, 'Tesis', current_date - 10, current_date + 1) returning id`, [U1])).id;
await db.query(`insert into tasks (user_id, project_id, title) values ($1, $2, 'A'), ($1, $2, 'B')`, [U1, p]);
await db.query(`update character_stats set current_xp = 95, xp_to_next_level = 100 where user_id = $1`, [U1]);
await db.query(`insert into tasks (user_id, title, due_date) values ($1, 'Pagar luz', $2::date + interval '20 hours')
  , ($1, 'Llamar', $2::date + interval '21 hours')`, [U1, today]);
await db.query(`insert into skills (user_id, name) values ($1, 'Salud')`, [U1]);

// 07:00: el proyecto y el nivel al momento; la racha espera a la tarde y lo
// informativo al digest de las 08:00.
let items = await deliver(token, '07:00');
assert.deepEqual(titles(items), ['Estás a un paso del nivel 2', 'Un proyecto necesita tu atención']);
assert.deepEqual(await deliver(token, '07:30'), []); // nada se entrega dos veces
items = await deliver(token, '08:15');
assert.deepEqual(items.map((i) => [i.type, i.title, i.message]),
  [['informational', 'Tu día de hoy', 'Hoy vencen 2 misiones. Tú decides el orden.']]);
items = await deliver(token, '18:30');
assert.deepEqual(items.map((i) => [i.type, i.title]), [['critical', 'Tu racha te está esperando 🔥']]);
assert.deepEqual(await deliver(token, '19:00'), []);
// El centro de avisos sigue igual que con 029.
const overview = await call(U1, `select notifications_overview($1::date) r`, [today]);
assert.equal(overview.items.length, 4);
assert.equal(overview.unread, 4);
ok('036: crítico al momento (racha al final del día), motivacional al momento y digest');

// Varios informativos van en un solo digest.
await reset();
await db.query(`insert into notifications (user_id, type, category, title, message)
  values ($1, 'informational', 'x', 'Uno', 'a'), ($1, 'informational', 'y', 'Dos', 'b')`, [U1]);
await db.query(`update game_master_settings set digest_time = '20:00' where user_id = $1`, [U1]);
assert.equal((await deliver(token, '12:00')).filter((i) => i.type === 'informational').length, 0);
items = (await deliver(token, '20:05')).filter((i) => i.type === 'informational');
assert.equal(items.length, 1);
assert.equal(items[0].title, 'Tu resumen del día');
assert.equal(items[0].message, 'Tienes 3 avisos: Uno · Dos · Tu día de hoy.');
assert.equal((await one(`select count(*)::int n from notifications
  where user_id = $1 and digest_slot = 'evening'`, [U1])).n, 3);
ok('036: el digest agrupa lo informativo a la hora elegida');

// Ventana de silencio: solo pasa lo crítico si el usuario lo permitió.
await reset();
await db.query(`update game_master_settings set silence_window_start = '22:00', silence_window_end = '07:00'
  where user_id = $1`, [U1]);
assert.deepEqual(await deliver(token, '23:00'), []);
assert.deepEqual(await deliver(token, '06:59'), []);
await db.query(`update game_master_settings set critical_bypass_silence = true where user_id = $1`, [U1]);
assert.deepEqual(titles(await deliver(token, '23:30')), ['Tu racha te está esperando 🔥', 'Un proyecto necesita tu atención']);
assert.deepEqual(titles(await deliver(token, '07:00')), ['Estás a un paso del nivel 2']);
ok('036: la ventana de silencio guarda lo no crítico');

// Mazmorra activa: lo no crítico espera a que termine.
await reset();
const s = (await one(`insert into focus_sessions (user_id, total_minutes, cycle_minutes)
  values ($1, 60, 25) returning id`, [U1])).id;
assert.deepEqual(titles(await deliver(token, '19:00')), ['Tu racha te está esperando 🔥', 'Un proyecto necesita tu atención']);
await db.query(`update focus_sessions set status = 'completed' where id = $1`, [s]);
assert.deepEqual(titles(await deliver(token, '19:30')), ['Estás a un paso del nivel 2', 'Tu día de hoy']);
ok('036: en la Mazmorra solo pasa lo crítico');

// Límite diario: lo no crítico se corta; lo crítico no cuenta.
await reset();
await db.query(`update game_master_settings set notification_daily_limit = 1 where user_id = $1`, [U1]);
items = await deliver(token, '19:00');
assert.deepEqual(titles(items), ['Estás a un paso del nivel 2', 'Tu racha te está esperando 🔥',
  'Un proyecto necesita tu atención']);
assert.deepEqual(await deliver(token, '19:30'), []); // el digest espera a mañana
ok('036: el límite diario solo frena lo no crítico');

// Entregado y sin leer en 24 h → ignorado; tras 5, la categoría se reduce.
await reset();
for (let i = 0; i < 5; i++) {
  await db.query(`insert into notifications (user_id, type, category, title, message, delivered_at)
    values ($1, 'motivational', 'level', 'Viejo', 'x', now() - interval '25 hours')`, [U1]);
}
items = await deliver(token, '19:00');
// 'level' ya no se genera; el resto sigue igual.
assert.deepEqual(titles(items), ['Tu día de hoy', 'Tu racha te está esperando 🔥',
  'Un proyecto necesita tu atención']);
assert.equal((await one(`select reduced from notification_category_state
  where user_id = $1 and category = 'level'`, [U1])).reduced, true);
ok('036: lo ignorado 5 veces baja la frecuencia de su categoría');

// Aislamiento y baja del dispositivo.
const token2 = await call(U2, `select register_device() r`);
assert.deepEqual(await deliver(token2, '19:00'), []);
await asAnon(() => one(`select unregister_device($1)`, [token]));
await rejects(deliver(token, '19:00'), /device_not_registered/);
ok('036: cada dispositivo ve solo a su jugador y se da de baja');
