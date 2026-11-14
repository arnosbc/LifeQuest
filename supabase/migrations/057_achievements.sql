-- Migración 057 · Logros que se desbloquean solos (requiere 026, 052 y 056).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- 1. Catálogo de 12 logros (achievements, antes vacío). Premios provisionales.
-- 2. _unlock_achievements(uid): revisa las condiciones; si se cumple una, guarda
--    user_achievements, paga con _award('achievement') y deja un aviso de Nevi.
-- 3. Triggers: después de cada fila de quest_log_entries (salvo los pagos de
--    logros, para no entrar en bucle) y al abrir una semana de liga.
-- El cliente no puede escribir user_achievements (003): solo el servidor.

begin;

-- 1. Catálogo -------------------------------------------------------------------
insert into public.achievements (code, name, description, reward_coins) values
  ('first_task',     'Primer paso',          'Completa tu primera tarea.',                 10),
  ('tasks_10',       'Manos a la obra',      'Completa 10 tareas.',                        20),
  ('tasks_50',       'Imparable',            'Completa 50 tareas.',                        50),
  ('first_habit',    'Buen hábito',          'Cumple un hábito por primera vez.',          10),
  ('streak_3',       'Racha encendida',      'Logra una racha de 3 días con actividad.',   15),
  ('streak_7',       'Semana de fuego',      'Logra una racha de 7 días con actividad.',   30),
  ('streak_30',      'Llama eterna',         'Logra una racha de 30 días con actividad.',  60),
  ('focus_10',       'Maestro del foco',     'Termina 10 ciclos en el Modo Foco.',         30),
  ('chests_10',      'Cazador de cofres',    'Abre 10 cofres del día.',                    30),
  ('challenges_10',  'Retador',              'Cumple 10 desafíos del día.',                30),
  ('level_5',        'Aventurero',           'Llega al nivel 5.',                          40),
  ('league_up',      'Ascenso',              'Sube de división en la Liga.',               25)
on conflict (code) do update
  set name = excluded.name, description = excluded.description,
      reward_coins = excluded.reward_coins;

-- 2. Desbloqueo -------------------------------------------------------------------
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

-- 3. Disparadores -------------------------------------------------------------------
create or replace function public._achievements_on_log()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public._unlock_achievements(new.user_id);
  return null;
end $$;

drop trigger if exists trg_achievements_on_log on public.quest_log_entries;
create trigger trg_achievements_on_log
  after insert on public.quest_log_entries
  for each row
  -- Los pagos de logros también son filas: sin esto, un logro revisaría otro sin fin.
  when (new.source_type::text <> 'achievement')
  execute function public._achievements_on_log();

drop trigger if exists trg_achievements_on_league on public.league_weeks;
create trigger trg_achievements_on_league
  after insert on public.league_weeks
  for each row execute function public._achievements_on_log();

revoke all on function public._achievements_on_log() from public, anon, authenticated;

-- 4. Quienes ya jugaban reciben al instante lo que ya habían logrado.
select public._unlock_achievements(id) from public.profiles;

commit;
