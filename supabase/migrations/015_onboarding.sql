-- Migración 015 · Onboarding de 5 pasos (requiere 001–014).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
-- Spec: specs/003-onboarding/.
--
-- 1. profiles.onboarded_at: fecha en que el jugador terminó o saltó el
--    Onboarding. Solo pasa de null a now(); después no cambia ni se borra.
-- 2. RPC onboarding_overview: si toca mostrarlo y los multiplicadores
--    vigentes de difficulty_levels (no se escriben a mano en la app).
-- 3. RPC complete_onboarding: guarda identidad, primera skill y dificultad
--    de una vez, al terminar o saltar. No da XP ni Monedas.

begin;

-- 1. Marca de Onboarding visto ------------------------------------------------
alter table public.profiles add column if not exists onboarded_at timestamptz;

-- profiles tiene grant update amplio (el Perfil edita la identidad directo):
-- el trigger es quien impide fijar otra fecha o borrar la marca.
create or replace function public.guard_onboarded_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if old.onboarded_at is not null then
    if new.onboarded_at is distinct from old.onboarded_at then
      raise exception 'onboarding_locked' using errcode = '42501';
    end if;
  elsif new.onboarded_at is not null then
    new.onboarded_at := now();
  end if;
  return new;
end $$;

drop trigger if exists trg_guard_onboarded_at on public.profiles;
create trigger trg_guard_onboarded_at before update of onboarded_at on public.profiles
  for each row execute function public.guard_onboarded_at();

-- 2. ¿Toca el Onboarding? -------------------------------------------------------
-- Un jugador con identidad o alguna skill (anterior a esta función) no lo ve.
create or replace function public.onboarding_overview()
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  select jsonb_build_object(
    'pending', p.onboarded_at is null
      and p.identity_statement is null
      and not exists (select 1 from public.skills s where s.user_id = p.id),
    'difficulties', (
      select coalesce(jsonb_agg(jsonb_build_object(
        'level', dl.level,
        'xp_multiplier', dl.xp_multiplier,
        'hp_penalty_multiplier', dl.hp_penalty_multiplier,
        'coin_multiplier', dl.coin_multiplier
      ) order by dl.level), '[]'::jsonb)
      from public.difficulty_levels dl
    )
  )
  from public.profiles p
  where p.id = auth.uid()
$$;

-- 3. Terminar o saltar ------------------------------------------------------------
-- security invoker: valen el RLS, los checks de longitud (002), el límite de
-- skills y el grant de columna de game_master_settings (003).
create or replace function public.complete_onboarding(
  p_identity text,
  p_skill text,
  p_difficulty public.difficulty_level
)
returns void
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_identity text := nullif(trim(p_identity), '');
  v_skill text := nullif(trim(p_skill), '');
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  -- for update: dos dispositivos a la vez no guardan dos veces.
  if (select onboarded_at from public.profiles where id = v_uid for update) is not null then
    raise exception 'onboarding_done' using errcode = '42501';
  end if;

  if v_identity is not null then
    update public.profiles set identity_statement = v_identity where id = v_uid;
  end if;
  if v_skill is not null then
    if exists (select 1 from public.skills
               where user_id = v_uid and lower(trim(name)) = lower(v_skill)) then
      raise exception 'skill_exists' using errcode = '23505';
    end if;
    insert into public.skills (user_id, name) values (v_uid, v_skill);
  end if;
  update public.game_master_settings
    set difficulty = coalesce(p_difficulty, 'normal') where user_id = v_uid;
  update public.profiles set onboarded_at = now() where id = v_uid;
end $$;

-- Permisos -----------------------------------------------------------------------
do $$
declare f text;
begin
  foreach f in array array['public.onboarding_overview()',
    'public.complete_onboarding(text, text, public.difficulty_level)'] loop
    execute format('revoke all on function %s from public, anon', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;

commit;
