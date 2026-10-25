-- Migración 009 · Perfil: Tesoro del reino y títulos de prestigio (requiere 001–008).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
-- Spec: specs/004-profile-update/.
--
-- 1. profile_overview: añade el Tesoro, el título activo y los títulos ganados
--    en la misma carga de 002.
-- 2. RPC set_active_title: luce un título ganado o ninguno; el trigger
--    check_active_title de 004 rechaza los no ganados.

begin;

-- 1. Datos del Perfil -------------------------------------------------------
-- Cuerpo de 002 más el Tesoro, el título activo y los ganados (orden de
-- obtención). security invoker: user_titles se lee con su RLS.
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
    'treasury', coalesce(s.treasury, 0),
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
    ), '[]'::jsonb),
    'active_title', (
      select jsonb_build_object('id', t.id, 'name', t.name, 'description', t.description)
      from public.titles t
      where t.id = p.active_title_id
    ),
    'titles', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', t.id,
          'name', t.name,
          'description', t.description,
          'earned_at', ut.earned_at
        )
        order by ut.earned_at
      )
      from public.user_titles ut
      join public.titles t on t.id = ut.title_id
      where ut.user_id = p.id
    ), '[]'::jsonb)
  )
  from public.profiles p
  left join public.character_stats s on s.user_id = p.id
  left join public.game_master_settings g on g.user_id = p.id
  where p.id = auth.uid()
$$;

-- 2. Elegir el título activo --------------------------------------------------
-- null quita el título. El trigger trg_check_active_title (004) rechaza con
-- title_not_earned lo que el jugador no ganó, también un id inexistente.
create or replace function public.set_active_title(p_title_id uuid)
returns void
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  update public.profiles set active_title_id = p_title_id where id = auth.uid();
end $$;

-- Permisos ---------------------------------------------------------------------
do $$
declare f text;
begin
  foreach f in array array['public.profile_overview()', 'public.set_active_title(uuid)'] loop
    execute format('revoke all on function %s from public, anon', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;

commit;
