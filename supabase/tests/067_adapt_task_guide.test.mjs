// Prueba la migración 067 («Hablar con Nevi»: rehacer los pasos pendientes).
// Uso: cd supabase/tests && node 067_adapt_task_guide.test.mjs
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
  '038_home_today.sql', '039_task_steps.sql', '040_focus_required.sql',
  '067_adapt_task_guide.sql', '067_adapt_task_guide.sql']) {
  await db.exec(migration(f));
}
await db.exec(`insert into auth.users values ('${U1}', '{}'), ('${U2}', '{}')`);
ok('067 se aplica dos veces sin error');

const call = (uid, sql, params) => asUser(uid, () => one(sql, params)).then((x) => x && x.r);
const t = (await call(U1, `select create_task($1) r`, ['Ordenar mi escritorio antes de estudiar'])).id;
await db.query(`update tasks set created_at = now() - interval '1 hour' where id = $1`, [t]);
await call(U1, `select attach_task_guide($1, $2::jsonb) r`, [t, JSON.stringify({
  objective: 'Espacio listo', steps: ['Retira lo que sobra', 'Limpia la mesa', 'Deja solo lo necesario'],
})]);
await call(U1, `select start_dungeon(60, 25, $1::uuid[]) r`, [[t]]);
const first = (await one(`select id from task_steps where task_id = $1 and position = 1`, [t])).id;
await call(U1, `select toggle_task_step($1) r`, [first]);
const paidBefore = (await one(`select paid_xp from task_steps where id = $1`, [first])).paid_xp;

await rejects(call(U1, `select attach_task_guide($1, '{"steps":["x"]}'::jsonb) r`, [t]), /guide_locked/);
const adapted = await call(U1, `select adapt_task_guide($1, $2::jsonb) r`, [t, JSON.stringify({
  steps: ['Despeja un lado de la cama', 'Pon una bandeja o tabla como mesa'], hints: ['Usa una almohada'],
})]);
const steps = (await db.query(
  `select position, title, paid_xp from task_steps where task_id = $1 order by position`, [t])).rows;
assert.deepEqual(steps.map((s) => [s.position, s.title]), [
  [1, 'Retira lo que sobra'], [2, 'Despeja un lado de la cama'], [3, 'Pon una bandeja o tabla como mesa'],
]);
assert.equal(steps[0].paid_xp, paidBefore);
const guide = (await one(`select guide from tasks where id = $1`, [t])).guide;
assert.equal(guide.objective, 'Espacio listo');
assert.deepEqual(guide.hints, ['Usa una almohada']);
assert.ok(adapted);
ok('067: conserva el paso pagado y su XP; reemplaza los pendientes a continuación');

// Al terminar, la tarea paga en total lo mismo que antes del cambio.
await call(U1, `select toggle_task_step(id) r from task_steps where task_id = '${t}' and position = 2`);
await call(U1, `select complete_task($1) r`, [t]);
const total = (await one(`select sum(xp_awarded)::int x from quest_log_entries
  where user_id = $1 and source_type::text in ('task', 'task_step')`, [U1])).x;
const reward = (await one(`select xp_reward from tasks where id = $1`, [t])).xp_reward;
assert.equal(total, reward);
ok(`067: la tarea adaptada paga su total (${total} XP, recompensa base ${reward})`);

await rejects(call(U2, `select adapt_task_guide($1, '{"steps":["x"]}'::jsonb) r`, [t]), /task_not_found/);
ok('067: nadie más puede cambiar los pasos de una tarea ajena');
