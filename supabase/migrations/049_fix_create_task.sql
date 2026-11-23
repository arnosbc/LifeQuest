-- Migración 049 · Una sola create_task (arregla «Crear tarea → Algo salió mal»).
-- Requiere 001–048. Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- Causa: en Supabase quedaron varias create_task a la vez. La de Questly (038) tiene 13
-- parámetros; volver a ejecutar 032_scheduling.sql después de 038 recrea la de 12, y la
-- 040_focus_required.sql de la rama LifeQuest (estevan_duolingo / jhon_cambios) recrea
-- la de 010 (8). Una llamada con nombres (p_title, p_due_date, p_scheduled_at…) encaja
-- en más de una y Postgres responde «function create_task(...) is not unique» (42725).
--
-- Arreglo: se borra toda create_task que no sea la de 038. La de 038 acepta los mismos
-- 8 nombres (el resto tiene valor por defecto), así que quien llame con la firma vieja
-- sigue creando tareas.

begin;

do $$
declare
  v_keep regprocedure := to_regprocedure(
    'public.create_task(text, text, public.urgency_level, timestamptz, uuid, uuid, uuid, '
    'text[], timestamptz, integer, integer, text, boolean)');
  v_fn regprocedure;
begin
  if v_keep is null then
    raise exception 'Falta create_task de 038_reminders.sql: aplícala antes de esta migración.';
  end if;
  for v_fn in
    select p.oid::regprocedure from pg_proc p
    where p.pronamespace = 'public'::regnamespace and p.proname = 'create_task'
      and p.oid <> v_keep::oid
  loop
    execute format('drop function %s', v_fn);
  end loop;
end $$;

commit;
