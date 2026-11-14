// Prueba la migración 053 (recordatorios con la voz de Nevi) sobre 001–050.
// Uso: cd supabase/tests && node 053_nevi_reminders.test.mjs
import assert from 'node:assert/strict';

import { U1, createFullDb, migration, ok } from './bootstrap.mjs';

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
  '048_daily_reminders.sql', '049_local_timezone.sql', '050_push_fcm.sql',
  '053_nevi_reminders.sql', '053_nevi_reminders.sql']) {
  await db.exec(migration(f));
}
await db.exec(`insert into auth.users values ('${U1}', '{}')`);
ok('053 se aplica dos veces sin error');

const cfg = (await one(`select proconfig::text c from pg_proc where proname = '_generate_reminders'`)).c;
assert.match(cfg, /TimeZone=America\/Bogota/i);
ok('053: los recordatorios siguen en hora de Colombia (049)');

const today = (await one(`select (now() at time zone 'America/Bogota')::date::text d`)).d;
const token = await asUser(U1, () => one(`select register_device() r`)).then((x) => x.r);
const deliver = async (time) => {
  await db.exec(`set role anon; select set_config('request.jwt.claim.sub', '', false);
                 select set_config('request.jwt.claim.role', 'anon', false);`);
  try {
    return (await one(`select device_notifications($1, $2::date, $3::time) r`, [token, today, time]))
      .r.items.filter((i) => i.type === 'critical' && i.title.startsWith('Nevi'));
  } finally { await db.exec('reset role'); }
};
const later = () => db.query(`update notifications set delivered_at = now() - interval '3 hours'`);

await db.query(`insert into habits (user_id, name, type, current_streak) values ($1, 'Leer', 'good', 4)`, [U1]);
await db.query(`insert into tasks (user_id, title, due_date) values ($1, 'Informe', $2::date + interval '20 hours')`, [U1, today]);
await db.query(`delete from notifications`);

let items = await deliver('09:05');
assert.equal(items.length, 1);
assert.match(items[0].message, /^Hoy te esperan 1 hábito y 1 tarea\. Yo empezaría/);
ok('053: Nevi saluda en la mañana con lo pendiente');

await later();
items = await deliver('21:40');
assert.equal(items.length, 1);
assert.equal(items[0].title, 'Nevi: tu racha de 4 días sigue encendida 🔥');
assert.ok(!/Última oportunidad/.test(JSON.stringify(items)));
ok('053: la última llamada invita sin amenazar');
