// Prueba supabase/migrations/002_profile.sql (Perfil: skills, límite,
// borrado, longitudes y profile_overview), aplicada sobre 001_home.sql.
// Uso: cd supabase/tests && npm install && npm test
import assert from 'node:assert/strict';

import { U1, U2, createDb, migration, ok, rejects } from './bootstrap.mjs';

const { db, one, asUser } = await createDb();
await db.exec(migration('001_home.sql'));
await db.exec(migration('002_profile.sql'));
await db.exec(migration('002_profile.sql')); // idempotente
await db.exec(`insert into auth.users values ('${U1}', '{"username":"Ana"}'), ('${U2}', '{"username":"Leo"}')`);

// 1. El cliente crea y renombra skills, pero no toca nivel ni XP.
const skill = await asUser(U1, async () => {
  const id = (await one(`insert into skills (user_id, name) values ($1, 'Inglés') returning id`, [U1])).id;
  await db.exec(`update skills set name = 'Inglés C1' where id = '${id}'`);
  await rejects(db.exec(`update skills set level = 99 where id = '${id}'`), /permission denied/);
  await rejects(db.exec(`insert into skills (user_id, name, level) values ('${U1}', 'Trampa', 50)`),
    /permission denied/);
  return id;
});
assert.deepEqual(await one(`select name, level from skills where id = $1`, [skill]),
  { name: 'Inglés C1', level: 1 });
ok('skills: el cliente solo elige el nombre');

// 2. Límite (6 por defecto, ampliable en Game Master).
await asUser(U1, async () => {
  for (const n of ['Salud', 'Diseño', 'Universidad', 'Música', 'Cocina']) {
    await db.query(`insert into skills (user_id, name) values ($1, $2)`, [U1, n]);
  }
  await rejects(db.query(`insert into skills (user_id, name) values ($1, 'Séptima')`, [U1]),
    /skill_limit_reached/);
});
await db.exec(`update game_master_settings set skill_limit = 7 where user_id = '${U1}'`);
await asUser(U1, () => db.query(`insert into skills (user_id, name) values ($1, 'Séptima')`, [U1]));
await asUser(U2, () => db.query(`insert into skills (user_id, name) values ($1, 'Fútbol')`, [U2]));
ok('límite de skills por usuario y ampliable');

// 3. Borrar una skill en uso.
const salud = (await one(`select id from skills where name = 'Salud'`)).id;
await db.exec(`
  insert into goals (user_id, skill_id, title) values ('${U1}', '${salud}', 'Correr 10K');
  insert into projects (user_id, skill_id, title) values ('${U1}', '${salud}', 'Plan');
  insert into tasks (user_id, skill_id, title) values ('${U1}', '${salud}', 'Trotar');
  insert into habits (user_id, skill_id, name, type) values ('${U1}', '${salud}', 'Agua', 'good');`);
await asUser(U1, () => db.query(`delete from skills where id = $1`, [salud]));
for (const t of ['goals', 'projects', 'tasks', 'habits']) {
  assert.equal((await one(`select count(*)::int n from ${t} where skill_id is null`)).n, 1, t);
}
const musica = (await one(`select id from skills where name = 'Música'`)).id;
await db.exec(`insert into npcs (user_id, name, skill_id, frequency) values ('${U1}', 'Vera', '${musica}', 'weekly')`);
await asUser(U1, () =>
  rejects(db.query(`delete from skills where id = $1`, [musica]), /violates foreign key/));
ok('borrar skill: se suelta de metas/proyectos/tareas/hábitos; un NPC lo impide');

// 4. Longitudes.
await asUser(U1, async () => {
  await rejects(db.exec(`update profiles set display_name = '   '`), /profiles_display_name_length/);
  await rejects(db.query(`update profiles set identity_statement = $1`, ['x'.repeat(281)]),
    /profiles_identity_length/);
  await rejects(db.query(`update skills set name = $1 where id = $2`, ['x'.repeat(41), skill]),
    /skills_name_length/);
  await db.query(`update profiles set display_name = 'Ana María', identity_statement = $1`,
    ['Una estratega que termina lo que empieza.']);
});
const U3 = '33333333-3333-3333-3333-333333333333';
await db.query(`insert into auth.users values ($1, $2)`, [U3, { username: 'n'.repeat(60) }]);
assert.equal((await one(`select char_length(display_name) n from profiles where id = $1`, [U3])).n, 40);
ok('longitudes de nombre, identidad y skill; el alta recorta nombres largos');

// 5. profile_overview.
await db.exec(`
  insert into quest_log_entries (user_id, source_type, source_id, result) values
    ('${U1}', 'task', gen_random_uuid(), 'completed'),
    ('${U1}', 'task', gen_random_uuid(), 'completed'),
    ('${U1}', 'habit', gen_random_uuid(), 'completed'),
    ('${U1}', 'task', gen_random_uuid(), 'failed'),
    ('${U2}', 'task', gen_random_uuid(), 'failed');`);
const p = (await asUser(U1, () => one(`select profile_overview() p`))).p;
assert.equal(p.display_name, 'Ana María');
assert.equal(p.identity_statement, 'Una estratega que termina lo que empieza.');
assert.equal(p.level, 1);
assert.equal(p.coins, 0);
assert.equal(p.hp_current, 100);
assert.equal(p.quests_completed, 3);
assert.equal(p.quests_failed, 1);
assert.equal(p.skill_limit, 7);
assert.deepEqual(p.skills.map((s) => s.name),
  ['Inglés C1', 'Diseño', 'Universidad', 'Música', 'Cocina', 'Séptima']);
const q = (await asUser(U2, () => one(`select profile_overview() p`))).p;
assert.deepEqual(q.skills.map((s) => s.name), ['Fútbol']);
assert.equal(q.quests_completed, 0);
await db.exec('set role anon');
await rejects(db.query('select profile_overview()'), /permission denied/);
await db.exec('reset role');
ok('profile_overview: datos, tasa y aislamiento entre usuarios');

console.log('\nTodo en orden.');
