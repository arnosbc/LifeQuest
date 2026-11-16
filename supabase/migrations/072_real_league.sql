-- Migración 072 · Liga con personas reales y premios al top 3 (requiere 052, 057 y 064).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- Decisión del usuario (2026-11-16): en la Liga solo aparecen personas
-- registradas que usan LifeQuest, nada de rivales simulados. Sigue como
-- Duolingo: 10 divisiones, zona de ascenso y de descenso, semana de lunes a
-- domingo (America/Bogota).
--
--   1. Grupo = quienes tienen fila en league_weeks esa semana y en esa
--      división. La fila se crea al abrir Desafíos o con el cron diario de
--      064 para quien tuvo actividad en 14 días: solo entra gente activa.
--      shortcut: un grupo por división, sin tope; con cientos de usuarios
--      partirlo en grupos de 30 (como Duolingo).
--   2. Nombre visible: solo el nombre y la inicial del apellido («Juan G.»),
--      nunca el correo ni el id (privacidad, OWASP M6).
--   3. Al cerrar la semana (_league_current): suben los 3 primeros con XP;
--      bajan los 3 últimos si el grupo tiene 7 o más, y quien hizo 0 XP.
--      Con menos de 2 personas con XP nadie sube ni cobra premio.
--   4. Premios (reglas provisionales en game_rules): 1.º 50 Monedas y un Pase
--      de Recuperación, 2.º 35 Monedas, 3.º 20 Monedas. Se pagan con _award
--      (fuente 'league', fuera de la racha diaria) y Nevi avisa. Caben bajo las
--      50 Monedas completas del día: el cron de 064 (08:00) los paga el lunes.

alter type public.quest_source add value if not exists 'league';

begin;

insert into public.game_rules (key, value, provisional, note) values
  ('league_prize_1', 50, true, 'Monedas del 1.º de la Liga (y un Pase de Recuperación)'),
  ('league_prize_2', 35, true, 'Monedas del 2.º de la Liga'),
  ('league_prize_3', 20, true, 'Monedas del 3.º de la Liga')
on conflict (key) do nothing;

-- Puesto con que cerró la semana anterior (para mostrar el premio).
alter table public.league_weeks add column if not exists last_rank smallint;

drop function if exists public._league_rival(uuid, date, integer, integer);

-- Personas del grupo con su XP de la semana.
create or replace function public._league_players(p_week date, p_division integer)
returns table (user_id uuid, name text, xp integer)
language sql
stable
security definer
set search_path = ''
as $$
  select w.user_id,
         coalesce(nullif(trim(
           split_part(trim(p.display_name), ' ', 1) ||
           case when split_part(trim(p.display_name), ' ', 2) <> ''
                then ' ' || upper(left(split_part(trim(p.display_name), ' ', 2), 1)) || '.'
                else '' end), ''), 'Aventurero'),
         public._league_week_xp(w.user_id, p_week)
  from public.league_weeks w
  join public.profiles p on p.id = w.user_id
  where w.week_start = p_week and w.division = p_division
$$;

-- Puesto (1 = primero) de quien tiene [p_xp]; empate = mismo puesto.
-- Misma firma que en 052 (la usa 064); p_fraction ya no se usa.
create or replace function public._league_rank(
  p_uid uuid, p_week date, p_division integer, p_xp integer, p_fraction numeric)
returns integer
language sql
stable
security definer
set search_path = ''
as $$
  select 1 + count(*)::integer
  from public._league_players(p_week, p_division) g
  where g.user_id <> p_uid and g.xp > p_xp
$$;

-- Fila de esta semana; si falta, cierra la última semana jugada, sube o baja
-- y paga el premio del top 3 una sola vez (solo al crear la fila).
create or replace function public._league_current(p_uid uuid)
returns public.league_weeks
language plpgsql
security definer
set search_path = ''
set timezone to 'America/Bogota'
as $$
declare
  v_week date := date_trunc('week', current_date)::date;
  v_row public.league_weeks;
  v_prev public.league_weeks;
  v_xp integer;
  v_rank integer;
  v_size integer;
  v_active integer;
  v_division integer := 0;
  v_result text;
  v_coins integer;
begin
  select * into v_row from public.league_weeks where user_id = p_uid and week_start = v_week;
  if found then
    return v_row;
  end if;
  select * into v_prev from public.league_weeks
  where user_id = p_uid and week_start < v_week order by week_start desc limit 1;
  if found then
    v_xp := public._league_week_xp(p_uid, v_prev.week_start);
    v_rank := public._league_rank(p_uid, v_prev.week_start, v_prev.division, v_xp, 1);
    select count(*), count(*) filter (where g.xp > 0) into v_size, v_active
    from public._league_players(v_prev.week_start, v_prev.division) g;
    v_division := v_prev.division;
    v_result := 'stayed';
    if v_xp > 0 and v_rank <= 3 and v_active >= 2 and v_division < 9 then
      v_division := v_division + 1;
      v_result := 'promoted';
    elsif v_division > 0 and (v_xp = 0 or (v_size >= 7 and v_rank > v_size - 3)) then
      v_division := v_division - 1;
      v_result := 'demoted';
    end if;
  end if;

  insert into public.league_weeks (user_id, week_start, division, last_result, last_rank)
  values (p_uid, v_week, v_division, v_result, v_rank)
  on conflict (user_id, week_start) do nothing
  returning * into v_row;

  -- Premio: solo quien creó la fila (nunca dos veces) y con rivales reales.
  if v_row.user_id is not null and v_xp > 0 and v_rank <= 3 and v_active >= 2 then
    v_coins := public.rule('league_prize_' || v_rank)::integer;
    perform public._award(p_uid, 'league', gen_random_uuid(), 0, v_coins);
    if v_rank = 1 then
      insert into public.recovery_passes (user_id) values (p_uid);
    end if;
    insert into public.notifications (user_id, type, category, event_key, title, message, sent_at)
    values (p_uid, 'motivational', 'league', 'league:prize:' || v_prev.week_start,
      'Nevi: ¡quedaste #' || v_rank || ' en la Liga! 🏆',
      'Tu premio ya está en tu bolsa: +' || v_coins || ' Monedas'
        || case when v_rank = 1 then ' y un Pase de Recuperación' else '' end
        || '. ¡Gracias por tu constancia!', now())
    on conflict (user_id, event_key) where event_key is not null do nothing;
  end if;

  if v_row.user_id is null then
    select * into v_row from public.league_weeks where user_id = p_uid and week_start = v_week;
  end if;
  return v_row;
end $$;

create or replace function public.challenges_overview()
returns jsonb
language plpgsql
security definer
set search_path = ''
set timezone to 'America/Bogota'
as $$
declare
  v_uid uuid := auth.uid();
  v_league public.league_weeks;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  v_league := public._league_current(v_uid);

  return jsonb_build_object(
    'daily', (
      select jsonb_agg(jsonb_build_object(
        'key', k,
        'progress', public._challenge_progress(v_uid, k),
        'target', public._challenge_target(k),
        'coins', public.rule('challenge_coins'),
        'claimed', public._challenge_claimed(v_uid, k)) order by o)
      from unnest(array['xp', 'tasks', 'focus']) with ordinality as t(k, o)),
    'month', jsonb_build_object(
      'progress', public._challenge_month_points(v_uid),
      'target', public.rule('challenge_month_target'),
      'coins', public.rule('challenge_month_coins'),
      'claimed', public._challenge_claimed(v_uid, 'month'),
      'days_left', (date_trunc('month', current_date) + interval '1 month')::date - current_date),
    'league', jsonb_build_object(
      'division', v_league.division,
      'last_result', v_league.last_result,
      'last_rank', v_league.last_rank,
      'days_left', v_league.week_start + 7 - current_date,
      'xp', public._league_week_xp(v_uid, v_league.week_start),
      'prizes', jsonb_build_array(public.rule('league_prize_1'),
        public.rule('league_prize_2'), public.rule('league_prize_3')),
      -- Las demás personas del grupo (la app agrega «Tú»). Sin ids.
      'rivals', coalesce((
        select jsonb_agg(jsonb_build_object('name', g.name, 'xp', g.xp) order by g.xp desc)
        from public._league_players(v_league.week_start, v_league.division) g
        where g.user_id <> v_uid), '[]'::jsonb))
  );
end $$;

revoke all on function public._league_players(date, integer) from public, anon, authenticated;
revoke all on function public._league_rank(uuid, date, integer, integer, numeric) from public, anon, authenticated;
revoke all on function public._league_current(uuid) from public, anon, authenticated;
revoke all on function public.challenges_overview() from public, anon;
grant execute on function public.challenges_overview() to authenticated;

commit;
