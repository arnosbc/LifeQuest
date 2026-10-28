-- Migración 026 · Inventario y logros (requiere 001–025).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- inventory_overview(): pestaña Objetos (Elixires, Cofres, Pases de
-- Recuperación) y pestaña Logros (catálogo visible con lo desbloqueado) y
-- títulos de prestigio ganados (CLAUDE.md §13: se ganan, no se compran).
--
-- shortcut: el catálogo de logros y títulos sigue abierto
-- (plan-cambios-esquema §7); con el catálogo vacío la pestaña Logros solo
-- muestra los títulos. Nada se desbloquea desde aquí.

begin;

create or replace function public.inventory_overview()
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  select jsonb_build_object(
    'elixirs', (select count(*) from public.user_consumables
                where kind = 'elixir' and status = 'stored'),
    'elixir_active', exists (select 1 from public.user_consumables
                             where kind = 'elixir' and status = 'active'),
    'chests', (select count(*) from public.user_consumables
               where kind = 'cofre' and status = 'stored'),
    'passes', (select count(*) from public.recovery_passes where used_at is null),
    'achievements', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', a.id, 'name', a.name, 'description', a.description,
        'reward_coins', a.reward_coins, 'unlocked_at', ua.unlocked_at)
        order by ua.unlocked_at desc nulls last, a.name)
      from public.achievements a
      left join public.user_achievements ua on ua.achievement_id = a.id
      where not a.is_hidden or ua.unlocked_at is not null
    ), '[]'::jsonb),
    'titles', coalesce((
      select jsonb_agg(jsonb_build_object('id', t.id, 'name', t.name,
                                          'description', t.description, 'earned_at', ut.earned_at)
                       order by ut.earned_at desc)
      from public.user_titles ut join public.titles t on t.id = ut.title_id
    ), '[]'::jsonb)
  )
$$;

revoke all on function public.inventory_overview() from public, anon;
grant execute on function public.inventory_overview() to authenticated;

commit;
