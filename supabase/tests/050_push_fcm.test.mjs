// Prueba la migración 050 (push con FCM) sobre 001–049.
// Uso: cd supabase/tests && node 050_push_fcm.test.mjs
import assert from 'node:assert/strict';

import { U1, createFullDb, migration, ok, rejects } from './bootstrap.mjs';

const { db, one, asUser } = await createFullDb();
await db.exec(`create role service_role nologin`);
for (const f of ['003_security.sql', '004_structure.sql', '005_rewards.sql', '006_store.sql',
  '007_daily.sql', '008_fix_exploits.sql', '009_profile_titles.sql', '010_missions.sql',
  '011_habits.sql', '012_dungeon.sql', '013_stage.sql', '014_goals.sql', '015_onboarding.sql',
  '016_settings.sql', '017_dungeon_breaks.sql', '018_marketplace.sql', '019_tavern.sql',
  '020_journal.sql', '021_boss_fight.sql', '022_rpgenie.sql', '023_brain_dump.sql',
  '024_vision_board.sql', '025_stats.sql', '026_inventory.sql', '027_daily_chest.sql',
  '028_edit_delete.sql', '029_notifications.sql', '030_npc_noble_mission.sql',
  '031_npc_mission_guide.sql', '033_dungeon_rewards.sql', '034_brain_dump_goal.sql',
  '036_device_notifications.sql', '043_settings_digest.sql', '045_more_reminders.sql',
  '048_daily_reminders.sql', '049_local_timezone.sql', '050_push_fcm.sql', '050_push_fcm.sql']) {
  await db.exec(migration(f));
}
await db.exec(`insert into auth.users values ('${U1}', '{}')`);
ok('050 se aplica dos veces sin error (sin pg_cron solo avisa)');

const token = await asUser(U1, () => one(`select register_device() r`)).then((x) => x.r);
const FCM = 'fcm-token-de-prueba-123456789';
await rejects(asUser(U1, () => db.query(`select set_push_token($1, 'corto')`, [token])), /invalid_push_token/);
await rejects(asUser(U1, () => db.query(`select set_push_token('otro', $1)`, [FCM])), /device_not_registered/);
await asUser(U1, () => db.query(`select set_push_token($1, $2)`, [token, FCM]));
ok('050: el teléfono guarda su token FCM con su código');

// Sin nada pendiente no se envía nada.
assert.deepEqual((await one(`select push_dispatch() r`)).r, []);

// Una tarea vencida genera el aviso crítico, que sale una sola vez por push.
await db.query(`insert into tasks (user_id, title, due_date) values ($1, 'Informe', now() - interval '2 days')`, [U1]);
const first = (await one(`select push_dispatch() r`)).r;
assert.equal(first.length, 1);
assert.deepEqual(first[0].tokens, [FCM]);
assert.ok(first[0].items.some((i) => i.title === 'Tienes tareas pendientes'));
assert.deepEqual((await one(`select push_dispatch() r`)).r, []);
ok('050: push_dispatch entrega lo que toca una sola vez');

// La revisión del teléfono no lo repite (los dos marcan delivered_at).
await db.exec(`set role anon; select set_config('request.jwt.claim.sub', '', false);
               select set_config('request.jwt.claim.role', 'anon', false);`);
// Fecha y hora de Colombia, como las manda el teléfono (049): con current_date
// (UTC) la prueba fallaba de noche porque el «día» ya era mañana.
const local = (await one(`select device_notifications($1,
  (now() at time zone 'America/Bogota')::date,
  (now() at time zone 'America/Bogota')::time(0)) r`, [token])).r.items;
await db.exec('reset role');
assert.ok(!local.some((i) => i.title === 'Tienes tareas pendientes'));
ok('050: la revisión del teléfono no duplica lo enviado por push');

await rejects(asUser(U1, () => one(`select push_dispatch() r`)), /permission denied/);
await db.query(`select clear_push_token($1)`, [FCM]);
assert.equal((await one(`select count(*)::int n from device_registrations where fcm_token is not null`)).n, 0);
ok('050: solo el servidor envía, y un token muerto se borra');
