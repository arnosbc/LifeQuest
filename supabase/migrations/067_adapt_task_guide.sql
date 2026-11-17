-- Migración 067 · «Hablar con Nevi»: rehacer solo los pasos pendientes (requiere 039).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- Idea del usuario (2026-11-15): si un paso no aplica («no tengo escritorio»),
-- la persona se lo dice a Nevi y la IA rehace lo que falta. attach_task_guide
-- (039) se niega con un paso ya cobrado (guide_locked); esta función conserva
-- los pasos pagados (y su XP) y reemplaza solo los pendientes, a continuación.
-- toggle_task_step reparte la XP restante entre los pasos sin pagar, así que
-- el total de la tarea no cambia. Hasta 8 pasos en total.

begin;

create or replace function public.adapt_task_guide(p_task_id uuid, p_guide jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_task public.tasks;
  v_kept integer;
  v_steps jsonb;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  select * into v_task from public.tasks
  where id = p_task_id and user_id = v_uid and parent_task_id is null for update;
  if not found then
    raise exception 'task_not_found' using errcode = 'P0002';
  end if;
  if v_task.status not in ('pending', 'in_progress') then
    raise exception 'task_not_open' using errcode = '22023';
  end if;

  -- Pasos ya cobrados: se quedan y fijan desde dónde siguen los nuevos.
  select coalesce(max(position), 0) into v_kept
  from public.task_steps where task_id = p_task_id and paid_at is not null;
  v_steps := public._text_list(p_guide -> 'steps', 8 - v_kept, 300);
  if jsonb_array_length(v_steps) = 0 then
    raise exception 'invalid_guide' using errcode = '22023';
  end if;

  delete from public.task_steps where task_id = p_task_id and paid_at is null;
  insert into public.task_steps (task_id, user_id, position, title)
  select p_task_id, v_uid, v_kept + n, x
  from jsonb_array_elements_text(v_steps) with ordinality as t(x, n);

  update public.tasks set guide = jsonb_build_object(
    'objective', coalesce(
      nullif(left(trim(coalesce(p_guide ->> 'objective', '')), 400), ''),
      v_task.guide ->> 'objective'),
    'topic', v_task.guide ->> 'topic',
    'hints', public._text_list(p_guide -> 'hints', 4, 400),
    'search', public._text_list(p_guide -> 'search', 2, 120))
  where id = p_task_id;

  return public.task_detail(p_task_id);
end $$;

revoke all on function public.adapt_task_guide(uuid, jsonb) from public, anon;
grant execute on function public.adapt_task_guide(uuid, jsonb) to authenticated;

commit;

notify pgrst, 'reload schema';
