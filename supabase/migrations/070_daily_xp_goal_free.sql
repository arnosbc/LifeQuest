-- Migración 070 · Meta diaria de XP libre (requiere 063). Ejecutar una vez en
-- Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- Pedido del usuario (2026-11-16): elegir su propia meta (p. ej. 60), no solo
-- 30, 50 o 100. La meta es un objetivo, nunca un tope de XP. El mínimo sigue
-- en 30 para no abaratar el cofre del desafío «Gana N XP» (063); de 10 en 10
-- hasta 500.

begin;

alter table public.game_master_settings
  drop constraint if exists game_master_settings_daily_xp_goal_check;
alter table public.game_master_settings
  add constraint game_master_settings_daily_xp_goal_check
  check (daily_xp_goal between 30 and 500 and daily_xp_goal % 10 = 0);

commit;

notify pgrst, 'reload schema';
