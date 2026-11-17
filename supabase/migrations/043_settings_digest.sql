-- Migración 043 · Resumen diario en Ajustes (requiere 001–042).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- settings_overview (016) devuelve además digest_time (HH:MI), la hora del
-- resumen de avisos informativos que entrega device_notifications (036). El
-- usuario ya podía escribirla (grant de 007). Resto: misma copia de 016.

begin;

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
