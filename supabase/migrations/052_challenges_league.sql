-- Migración 052 · Desafíos y Liga estilo Duolingo (requiere 004, 005, 008 y 012).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
--   1. Desafíos del día: 3 metas pequeñas (XP, tareas, ciclos de Mazmorra) que se
--      cobran por separado con claim_challenge(key). Cada cobro suma 1 punto al
--      Desafío del mes, que se cobra con claim_challenge('month').
--   2. Liga semanal: el usuario compite por XP de la semana (lunes a domingo)
--      contra 10 rivales SIMULADOS de su división. No hay otros usuarios en la
--      tabla (CLAUDE.md §1: sin ranking social). Top 3 sube, últimos 3 bajan.
--   3. challenges_overview(): todo lo anterior en una llamada.
--
-- Los días y semanas se cuentan en America/Bogota (igual que 049).
-- Valores de la economía: reglas provisionales en game_rules.

alter type public.quest_source add value if not exists 'challenge';

begin;

insert into public.game_rules (key, value, provisional, note) values
  ('challenge_xp_target',    30, true, 'Desafío del día: gana N XP'),
  ('challenge_tasks_target',  2, true, 'Desafío del día: completa N tareas'),
  ('challenge_focus_target',  1, true, 'Desafío del día: N ciclos en la Mazmorra'),
  ('challenge_coins',         5, true, 'Monedas por cada desafío del día'),
  ('challenge_month_target', 30, true, 'Desafíos del día cobrados para el del mes'),
  ('challenge_month_coins',  60, true, 'Monedas del Desafío del mes'),
  ('league_base_xp',         60, true, 'XP semanal típica de un rival en la división 0')
on conflict (key) do nothing;

-- División de cada semana. Solo la escriben las funciones (security definer).
create table if not exists public.league_weeks (
  user_id uuid not null references public.profiles(id) on delete cascade,
  week_start date not null,
  division smallint not null default 0 check (division between 0 and 9),
  -- Resultado de la semana anterior: promoted / demoted / stayed / null.
  last_result text,
  primary key (user_id, week_start)
);
alter table public.league_weeks enable row level security;
drop policy if exists "own rows" on public.league_weeks;
create policy "own rows" on public.league_weeks for select using (user_id = auth.uid());

-- Id estable de cada desafío dentro de quest_log_entries.source_id.
create or replace function public._challenge_id(p_key text)
returns uuid
language sql
immutable
set search_path = ''
as $$ select md5('lifequest-challenge:' || p_key)::uuid $$;

-- Progreso de hoy de un desafío del día (null si la clave no existe).
create or replace function public._challenge_progress(p_uid uuid, p_key text)
returns integer
language sql
stable
security definer
set search_path = ''
set timezone to 'America/Bogota'
as $$
  select case p_key
    when 'xp' then (
      select coalesce(sum(xp_awarded), 0)::integer from public.quest_log_entries
      where user_id = p_uid and occurred_at >= current_date and occurred_at < current_date + 1)
    when 'tasks' then (
      select count(*)::integer from public.quest_log_entries
      where user_id = p_uid and source_type::text in ('task', 'npc') and result = 'completed'
        and occurred_at >= current_date and occurred_at < current_date + 1)
    when 'focus' then (
      select count(*)::integer from public.dungeon_runs r
      join public.focus_sessions s on s.id = r.session_id
      where s.user_id = p_uid and r.completed
        and r.ended_at >= current_date and r.ended_at < current_date + 1)
  end
$$;

create or replace function public._challenge_target(p_key text)
returns integer
language sql
stable
security definer
set search_path = ''
as $$
  select public.rule('challenge_' || p_key || '_target')::integer
$$;

-- Ya cobrado: los del día, hoy; el del mes, este mes.
create or replace function public._challenge_claimed(p_uid uuid, p_key text)
returns boolean
language sql
stable
security definer
set search_path = ''
set timezone to 'America/Bogota'
as $$
  select exists (
    select 1 from public.quest_log_entries
    where user_id = p_uid and source_type::text = 'challenge'
      and source_id = public._challenge_id(p_key)
      and occurred_at >= case when p_key = 'month'
                              then date_trunc('month', current_date)::date
                              else current_date end)
$$;

-- Desafíos del día cobrados este mes (puntos del Desafío del mes).
create or replace function public._challenge_month_points(p_uid uuid)
returns integer
language sql
stable
security definer
set search_path = ''
set timezone to 'America/Bogota'
as $$
  select count(*)::integer from public.quest_log_entries
  where user_id = p_uid and source_type::text = 'challenge'
    and source_id <> public._challenge_id('month')
    and occurred_at >= date_trunc('month', current_date)::date
$$;

create or replace function public.claim_challenge(p_key text)
returns jsonb
language plpgsql
security definer
set search_path = ''
set timezone to 'America/Bogota'
as $$
declare
  v_uid uuid := auth.uid();
  v_progress integer;
  v_target integer;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  if p_key not in ('xp', 'tasks', 'focus', 'month') then
    raise exception 'challenge_not_found' using errcode = 'P0002';
  end if;
  perform pg_advisory_xact_lock(hashtext('challenge:' || v_uid::text));
  if public._challenge_claimed(v_uid, p_key) then
    raise exception 'challenge_already_claimed' using errcode = '23505';
  end if;
  if p_key = 'month' then
    v_progress := public._challenge_month_points(v_uid);
    v_target := public.rule('challenge_month_target')::integer;
  else
    v_progress := public._challenge_progress(v_uid, p_key);
    v_target := public._challenge_target(p_key);
  end if;
  if v_progress < v_target then
    raise exception 'challenge_locked' using errcode = '22023';
  end if;
  return public._award(v_uid, 'challenge', public._challenge_id(p_key), 0,
    public.rule(case when p_key = 'month' then 'challenge_month_coins'
                     else 'challenge_coins' end)::integer);
end $$;

-- XP de un rival al final de la semana y su ritmo (0..1 → cuándo la gana).
-- Determinista por usuario, semana y puesto: la tabla no cambia al recargar.
create or replace function public._league_rival(
  p_uid uuid, p_week date, p_division integer, p_slot integer,
  out name text, out full_xp integer, out pace numeric)
language sql
stable
security definer
set search_path = ''
as $$
  with h as (
    -- bigint: abs() del menor int4 desborda.
    select abs(hashtext(p_uid::text || p_week::text || p_slot)::bigint) as a,
           abs(hashtext(p_slot || p_week::text || p_uid::text)::bigint) as b,
           abs(hashtext(p_uid::text || p_week::text)::bigint) as base
  )
  select
    (array['Aria Luna','Bruno Vega','Camila Sol','Dante Roble','Elena Brisa',
           'Fabio Cruz','Gala Nieve','Hugo Pardo','Iris Monte','Joaquín Mar',
           'Kira Alba','León Duarte','Maya Ríos','Nico Valle','Olivia Paz',
           'Pablo Lago','Quira Flor','Rocío Aire','Saúl Peña','Tania Lince'])
      -- 3 y 20 son coprimos: los puestos 1–10 nunca repiten nombre.
      [1 + (h.base + p_slot * 3) % 20],
    round(public.rule('league_base_xp') * power(1.35, p_division)
          * (0.2 + (h.a % 1000) / 1000.0 * 1.6))::integer,
    0.5 + (h.b % 1000) / 1000.0
  from h
$$;

-- Puesto (1 = primero) del usuario con [p_xp] en una semana terminada o en curso.
create or replace function public._league_rank(
  p_uid uuid, p_week date, p_division integer, p_xp integer, p_fraction numeric)
returns integer
language sql
stable
security definer
set search_path = ''
as $$
  select 1 + count(*)::integer
  from generate_series(1, 10) i,
       lateral public._league_rival(p_uid, p_week, p_division, i) r
  where round(r.full_xp * power(p_fraction, r.pace)) > p_xp
$$;

create or replace function public._league_week_xp(p_uid uuid, p_week date)
returns integer
language sql
stable
security definer
set search_path = ''
set timezone to 'America/Bogota'
as $$
  select coalesce(sum(xp_awarded), 0)::integer from public.quest_log_entries
  where user_id = p_uid and occurred_at >= p_week and occurred_at < p_week + 7
$$;

-- Fila de esta semana; si falta, cierra la última semana jugada y sube o baja.
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
  v_rank integer;
  v_division integer := 0;
  v_result text;
begin
  select * into v_row from public.league_weeks where user_id = p_uid and week_start = v_week;
  if found then
    return v_row;
  end if;
  select * into v_prev from public.league_weeks
  where user_id = p_uid and week_start < v_week order by week_start desc limit 1;
  if found then
    v_rank := public._league_rank(p_uid, v_prev.week_start, v_prev.division,
      public._league_week_xp(p_uid, v_prev.week_start), 1);
    v_division := v_prev.division;
    v_result := 'stayed';
    if v_rank <= 3 and v_division < 9 then
      v_division := v_division + 1;
      v_result := 'promoted';
    elsif v_rank >= 9 and v_division > 0 then
      v_division := v_division - 1;
      v_result := 'demoted';
    end if;
  end if;
  insert into public.league_weeks (user_id, week_start, division, last_result)
  values (p_uid, v_week, v_division, v_result)
  on conflict (user_id, week_start) do nothing;
  select * into v_row from public.league_weeks where user_id = p_uid and week_start = v_week;
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
  v_fraction numeric;
  v_xp integer;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  v_league := public._league_current(v_uid);
  -- Parte de la semana que ya pasó: los rivales avanzan con ella.
  v_fraction := least(1, extract(epoch from (now() - v_league.week_start::timestamptz))
                         / (7 * 86400));
  v_xp := public._league_week_xp(v_uid, v_league.week_start);

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
      'days_left', v_league.week_start + 7 - current_date,
      'xp', v_xp,
      'rivals', (
        select jsonb_agg(jsonb_build_object(
          'name', r.name,
          'xp', round(r.full_xp * power(v_fraction, r.pace))::integer))
        from generate_series(1, 10) i,
             lateral public._league_rival(v_uid, v_league.week_start, v_league.division, i) r))
  );
end $$;

revoke all on function public._challenge_id(text) from public, anon, authenticated;
revoke all on function public._challenge_progress(uuid, text) from public, anon, authenticated;
revoke all on function public._challenge_target(text) from public, anon, authenticated;
revoke all on function public._challenge_claimed(uuid, text) from public, anon, authenticated;
revoke all on function public._challenge_month_points(uuid) from public, anon, authenticated;
revoke all on function public._league_rival(uuid, date, integer, integer) from public, anon, authenticated;
revoke all on function public._league_rank(uuid, date, integer, integer, numeric) from public, anon, authenticated;
revoke all on function public._league_week_xp(uuid, date) from public, anon, authenticated;
revoke all on function public._league_current(uuid) from public, anon, authenticated;
revoke all on function public.claim_challenge(text) from public, anon;
grant execute on function public.claim_challenge(text) to authenticated;
revoke all on function public.challenges_overview() from public, anon;
grant execute on function public.challenges_overview() to authenticated;

commit;
