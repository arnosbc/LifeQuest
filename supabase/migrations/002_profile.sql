-- Migración 002 · Perfil del Personaje (requiere 001_home.sql).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- 1. Skills: el usuario solo elige el nombre; nivel y XP los sube el servidor.
-- 2. Límite de skills con un motivo claro (CLAUDE.md §6, ampliable).
-- 3. Borrar una skill la quita de metas, proyectos, tareas y hábitos
--    (ON DELETE SET NULL); un NPC la exige, así que ahí se impide.
-- 4. Longitudes válidas de nombre e identidad.
-- 5. RPC profile_overview: todo el Perfil en una sola llamada.

begin;

-- 1. Skills: nivel y XP fuera del alcance del cliente --------------------
revoke insert, update on public.skills from authenticated, anon;
grant insert (user_id, name), update (name) on public.skills to authenticated;

-- 2. Límite de skills -----------------------------------------------------
-- Reemplaza el cuerpo de la función que ya usa trg_enforce_skill_limit.
create or replace function public.enforce_skill_limit()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_limit integer;
begin
  select skill_limit into v_limit
  from public.game_master_settings where user_id = new.user_id;
  -- Bloquea las altas simultáneas del mismo usuario mientras cuenta.
  perform pg_advisory_xact_lock(hashtext('skills:' || new.user_id::text));
  if (select count(*) from public.skills where user_id = new.user_id)
     >= coalesce(v_limit, 6) then
    raise exception 'skill_limit_reached' using errcode = 'P0001';
  end if;
  return new;
end $$;

-- 3. Borrar una skill -------------------------------------------------------
alter table public.goals drop constraint if exists goals_skill_id_fkey,
  add constraint goals_skill_id_fkey foreign key (skill_id)
    references public.skills (id) on delete set null;
alter table public.projects drop constraint if exists projects_skill_id_fkey,
  add constraint projects_skill_id_fkey foreign key (skill_id)
    references public.skills (id) on delete set null;
alter table public.tasks drop constraint if exists tasks_skill_id_fkey,
  add constraint tasks_skill_id_fkey foreign key (skill_id)
    references public.skills (id) on delete set null;
alter table public.habits drop constraint if exists habits_skill_id_fkey,
  add constraint habits_skill_id_fkey foreign key (skill_id)
    references public.skills (id) on delete set null;
alter table public.npcs drop constraint if exists npcs_skill_id_fkey,
  add constraint npcs_skill_id_fkey foreign key (skill_id)
    references public.skills (id) on delete restrict;

-- 4. Longitudes -------------------------------------------------------------
-- not valid: no revisa filas antiguas, pero sí todo lo que se escriba.
alter table public.profiles drop constraint if exists profiles_display_name_length;
alter table public.profiles add constraint profiles_display_name_length
  check (char_length(trim(display_name)) between 1 and 40) not valid;
alter table public.profiles drop constraint if exists profiles_identity_length;
alter table public.profiles add constraint profiles_identity_length
  check (char_length(identity_statement) <= 280) not valid;
alter table public.skills drop constraint if exists skills_name_length;
alter table public.skills add constraint skills_name_length
  check (char_length(trim(name)) between 1 and 40) not valid;

-- El alta (001) recorta el nombre: un registro nunca falla por su longitud.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    nullif(left(trim(new.raw_user_meta_data ->> 'username'), 40), '')
  )
  on conflict (id) do nothing;
  insert into public.character_stats (user_id) values (new.id)
  on conflict (user_id) do nothing;
  insert into public.game_master_settings (user_id) values (new.id)
  on conflict (user_id) do nothing;
  return new;
end $$;

-- 5. Datos del Perfil -------------------------------------------------------
-- security invoker: lee con el RLS del usuario.
-- Tasa de finalización: misiones cumplidas / (cumplidas + falladas) en la
-- bitácora (quest_log_entries).
create or replace function public.profile_overview()
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  select jsonb_build_object(
    'display_name', p.display_name,
    'character_class', p.character_class,
    'identity_statement', p.identity_statement,
    'level', s.level,
    'current_xp', s.current_xp,
    'xp_to_next_level', s.xp_to_next_level,
    'coins', s.coins,
    'hp_current', s.hp_current,
    'hp_max', s.hp_max,
    'is_weakened', s.is_weakened,
    'quests_completed', (
      select count(*) from public.quest_log_entries q
      where q.user_id = p.id and q.result = 'completed'
    ),
    'quests_failed', (
      select count(*) from public.quest_log_entries q
      where q.user_id = p.id and q.result = 'failed'
    ),
    'skill_limit', coalesce(g.skill_limit, 6),
    'skills', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', k.id,
          'name', k.name,
          'level', k.level,
          'current_xp', k.current_xp,
          'xp_to_next_level', k.xp_to_next_level
        )
        order by k.created_at
      )
      from public.skills k
      where k.user_id = p.id
    ), '[]'::jsonb)
  )
  from public.profiles p
  left join public.character_stats s on s.user_id = p.id
  left join public.game_master_settings g on g.user_id = p.id
  where p.id = auth.uid()
$$;

revoke all on function public.profile_overview() from public, anon;
grant execute on function public.profile_overview() to authenticated;

commit;
