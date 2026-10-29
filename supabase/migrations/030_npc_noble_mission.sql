-- Migración 030 · La noble misión del NPC pasa a ser obligatoria (requiere 001–029).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- La noble misión es el tema que la Edge Function npc-mission envía a la IA
-- para proponer misiones (p. ej. «fundamentos de diseño gráfico»). create_npc
-- la exige; los NPC antiguos sin ella siguen funcionando (la IA usa la skill).

begin;

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
  v_mission text := trim(coalesce(p_noble_mission, ''));
  v_id uuid;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  if v_name = '' or length(v_name) > 60 then
    raise exception 'invalid_name' using errcode = '22023';
  end if;
  if v_mission = '' or length(v_mission) > 300 then
    raise exception 'invalid_noble_mission' using errcode = '22023';
  end if;
  if p_skill_id is null
     or not exists (select 1 from public.skills where id = p_skill_id and user_id = v_uid) then
    raise exception 'skill_not_found' using errcode = 'P0002';
  end if;
  insert into public.npcs (user_id, name, skill_id, frequency, noble_mission)
  values (v_uid, v_name, p_skill_id, coalesce(p_frequency, 'weekly'), v_mission)
  returning id into v_id;
  return v_id;
end $$;

revoke all on function public.create_npc(text, uuid, public.npc_frequency, text) from public, anon;
grant execute on function public.create_npc(text, uuid, public.npc_frequency, text) to authenticated;

commit;
