-- Migración 040 · Borrar proyectos, metas y recursos (rework, mejoras).
-- Requiere 001–039. Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- Hasta ahora solo se podían archivar. delete_item los borra de verdad:
--   · las tareas y proyectos vinculados no se pierden: quedan sin proyecto / sin meta;
--   · lo completado no se borra (como delete_task, 028): su XP ya está en el
--     Historial; para quitarlo de la vista está archive_item.

begin;

create or replace function public.delete_item(p_kind text, p_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_status public.objective_status;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  if p_kind = 'project' then
    select status into v_status from public.projects
    where id = p_id and user_id = v_uid for update;
  elsif p_kind = 'goal' then
    select status into v_status from public.goals
    where id = p_id and user_id = v_uid for update;
  elsif p_kind = 'resource' then
    delete from public.resources where id = p_id and user_id = v_uid;
    if not found then
      raise exception 'item_not_found' using errcode = 'P0002';
    end if;
    return;
  else
    raise exception 'invalid_kind' using errcode = '22023';
  end if;
  if not found then
    raise exception 'item_not_found' using errcode = 'P0002';
  end if;
  if v_status = 'completed' then
    raise exception 'item_completed' using errcode = 'P0001';
  end if;

  if p_kind = 'project' then
    update public.tasks set project_id = null where project_id = p_id and user_id = v_uid;
    delete from public.projects where id = p_id;
  else
    update public.tasks set goal_id = null where goal_id = p_id and user_id = v_uid;
    update public.projects set goal_id = null where goal_id = p_id and user_id = v_uid;
    delete from public.goals where id = p_id;
  end if;
end $$;

revoke all on function public.delete_item(text, uuid) from public, anon;
grant execute on function public.delete_item(text, uuid) to authenticated;

commit;
