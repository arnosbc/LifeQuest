// Prueba la migración 016 (Configuración) sobre 001–015: settings_overview,
// rangos de game_master_settings y columnas que el jugador puede cambiar.
// Uso: cd supabase/tests && node 016_settings.test.mjs
import assert from 'node:assert/strict';

import { U1, U2, createFullDb, migration, ok, rejects } from './bootstrap.mjs';

const { db, one, asUser } = await createFullDb();
for (const f of ['003_security.sql', '004_structure.sql', '005_rewards.sql', '006_store.sql',
  '007_daily.sql', '008_fix_exploits.sql', '009_profile_titles.sql', '010_missions.sql',
  '011_habits.sql', '012_dungeon.sql', '013_stage.sql', '014_goals.sql', '015_onboarding.sql']) {
  await db.exec(migration(f));
}
await db.exec(migration('016_settings.sql'));
await db.exec(migration('016_settings.sql')); // idempotente
await db.exec(`insert into auth.users values ('${U1}', '{"username":"Ana"}'), ('${U2}', '{}')`);
ok('016 se aplica dos veces sin error');

const overview = (uid) => asUser(uid, () => one(`select settings_overview() r`)).then((x) => x.r);
const update = (uid, set) => asUser(uid, () => db.query(
  `update game_master_settings set ${set} where user_id = $1`, [uid]));

// Valores por defecto ------------------------------------------------------------------
let r = await overview(U1);
assert.deepEqual(
  [r.level, r.current_xp, r.difficulty, r.notification_daily_limit, r.silence_window_start,
    r.silence_window_end, r.critical_bypass_silence, r.short_break_minutes, r.long_break_minutes,
    r.long_break_every_n_cycles],
  [1, 0, 'normal', null, null, null, false, 5, 15, 4]);
assert.equal(typeof r.xp_to_next_level, 'number');
assert.deepEqual(r.difficulties.map((d) => d.level), ['easy', 'normal', 'hard']);
ok('016: settings_overview trae nivel, reglas por defecto y dificultades');

// El jugador cambia sus reglas ------------------------------------------------------------
await update(U1, `difficulty = 'hard', notification_daily_limit = 10,
  silence_window_start = '22:00', silence_window_end = '07:30', critical_bypass_silence = true,
  short_break_minutes = 10, long_break_minutes = 30, long_break_every_n_cycles = 3`);
r = await overview(U1);
assert.deepEqual(
  [r.difficulty, r.notification_daily_limit, r.silence_window_start, r.silence_window_end,
    r.critical_bypass_silence, r.short_break_minutes, r.long_break_minutes, r.long_break_every_n_cycles],
  ['hard', 10, '22:00', '07:30', true, 10, 30, 3]);
assert.equal((await overview(U2)).difficulty, 'normal');
ok('016: el jugador guarda dificultad, avisos y descansos; no afecta a otro');

// Rangos ------------------------------------------------------------------------------------
await rejects(update(U1, `notification_daily_limit = 0`), /daily_limit_range/);
await rejects(update(U1, `notification_daily_limit = 51`), /daily_limit_range/);
await rejects(update(U1, `silence_window_start = null`), /silence_pair/);
await rejects(update(U1, `short_break_minutes = 0`), /breaks_range/);
await rejects(update(U1, `long_break_minutes = 61`), /breaks_range/);
await rejects(update(U1, `long_break_every_n_cycles = 1`), /breaks_range/);
await update(U1, `notification_daily_limit = null, silence_window_start = null, silence_window_end = null`);
assert.equal((await overview(U1)).notification_daily_limit, null);
ok('016: los rangos rechazan valores fuera de lugar y permiten apagar límite y silencio');

// Lo que no es del jugador ----------------------------------------------------------------
await rejects(update(U1, `skill_limit = 99`), /permission denied/);
await update(U2, `difficulty = 'easy'`).then(() => asUser(U2, () => db.query(
  `update game_master_settings set difficulty = 'hard' where user_id = $1`, [U1])));
assert.equal((await overview(U1)).difficulty, 'hard');
await db.exec('set role anon');
await rejects(db.query('select settings_overview()'), /permission denied/);
await db.exec('reset role');
ok('016: skill_limit no se toca, un jugador no cambia las reglas de otro y anon no lee');
