-- Migración 027 · Cofre del día en el Inicio (requiere 001–026).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- daily_chest_status(): progreso del cofre de hoy con la misma regla de
-- claim_daily_chest (008): misiones (tarea o NPC) que dieron Monedas hoy,
-- cuántas hacen falta, cuántas Monedas da y si ya se reclamó. Cobrar sigue
-- siendo claim_daily_chest.
--
-- shortcut: "hoy" es el día UTC del servidor, igual que claim_daily_chest.

begin;

create or replace function public.daily_chest_status()
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  select jsonb_build_object(
    'progress', (
      select count(*) from public.quest_log_entries
      where source_type::text in ('task', 'npc') and result = 'completed' and coin_awarded > 0
        and occurred_at >= current_date and occurred_at < current_date + 1),
    'required', public.rule('daily_chest_min_missions'),
    'coins', public.rule('daily_chest_coins'),
    'claimed', exists (
      select 1 from public.quest_log_entries
      where source_type::text = 'daily_chest'
        and occurred_at >= current_date and occurred_at < current_date + 1)
  )
$$;

revoke all on function public.daily_chest_status() from public, anon;
grant execute on function public.daily_chest_status() to authenticated;

commit;
