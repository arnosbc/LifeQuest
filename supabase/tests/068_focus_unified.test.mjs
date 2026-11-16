// Prueba la migración 068 (Foco unificado: minutos por paso, paso actual y hábitos).
// Uso: cd supabase/tests && node 068_focus_unified.test.mjs
// 069: el botín de la sesión suma los hábitos cumplidos dentro de Foco.
import assert from 'node:assert/strict';

import { U1, U2, createFullDb, migration, ok, rejects } from './bootstrap.mjs';

const { db, one, asUser } = await createFullDb();
for (const f of ['003_security.sql', '004_structure.sql', '005_rewards.sql', '006_store.sql',
  '007_daily.sql', '008_fix_exploits.sql', '009_profile_titles.sql', '010_missions.sql',
  '011_habits.sql', '012_dungeon.sql', '013_stage.sql', '014_goals.sql', '015_onboarding.sql',
  '016_settings.sql', '017_dungeon_breaks.sql', '018_marketplace.sql', '019_tavern.sql',
  '020_journal.sql', '021_boss_fight.sql', '022_rpgenie.sql', '023_brain_dump.sql',
  '024_vision_board.sql', '025_stats.sql', '026_inventory.sql', '027_daily_chest.sql',
  '028_edit_delete.sql', '029_notifications.sql', '030_npc_noble_mission.sql',
  '031_npc_mission_guide.sql', '033_dungeon_rewards.sql', '037_reward_feedback.sql',
  '038_home_today.sql', '039_task_steps.sql', '040_focus_required.sql', '066_dungeon_loot_steps.sql',
  '067_adapt_task_guide.sql', '068_focus_unified.sql', '068_focus_unified.sql', '069_dungeon_loot_habits.sql']) {
  await db.exec(migration(f));
}
await db.exec(`insert into auth.users values ('${U1}', '{}'), ('${U2}', '{}')`);
ok('068 se aplica dos veces sin error');

const call = (uid, sql, params) => asUser(uid, () => one(sql, params)).then((x) => x && x.r);
const t = (await call(U1, `select create_task($1) r`, ['Ordenar mi escritorio'])).id;
await call(U1, `select attach_task_guide($1, $2::jsonb) r`, [t, JSON.stringify({
  steps: ['Retira lo que sobra', 'Limpia la mesa', 'Deja solo lo necesario'],
})]);
await call(U1, `select set_step_minutes($1, $2::int[]) r`, [t, [5, 10, 999]]);
const mins = (await db.query(`select minutes from task_steps where task_id = $1 order by position`, [t]))
  .rows.map((r) => r.minutes);
assert.deepEqual(mins, [5, 10, 240]);
await call(U2, `select set_step_minutes($1, $2::int[]) r`, [t, [1, 1, 1]]);
assert.equal((await one(`select minutes from task_steps where task_id = $1 and position = 1`, [t])).minutes, 5);
ok('068: set_step_minutes pone los minutos en orden, con tope, y solo a su dueño');

let board = await call(U1, `select dungeon_overview() r`);
const cand = board.candidates.find((c) => c.id === t);
assert.equal(cand.minutes, 255);
assert.equal(cand.step_count, 3);
ok('068: la candidata trae los minutos que faltan y cuántos pasos tiene');

const habitId = await call(U1, `select create_habit('Leer', 'good') r`);
board = await call(U1, `select dungeon_overview() r`);
assert.deepEqual(board.habit_candidates.map((x) => x.id), [habitId]);
ok('068: los hábitos buenos de hoy aparecen como candidatos');

// La app anterior (3 parámetros) sigue funcionando.
const old = await call(U1, `select start_dungeon(60, 30, $1::uuid[]) r`, [[t]]);
await call(U1, `select end_dungeon($1) r`, [old]);
ok('068: start_dungeon con 3 parámetros (app anterior) sigue funcionando');

await rejects(call(U2, `select start_dungeon(60, 30, null, $1::uuid[]) r`, [[habitId]]), /habit_not_found/);
const sid = await call(U1, `select start_dungeon(60, 30, $1::uuid[], $2::uuid[]) r`, [[t], [habitId]]);
board = await call(U1, `select dungeon_overview() r`);
const task = board.session.tasks[0];
assert.equal(task.step.title, 'Retira lo que sobra');
assert.equal(task.step.position, 1);
assert.equal(task.step_count, 3);
assert.deepEqual(board.session.habits.map((x) => [x.id, x.done]), [[habitId, false]]);
ok('068: la sesión trae el paso actual de la tarea y sus hábitos');

await call(U1, `select toggle_task_step($1) r`, [task.step.id]);
board = await call(U1, `select dungeon_overview() r`);
assert.equal(board.session.tasks[0].step.title, 'Limpia la mesa');
assert.equal(board.session.tasks[0].minutes, 250);
ok('068: al marcar un paso, Foco muestra el siguiente y los minutos que faltan');

// Bloque de un hábito: se cobra sin tarea.
await db.query(`update focus_sessions set started_at = now() - interval '31 minutes' where id = $1`, [sid]);
const paid = await call(U1, `select complete_dungeon_cycle($1, null, $2) r`, [sid, habitId]);
assert.equal(paid.cycle, 1);
board = await call(U1, `select dungeon_overview() r`);
assert.equal(board.session.habits[0].cycles, 1);
assert.equal(board.session.cycles_done, 1);
await rejects(call(U1, `select complete_dungeon_cycle($1, null, null) r`, [sid]), /task_not_in_session/);
ok('068: un bloque de un hábito se cobra y cuenta para ese hábito');

// Con dos parámetros (app anterior) cobra la tarea como antes.
await db.query(`update focus_sessions set started_at = now() - interval '61 minutes' where id = $1`, [sid]);
assert.equal((await call(U1, `select complete_dungeon_cycle($1, $2) r`, [sid, t])).cycle, 2);
ok('068: complete_dungeon_cycle con 2 parámetros sigue cobrando la tarea');

const today = (await one(`select (now() at time zone 'America/Bogota')::date d`)).d;
await call(U1, `select complete_habit($1, $2::date) r`, [habitId, today]);
board = await call(U1, `select dungeon_overview() r`);
assert.equal(board.session.habits[0].done, true);
assert.deepEqual(board.habit_candidates, []);
ok('068: el hábito cumplido sale marcado y deja de ser candidato');

// 069: el hábito cumplido en la sesión suma al botín (XP de 2 bloques + pasos + hábito).
const habitXp = (await one(`select xp_awarded x from quest_log_entries
  where source_type = 'habit' and source_id = $1`, [habitId])).x;
const loot = (await one(`select xp from _dungeon_loot($1)`, [sid])).xp;
const withoutHabit = (await one(`select coalesce(sum(xp_awarded), 0)::int x from quest_log_entries
  where source_type in ('dungeon', 'task_step', 'task')`)).x;
assert.ok(habitXp > 0);
assert.equal(Number(loot), withoutHabit + habitXp);
ok(`069: el botín de la sesión incluye el hábito (+${habitXp} XP)`);
