-- Migración 018 · Marketplace: lectura de la Tienda (requiere 001–017).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- market_overview(): bolsa, vida, Hotel y Mercado con su disponibilidad,
-- Mercado negro con su uso del mes, Elixires y Pases guardados, rachas que
-- aún se pueden salvar (48 h) y el Refugio con el precio del siguiente nivel.
-- Comprar sigue siendo purchase, buy_black_market, use_recovery_pass,
-- upgrade_refuge y activate_elixir (006).
--
-- shortcut: el Cofre no se muestra porque aún no hay RPC para abrirlo ni
-- catálogo de premios (plan-cambios-esquema §7); mostrarlo cuando exista.

begin;

-- security invoker: todo se lee con el RLS del usuario.
create or replace function public.market_overview()
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  select jsonb_build_object(
    'coins', coalesce(cs.coins, 0),
    'treasury', coalesce(cs.treasury, 0),
    'hp_current', coalesce(cs.hp_current, 100),
    'hp_max', coalesce(cs.hp_max, 100),
    'items', coalesce((
      select jsonb_agg(jsonb_build_object(
        'code', m.code,
        'category', m.category,
        'name', m.name,
        'description', m.description,
        'cost', m.coin_cost,
        'available', not (
          (m.daily_limit is not null and (
            select count(*) from public.purchases p
            where p.market_item_id = m.id
              and p.purchased_at >= current_date and p.purchased_at < current_date + 1
          ) >= m.daily_limit)
          or (m.code = 'elixir' and (
            select count(*) from public.user_consumables c
            where c.kind = 'elixir' and c.status in ('stored', 'active')
          ) >= coalesce(m.active_limit, 1)))
      ) order by m.category, m.coin_cost)
      from public.market_items m
      where m.is_active and m.code is not null and m.code <> 'cofre'
    ), '[]'::jsonb),
    'black_market', coalesce((
      select jsonb_agg(jsonb_build_object(
        'code', b.code,
        'name', b.name,
        'cost', b.coin_cost,
        'available', b.monthly_limit is null or (
          select count(*) from public.black_market_redemptions r
          where r.item_id = b.id and r.redeemed_at >= date_trunc('month', now())
        ) < b.monthly_limit
      ) order by b.coin_cost)
      from public.black_market_items b where b.code is not null
    ), '[]'::jsonb),
    'elixirs_stored', (select count(*) from public.user_consumables
                       where kind = 'elixir' and status = 'stored'),
    'elixir_active', exists (select 1 from public.user_consumables
                             where kind = 'elixir' and status = 'active'),
    'passes', (select count(*) from public.recovery_passes where used_at is null),
    'broken_streaks', coalesce((
      select jsonb_agg(jsonb_build_object(
        'habit_id', h.id,
        'name', h.name,
        'streak', h.broken_streak,
        'deadline', (h.broken_on + 1)::timestamptz
                    + make_interval(hours => public.rule('streak_recovery_hours')::integer)
      ) order by h.broken_on)
      from public.habits h
      where h.broken_on is not null and h.broken_streak > 0
        and now() <= (h.broken_on + 1)::timestamptz
                     + make_interval(hours => public.rule('streak_recovery_hours')::integer)
    ), '[]'::jsonb),
    'refuge', (
      select jsonb_agg(jsonb_build_object(
        'building', b,
        'level', coalesce(u.level, 0),
        'max_level', public.rule('refuge_max_level'),
        'price', case when coalesce(u.level, 0) < public.rule('refuge_max_level')
                      then round(public.rule('refuge_base_price')
                                 * power(public.rule('refuge_growth'), coalesce(u.level, 0))) end
      ) order by b)
      from unnest(enum_range(null::public.refuge_building)) b
      left join public.refuge_upgrades u on u.building = b
    )
  )
  from (select 1) one
  left join public.character_stats cs on true
$$;

revoke all on function public.market_overview() from public, anon;
grant execute on function public.market_overview() to authenticated;

commit;
