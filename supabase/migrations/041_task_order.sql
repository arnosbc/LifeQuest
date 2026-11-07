-- Migración 041 · Orden estable de tareas y pasos (rework, mejoras).
-- Requiere 001–040. Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- Foco, los proyectos y los pasos ordenan por tasks.created_at. Con el valor por
-- defecto now() (hora de la transacción) los pasos y tareas que se crean juntos
-- (create_task con subtareas, proyecto o meta con sus pasos) empatan y salen en
-- cualquier orden: la primera tarea del proyecto podía quedar la última en Foco.
--   · clock_timestamp() da a cada fila su propio instante, en el orden de inserción.
--   · Los empates que ya existen se deshacen por fecha límite (los pasos del
--     asistente la tienen creciente) y, sin fecha, por id.

begin;

alter table public.tasks alter column created_at set default clock_timestamp();

update public.tasks t
set created_at = t.created_at + (r.n - 1) * interval '1 microsecond'
from (
  select id, row_number() over (
           partition by user_id, created_at
           order by due_date nulls last, id) as n,
         count(*) over (partition by user_id, created_at) as tied
  from public.tasks
) r
where r.id = t.id and r.tied > 1 and r.n > 1;

commit;
