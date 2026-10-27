-- Migración 016 · Configuración (Game Master) (requiere 001–015).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- 1. Rangos de game_master_settings: el cliente ya puede escribir estas
--    columnas (grants de 003 y 007); los checks evitan valores sin sentido.
-- 2. RPC settings_overview: nivel y XP del personaje, reglas del jugador y
--    multiplicadores vigentes de difficulty_levels, en una sola carga.
--
-- El guardado es un update directo (RLS + grants de columna): no toca la
-- economía.

begin;

-- 1. Rangos ------------------------------------------------------------------------
-- shortcut: rangos provisionales, no vienen del documento de diseño; ajustar
-- si el equipo fija otros. not valid: no revisa filas antiguas.
alter table public.game_master_settings
  drop constraint if exists game_master_settings_daily_limit_range,
  add constraint game_master_settings_daily_limit_range
    check (notification_daily_limit is null or notification_daily_limit between 1 and 50) not valid,
  -- RF-067: la ventana de silencio va completa o no va.
  drop constraint if exists game_master_settings_silence_pair,
  add constraint game_master_settings_silence_pair
    check ((silence_window_start is null) = (silence_window_end is null)) not valid,
  drop constraint if exists game_master_settings_breaks_range,
  add constraint game_master_settings_breaks_range
    check (short_break_minutes between 1 and 30
       and long_break_minutes between 5 and 60
       and long_break_every_n_cycles between 2 and 8) not valid;

-- 2. Datos de Configuración ---------------------------------------------------------
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
