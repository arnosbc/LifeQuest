-- Migración 050 · Una sola create_habit (arregla «Crear hábito → Algo salió mal»).
-- Requiere 001–049. Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- Mismo caso que 049 con create_task: en Supabase quedaron la create_habit de 011
-- (6 parámetros, si 011 se volvió a ejecutar después de 039) y la de 039 (7, con
-- p_min_version). La app solo envía p_min_version cuando hay texto, así que crear un
-- hábito sin «versión mínima» encaja en las dos y Postgres responde «is not unique».
-- Se deja solo la de 039, que acepta los mismos 6 nombres.

begin;

do $$
declare
  v_keep regprocedure := to_regprocedure(
    'public.create_habit(text, public.habit_type, public.habit_frequency, integer[], '
    'integer, uuid, text)');
  v_fn regprocedure;
begin
  if v_keep is null then
    raise exception 'Falta create_habit de 039_day_close_habits.sql: aplícala antes de esta migración.';
  end if;
  for v_fn in
    select p.oid::regprocedure from pg_proc p
    where p.pronamespace = 'public'::regnamespace and p.proname = 'create_habit'
      and p.oid <> v_keep::oid
  loop
    execute format('drop function %s', v_fn);
  end loop;
end $$;

commit;
