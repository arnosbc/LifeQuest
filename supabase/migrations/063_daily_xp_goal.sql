-- Migración 063 · Meta diaria de XP (requiere 048 y 052).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- Estilo Duolingo: el jugador elige su meta del día (30, 50 o 100 XP) en
-- Configuración. No es un sistema aparte: es el desafío del día «Gana N XP»
-- (052), que ahora usa la meta de cada quien; el cofre paga lo mismo. Nunca
-- baja de 30 (el valor de game_rules) para no abaratar el cofre.
--   · game_master_settings.daily_xp_goal (30 por defecto, el cliente la escribe).
--   · _challenge_target('xp') lee la meta del usuario de la sesión.
--   · settings_overview la devuelve (copia de 048 con un campo más).
--   · daily_goal(): XP de hoy y la meta, para el anillo del Inicio.

begin;

alter table public.game_master_settings
  add column if not exists daily_xp_goal integer not null default 30;
alter table public.game_master_settings
  drop constraint if exists game_master_settings_daily_xp_goal_check;
alter table public.game_master_settings
  add constraint game_master_settings_daily_xp_goal_check check (daily_xp_goal in (30, 50, 100));
grant update (daily_xp_goal) on public.game_master_settings to authenticated;

-- Llamada desde challenges_overview y claim_challenge, siempre con sesión.
create or replace function public._challenge_target(p_key text)
returns integer
language sql
stable
security definer
set search_path = ''
as $$
  select case
    when p_key = 'xp' then greatest(
      public.rule('challenge_xp_target')::integer,
      coalesce((select daily_xp_goal from public.game_master_settings
                where user_id = auth.uid()), 0))
    else public.rule('challenge_' || p_key || '_target')::integer
  end
$$;

create or replace function public.daily_goal()
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'xp', public._challenge_progress(auth.uid(), 'xp'),
    'goal', public._challenge_target('xp'))
  where auth.uid() is not null
$$;

revoke all on function public.daily_goal() from public, anon;
grant execute on function public.daily_goal() to authenticated;

create or replace function public.settings_overview()
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  select jsonb_build_object(
    'level', s.level,
    'current_xp', s.current_xp,
    'xp_to_next_level', s.xp_to_next_level,
    'difficulty', g.difficulty,
    'notification_daily_limit', g.notification_daily_limit,
    'silence_window_start', to_char(g.silence_window_start, 'HH24:MI'),
    -- 043: hora del resumen diario (null = la de notify_digest_hour).
    'digest_time', to_char(g.digest_time, 'HH24:MI'),
    'silence_window_end', to_char(g.silence_window_end, 'HH24:MI'),
    'critical_bypass_silence', g.critical_bypass_silence,
    -- 048: recordatorios del día (estilo Duolingo).
    'daily_reminders', coalesce(g.daily_reminders, true),
    -- 063: meta diaria de XP (el desafío «Gana N XP»).
    'daily_xp_goal', coalesce(g.daily_xp_goal, 30),
    'short_break_minutes', g.short_break_minutes,
    'long_break_minutes', g.long_break_minutes,
    'long_break_every_n_cycles', g.long_break_every_n_cycles,
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
  left join public.character_stats s on s.user_id = p.id
  left join public.game_master_settings g on g.user_id = p.id
  where p.id = auth.uid()
$$;
revoke all on function public.settings_overview() from public, anon;
grant execute on function public.settings_overview() to authenticated;

commit;

notify pgrst, 'reload schema';
