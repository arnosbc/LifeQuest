-- Migración 064 · Avisos de Liga de Nevi (requiere 052).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- Cada día a las 08:00 de Colombia (13:00 UTC), para quien tuvo actividad en
-- las últimas 2 semanas (§9, como 061):
--   · Primera vuelta de la semana (el lunes): cómo cerró la semana pasada
--     (subió, se mantuvo o bajó), con ánimo. _league_current la cierra igual
--     que al abrir la pantalla de Liga.
--   · Miércoles a domingo: si va entre los 3 primeros (zona de ascenso), un
--     aviso por semana. Mismo puesto que muestra challenges_overview.

begin;

drop function if exists public._league_notices();
-- p_today solo para pruebas (el día de la semana); el cron no lo pasa.
create or replace function public._league_notices(p_today date default null)
returns integer
language plpgsql
security definer
set search_path = ''
set timezone to 'America/Bogota'
as $$
declare
  v_today date := coalesce(p_today, current_date);
  v_uid uuid;
  v_league public.league_weeks;
  v_xp integer;
  v_rank integer;
  v_title text;
  v_message text;
  v_key text;
  v_sent integer := 0;
begin
  for v_uid in
    select distinct user_id from public.quest_log_entries
    where occurred_at >= now() - interval '14 days'
  loop
    v_league := public._league_current(v_uid);
    v_title := null;
    v_key := 'league:result:' || v_league.week_start;
    if v_league.last_result is not null and not exists (
         select 1 from public.notifications where user_id = v_uid and event_key = v_key) then
      if v_league.last_result = 'promoted' then
        v_title := 'Nevi: ¡subiste de división! 🏆';
        v_message := 'Quedaste entre los 3 primeros la semana pasada. Nueva liga, nuevos rivales: ¡vamos!';
      elsif v_league.last_result = 'demoted' then
        v_title := 'Nevi: nueva semana, nueva oportunidad 🌱';
        v_message := 'Bajaste una división, y aquí se recupera rápido. Te acompaño.';
      else
        v_title := 'Nevi: sigues en tu división 💪';
        v_message := 'Esta semana vamos por el podio: los 3 primeros suben.';
      end if;
    elsif extract(isodow from v_today) >= 3 and v_league.division < 9 then
      v_xp := public._league_week_xp(v_uid, v_league.week_start);
      v_rank := public._league_rank(v_uid, v_league.week_start, v_league.division, v_xp,
        least(1, extract(epoch from (now() - v_league.week_start::timestamptz)) / (7 * 86400)));
      if v_xp > 0 and v_rank <= 3 then
        v_key := 'league:zone:' || v_league.week_start;
        v_title := 'Nevi: ¡vas #' || v_rank || ' en la Liga! 🏆';
        v_message := 'Si terminas la semana entre los 3 primeros, subes de división. ¡Sigue así!';
      end if;
    end if;
    if v_title is not null then
      insert into public.notifications (user_id, type, category, event_key, title, message, sent_at)
      values (v_uid, 'motivational', 'league', v_key, v_title, v_message, now())
      on conflict (user_id, event_key) where event_key is not null do nothing;
      v_sent := v_sent + 1;
    end if;
  end loop;
  return v_sent;
end $$;

revoke all on function public._league_notices(date) from public, anon, authenticated;

do $$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    perform cron.unschedule(jobid) from cron.job where jobname = 'lifequest_league';
    perform cron.schedule('lifequest_league', '0 13 * * *', 'select public._league_notices()');
  else
    raise notice 'Activa pg_cron (Database → Extensions) y vuelve a ejecutar esta migración.';
  end if;
end $$;

commit;
