-- Migración 062 · Logro de 100 días de racha (requiere 057).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- Hitos de racha: la app celebra los 7, 30, 100 y 365 días con una pantalla
-- especial; los de 7 y 30 ya pagan con sus logros (057). Este agrega «Leyenda»
-- (100 días, premio provisional) y su condición en _unlock_achievements, que
-- es la misma copia de 057 con una línea más.

begin;

insert into public.achievements (code, name, description, reward_coins) values
  ('streak_100', 'Leyenda', 'Logra una racha de 100 días con actividad.', 100)
on conflict (code) do update
  set name = excluded.name, description = excluded.description,
      reward_coins = excluded.reward_coins;

create or replace function public._unlock_achievements(p_uid uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  -- shortcut: día y desfase de Colombia (049), app de un solo país.
  v_day date := (now() at time zone 'America/Bogota')::date;
  v_count integer;
  a record;
  v_ok boolean;
begin
  for a in
    select ac.id, ac.code, ac.name, ac.reward_coins
    from public.achievements ac
    where not exists (select 1 from public.user_achievements ua
                      where ua.user_id = p_uid and ua.achievement_id = ac.id)
  loop
    v_ok := case a.code
      when 'first_task' then exists (
        select 1 from public.quest_log_entries where user_id = p_uid
          and source_type::text in ('task', 'npc') and result = 'completed')
      when 'tasks_10' then (
        select count(*) from public.quest_log_entries where user_id = p_uid
          and source_type::text in ('task', 'npc') and result = 'completed') >= 10
      when 'tasks_50' then (
        select count(*) from public.quest_log_entries where user_id = p_uid
          and source_type::text in ('task', 'npc') and result = 'completed') >= 50
      when 'first_habit' then exists (
        select 1 from public.quest_log_entries where user_id = p_uid
          and source_type::text = 'habit' and result = 'completed')
      when 'streak_3' then public._activity_streak(p_uid, v_day, -300) >= 3
      when 'streak_7' then public._activity_streak(p_uid, v_day, -300) >= 7
      when 'streak_30' then public._activity_streak(p_uid, v_day, -300) >= 30
      when 'streak_100' then public._activity_streak(p_uid, v_day, -300) >= 100
      when 'focus_10' then (
        select count(*) from public.quest_log_entries where user_id = p_uid
          and source_type::text = 'dungeon' and result = 'completed') >= 10
      when 'chests_10' then (
        select count(*) from public.quest_log_entries where user_id = p_uid
          and source_type::text = 'daily_chest') >= 10
      when 'challenges_10' then (
        select count(*) from public.quest_log_entries where user_id = p_uid
          and source_type::text = 'challenge') >= 10
      when 'level_5' then coalesce((
        select level from public.character_stats where user_id = p_uid), 0) >= 5
      when 'league_up' then exists (
        select 1 from public.league_weeks where user_id = p_uid and last_result = 'promoted')
      else false
    end;
    if not v_ok then
      continue;
    end if;
    -- Unicidad (user_id, achievement_id): nunca se cobra dos veces.
    insert into public.user_achievements (user_id, achievement_id)
    values (p_uid, a.id) on conflict do nothing;
    get diagnostics v_count = row_count;
    if v_count = 0 then
      continue;
    end if;
    if a.reward_coins > 0 then
      perform public._award(p_uid, 'achievement', a.id, 0, a.reward_coins);
    end if;
    insert into public.notifications (user_id, type, category, event_key, title, message, sent_at)
    values (p_uid, 'motivational', 'achievement', 'achievement:' || a.id,
            'Nevi: ¡desbloqueaste «' || a.name || '»! 🏅',
            'Ganaste ' || a.reward_coins || ' Monedas. Míralo en Perfil → Logros.', now())
    on conflict (user_id, event_key) where event_key is not null do nothing;
  end loop;
end $$;

revoke all on function public._unlock_achievements(uuid) from public, anon, authenticated;

commit;
