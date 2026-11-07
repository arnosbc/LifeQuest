// Prueba la migración 036: con funciones de otra rama que leen npcs (ya
// borrada por 035), Hoy, Stage, Historial, Estadísticas y completar fallan;
// tras 036 vuelven a funcionar.
// Uso: cd supabase/tests && node 036_restore_functions.test.mjs
import assert from 'node:assert/strict';
import { readdirSync } from 'node:fs';

import { U1, createFullDb, migration, ok } from './bootstrap.mjs';

const { db, one, asUser } = await createFullDb();
const files = readdirSync(new URL('../migrations/', import.meta.url))
  .filter((f) => f >= '003' && f < '036' && f.endsWith('.sql')).sort();
for (const f of files) await db.exec(migration(f));
await db.exec(`insert into auth.users values ('${U1}', '{"username":"Ana"}')`);

// Lo que había en la base desplegada: versiones que leen npcs.
const broken = `select jsonb_build_object('n', (select count(*) from public.npcs))`;
await db.exec(`
  create or replace function public.home_dashboard(p_day date, p_utc_offset_minutes integer default 0)
    returns jsonb language plpgsql as $$ begin return (${broken}); end $$;
  create or replace function public.stage_overview_before_historical_pace(p_day date)
    returns jsonb language plpgsql as $$ begin return (${broken}); end $$;
  create or replace function public.complete_task(p_task_id uuid)
    returns jsonb language plpgsql as $$ begin return (${broken}); end $$;`);
const as = (sql, p) => asUser(U1, () => one(sql, p));
await assert.rejects(as('select home_dashboard(current_date, 0) r'), /npcs/);

await db.exec(migration('036_restore_functions.sql'));
await db.exec(migration('036_restore_functions.sql')); // idempotente
const t = (await as(`select create_task('Leer') r`)).r.id;
await as('select complete_task($1)', [t]);
for (const sql of ['select home_dashboard(current_date, -300) r', 'select stage_overview(current_date) r',
  'select journal_overview(current_date) r', 'select stats_overview(current_date) r']) {
  assert.ok((await as(sql)).r, sql);
}
ok('036: Hoy, Stage, Historial, Estadísticas y completar vuelven a funcionar sin npcs');
