-- Migración 031 · Guía de la misión del NPC (requiere 001–030).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- RPGenie (Edge Function npc-mission) ya no da solo un título: añade una guía
-- con objetivo, pasos o ejercicios concretos y pistas, para quien no domina el
-- tema. La guía se guarda en tasks.description (no hace falta columna nueva).
--
-- 1. accept_npc_mission(p_npc_id, p_title, p_description): la descripción es
--    opcional (máx. 4000 caracteres). Las llamadas con dos argumentos siguen
--    funcionando.
-- 2. tavern_overview: la misión abierta devuelve su descripción.

begin;

-- 1. Aceptar misión con guía -------------------------------------------------------
-- La firma cambia: se borra la de dos argumentos para no dejar dos versiones.
drop function if exists public.accept_npc_mission(uuid, text);

create or replace function public.accept_npc_mission(
  p_npc_id uuid,
  p_title text,
  p_description text default null
)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_title text := trim(coalesce(p_title, ''));
  v_description text := nullif(trim(coalesce(p_description, '')), '');
  v_skill uuid;
  v_paid jsonb;
  v_task uuid;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  if v_title = '' or length(v_title) > 200 then
    raise exception 'invalid_title' using errcode = '22023';
  end if;
  if length(v_description) > 4000 then
    raise exception 'invalid_description' using errcode = '22023';
  end if;
  select skill_id into v_skill from public.npcs where id = p_npc_id and user_id = v_uid;
  if not found then
    raise exception 'npc_not_found' using errcode = 'P0002';
  end if;
  if exists (select 1 from public.tasks where npc_id = p_npc_id
             and status in ('pending', 'in_progress')) then
    raise exception 'npc_mission_open' using errcode = 'P0001';
  end if;
  v_paid := public.request_npc_mission(p_npc_id);
  insert into public.tasks (user_id, npc_id, skill_id, title, description, source)
  values (v_uid, p_npc_id, v_skill, v_title, v_description, 'npc')
  returning id into v_task;
  return v_paid || jsonb_build_object('task_id', v_task);
end $$;

-- 2. Taverna con la guía de la misión abierta ----------------------------------------
create or replace function public.tavern_overview()
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  select jsonb_build_object(
    'npcs', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', n.id,
        'name', n.name,
        'noble_mission', n.noble_mission,
        'frequency', n.frequency,
        'skill_name', s.name,
        'free_at', case when n.last_mission_at is not null
                        then n.last_mission_at
                             + make_interval(hours => public.rule('npc_free_hours')::integer) end,
        'open_mission', (
          select jsonb_build_object('id', t.id, 'title', t.title,
                                    'description', t.description, 'xp_reward', t.xp_reward)
          from public.tasks t
          where t.npc_id = n.id and t.status in ('pending', 'in_progress')
          order by t.created_at desc limit 1),
        'completed', (select count(*) from public.tasks t
                      where t.npc_id = n.id and t.status = 'completed')
      ) order by n.created_at)
      from public.npcs n join public.skills s on s.id = n.skill_id
    ), '[]'::jsonb),
    'npc_limit', public.rule('npc_base_limit') + coalesce((
      select level from public.refuge_upgrades where building = 'estandarte'), 0),
    'instant_cost', public.rule('npc_instant_cost'),
    'coins', coalesce((select coins from public.character_stats), 0),
    'skills', coalesce((
      select jsonb_agg(jsonb_build_object('id', id, 'name', name) order by created_at)
      from public.skills
    ), '[]'::jsonb)
  )
$$;

-- Permisos ---------------------------------------------------------------------
revoke all on function public.accept_npc_mission(uuid, text, text) from public, anon;
grant execute on function public.accept_npc_mission(uuid, text, text) to authenticated;
revoke all on function public.tavern_overview() from public, anon;
grant execute on function public.tavern_overview() to authenticated;

commit;
