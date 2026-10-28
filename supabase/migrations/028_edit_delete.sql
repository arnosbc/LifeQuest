-- Migración 028 · Editar y borrar misiones, hábitos y NPCs (requiere 001–027).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- 1. rename_task / delete_task: solo misiones abiertas. Renombrar no
--    recalcula la recompensa (RF-112: set_task_reward es solo al insertar).
--    Borrar quita también sus subtareas y su asignación a sesiones de
--    Mazmorra; si ya tiene ciclos jugados, no se borra (task_in_use).
--    Lo completado no se borra: su historia vive en la Bitácora.
-- 2. rename_habit / delete_habit: borrar quita también sus registros.
-- 3. rename_npc / delete_npc: las misiones del NPC se conservan como
--    misiones sueltas (npc_id = null; la FK es RESTRICT, CLAUDE.md §8).
--
-- security definer: las tablas de registros son de solo lectura para el
-- cliente (003); cada función comprueba que la fila es del usuario.

begin;

-- 1. Misiones -----------------------------------------------------------------------
create or replace function public.rename_task(p_task_id uuid, p_title text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare v_title text := trim(coalesce(p_title, ''));
begin
  if auth.uid() is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  if v_title = '' or length(v_title) > 200 then
    raise exception 'invalid_title' using errcode = '22023';
  end if;
  update public.tasks set title = v_title
  where id = p_task_id and user_id = auth.uid()
    and status in ('pending', 'in_progress', 'delegated');
  if not found then
    raise exception 'task_not_open' using errcode = 'P0002';
  end if;
end $$;

create or replace function public.delete_task(p_task_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  perform 1 from public.tasks
  where id = p_task_id and user_id = auth.uid()
    and status in ('pending', 'in_progress', 'delegated')
  for update;
  if not found then
    raise exception 'task_not_open' using errcode = 'P0002';
  end if;
  if exists (select 1 from public.dungeon_runs r join public.tasks t on t.id = r.task_id
             where t.id = p_task_id or t.parent_task_id = p_task_id) then
    raise exception 'task_in_use' using errcode = 'P0001';
  end if;
  delete from public.focus_session_tasks
  where task_id in (select id from public.tasks where id = p_task_id or parent_task_id = p_task_id);
  delete from public.tasks where parent_task_id = p_task_id;
  delete from public.tasks where id = p_task_id;
end $$;

-- 2. Hábitos --------------------------------------------------------------------------
create or replace function public.rename_habit(p_habit_id uuid, p_name text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare v_name text := trim(coalesce(p_name, ''));
begin
  if auth.uid() is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  if v_name = '' or length(v_name) > 100 then
    raise exception 'invalid_name' using errcode = '22023';
  end if;
  update public.habits set name = v_name where id = p_habit_id and user_id = auth.uid();
  if not found then
    raise exception 'habit_not_found' using errcode = 'P0002';
  end if;
end $$;

create or replace function public.delete_habit(p_habit_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  perform 1 from public.habits where id = p_habit_id and user_id = auth.uid() for update;
  if not found then
    raise exception 'habit_not_found' using errcode = 'P0002';
  end if;
  delete from public.habit_records where habit_id = p_habit_id;
  delete from public.habits where id = p_habit_id;
end $$;

-- 3. NPCs -------------------------------------------------------------------------------
create or replace function public.rename_npc(p_npc_id uuid, p_name text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare v_name text := trim(coalesce(p_name, ''));
begin
  if auth.uid() is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  if v_name = '' or length(v_name) > 60 then
    raise exception 'invalid_name' using errcode = '22023';
  end if;
  update public.npcs set name = v_name where id = p_npc_id and user_id = auth.uid();
  if not found then
    raise exception 'npc_not_found' using errcode = 'P0002';
  end if;
end $$;

create or replace function public.delete_npc(p_npc_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  perform 1 from public.npcs where id = p_npc_id and user_id = auth.uid() for update;
  if not found then
    raise exception 'npc_not_found' using errcode = 'P0002';
  end if;
  update public.tasks set npc_id = null where npc_id = p_npc_id;
  update public.resources set npc_id = null where npc_id = p_npc_id;
  delete from public.npcs where id = p_npc_id;
end $$;

-- Permisos ---------------------------------------------------------------------
do $$
declare f text;
begin
  foreach f in array array['public.rename_task(uuid, text)', 'public.delete_task(uuid)',
    'public.rename_habit(uuid, text)', 'public.delete_habit(uuid)',
    'public.rename_npc(uuid, text)', 'public.delete_npc(uuid)'] loop
    execute format('revoke all on function %s from public, anon', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;

commit;
