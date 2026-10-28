-- Migración 019 · Taverna: NPCs y sus misiones (requiere 001–018).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- 1. tavern_overview(): NPCs con su skill, su misión abierta y cuándo vuelve
--    a ser gratis pedirle otra; límite de NPCs (3 + Estandarte) y skills.
-- 2. create_npc: nombre, skill obligatoria (CLAUDE.md §6), frecuencia y
--    noble misión. El límite lo aplica el trigger de 006.
-- 3. accept_npc_mission: cobra el atajo con request_npc_mission (006) y crea
--    la misión como una tarea real (source = 'npc'). Se completa con
--    complete_task, que ya paga como 'npc'.
--
-- shortcut: RPGenie v1 no redacta la misión; el usuario la escribe partiendo
-- de la noble misión del NPC. Generarla cuando exista RPGenie avanzado.

begin;

-- 1. Datos de la Taverna ---------------------------------------------------------
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
          select jsonb_build_object('id', t.id, 'title', t.title, 'xp_reward', t.xp_reward)
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

-- 2. Crear NPC ------------------------------------------------------------------
-- security invoker: el insert pasa por el RLS y los grants de columna de 003.
create or replace function public.create_npc(
  p_name text,
  p_skill_id uuid,
  p_frequency public.npc_frequency default 'weekly',
  p_noble_mission text default null
)
returns uuid
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_name text := trim(coalesce(p_name, ''));
  v_id uuid;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  if v_name = '' or length(v_name) > 60 then
    raise exception 'invalid_name' using errcode = '22023';
  end if;
  if p_skill_id is null
     or not exists (select 1 from public.skills where id = p_skill_id and user_id = v_uid) then
    raise exception 'skill_not_found' using errcode = 'P0002';
  end if;
  insert into public.npcs (user_id, name, skill_id, frequency, noble_mission)
  values (v_uid, v_name, p_skill_id, coalesce(p_frequency, 'weekly'),
          nullif(left(trim(coalesce(p_noble_mission, '')), 300), ''))
  returning id into v_id;
  return v_id;
end $$;

-- 3. Aceptar misión ----------------------------------------------------------------
-- Una misión abierta por NPC: así el atajo de pago no se acumula.
create or replace function public.accept_npc_mission(p_npc_id uuid, p_title text)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_title text := trim(coalesce(p_title, ''));
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
  select skill_id into v_skill from public.npcs where id = p_npc_id and user_id = v_uid;
  if not found then
    raise exception 'npc_not_found' using errcode = 'P0002';
  end if;
  if exists (select 1 from public.tasks where npc_id = p_npc_id
             and status in ('pending', 'in_progress')) then
    raise exception 'npc_mission_open' using errcode = 'P0001';
  end if;
  v_paid := public.request_npc_mission(p_npc_id);
  insert into public.tasks (user_id, npc_id, skill_id, title, source)
  values (v_uid, p_npc_id, v_skill, v_title, 'npc')
  returning id into v_task;
  return v_paid || jsonb_build_object('task_id', v_task);
end $$;

-- Permisos ---------------------------------------------------------------------
do $$
declare f text;
begin
  foreach f in array array['public.tavern_overview()',
    'public.create_npc(text, uuid, public.npc_frequency, text)',
    'public.accept_npc_mission(uuid, text)'] loop
    execute format('revoke all on function %s from public, anon', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;

commit;
