// Prueba la migración 049 (hora de Colombia en el job diario y los avisos).
// La base corre en UTC, como Supabase. Uso: node 049_local_timezone.test.mjs
import assert from 'node:assert/strict';

import { U1, createFullDb, migration, ok } from './bootstrap.mjs';

const { db, one, asUser } = await createFullDb();
await db.exec(`set timezone = 'UTC'`);
for (const f of ['003_security.sql', '004_structure.sql', '005_rewards.sql', '006_store.sql',
  '007_daily.sql', '008_fix_exploits.sql', '009_profile_titles.sql', '010_missions.sql',
  '011_habits.sql', '012_dungeon.sql', '013_stage.sql', '014_goals.sql', '015_onboarding.sql',
  '016_settings.sql', '017_dungeon_breaks.sql', '018_marketplace.sql', '019_tavern.sql',
  '020_journal.sql', '021_boss_fight.sql', '022_rpgenie.sql', '023_brain_dump.sql',
  '024_vision_board.sql', '025_stats.sql', '026_inventory.sql', '027_daily_chest.sql',
  '028_edit_delete.sql', '029_notifications.sql', '030_npc_noble_mission.sql',
  '031_npc_mission_guide.sql', '033_dungeon_rewards.sql', '034_brain_dump_goal.sql',
  '036_device_notifications.sql', '043_settings_digest.sql', '045_more_reminders.sql',
  '048_daily_reminders.sql', '049_local_timezone.sql', '049_local_timezone.sql']) {
  await db.exec(migration(f));
}
await db.exec(`insert into auth.users values ('${U1}', '{}')`);
ok('049 se aplica dos veces sin error (sin pg_cron solo avisa)');

const cfg = (await one(`select proconfig c from pg_proc where proname = 'daily_maintenance'`)).c;
assert.ok(cfg.includes('TimeZone=America/Bogota') || cfg.includes('timezone=America/Bogota'), String(cfg));
ok('049: el job diario usa la hora de Colombia');

const D = '2026-10-31';
const token = await asUser(U1, () => one(`select register_device() r`)).then((x) => x.r);
const deliver = async (time) => {
  await db.exec(`set role anon; select set_config('request.jwt.claim.sub', '', false);
                 select set_config('request.jwt.claim.role', 'anon', false);`);
  try {
    return (await one(`select device_notifications($1, $2::date, $3::time) r`, [token, D, time]))
      .r.items.filter((i) => i.type === 'critical' && i.title !== 'Tienes tareas pendientes');
  } finally { await db.exec('reset role'); }
};

// Tarea de hoy a las 23:59 de Colombia (04:59 UTC del día siguiente).
const late = (await one(`insert into tasks (user_id, title, due_date)
  values ($1, 'Ensayo', '${D} 23:59-05') returning id`, [U1])).id;
const items = await deliver('19:40');
assert.equal(items.length, 1);
assert.equal(items[0].message, 'Te queda 1 tarea.');
ok('049: una tarea de hoy a las 23:59 cuenta en el recordatorio de la noche');

// Job del día D: vence lo de D (aunque sea 23:59 local), no lo de la madrugada de D+1.
const tomorrow = (await one(`insert into tasks (user_id, title, due_date)
  values ($1, 'Mañana', '2026-11-01 00:30-05') returning id`, [U1])).id;
// Creados antes de D: el job ignora hábitos creados después del día que revisa.
const kept = (await one(`insert into habits (user_id, name, type, current_streak, created_at)
  values ($1, 'Leer', 'good', 5, '2026-10-01') returning id`, [U1])).id;
const lost = (await one(`insert into habits (user_id, name, type, current_streak, created_at)
  values ($1, 'Correr', 'good', 3, '2026-10-01') returning id`, [U1])).id;
// «Leer» se hizo el 31 a las 21:00 en Colombia (ya 1 de nov en UTC).
await db.query(`insert into habit_records (habit_id, user_id, completed_on) values ($1, $2, '${D}')`, [kept, U1]);
const hpBefore = (await one(`select hp_current from character_stats where user_id = $1`, [U1])).hp_current;
await db.query(`select daily_maintenance('${D}')`);

const st = async (id) => (await one(`select status from tasks where id = $1`, [id])).status;
assert.equal(await st(late), 'expired');
assert.equal(await st(tomorrow), 'pending');
const streak = async (id) => (await one(`select current_streak s from habits where id = $1`, [id])).s;
assert.equal(await streak(kept), 5);
assert.equal(await streak(lost), 0);
const hpAfter = (await one(`select hp_current from character_stats where user_id = $1`, [U1])).hp_current;
assert.ok(hpAfter < hpBefore + 10, `vida ${hpBefore} → ${hpAfter}`);
assert.equal((await one(`select count(*)::int n from quest_log_entries
  where user_id = $1 and source_id = $2 and result = 'failed'`, [U1, late])).n, 1);
ok('049: el job vence la tarea de las 23:59, resta vida y respeta el hábito hecho de noche');
