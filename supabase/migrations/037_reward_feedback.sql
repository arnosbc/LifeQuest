-- Migración 037 · Respuesta de recompensa para el «momento de recompensa» (requiere 001–036).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- Plan: docs/plan-funcionalidades-asistente.md A1–A2 y A5. La app muestra lo
-- que ganó el usuario leyendo esta respuesta; nunca calcula recompensas.
--
-- 1. _award (005) devuelve además el área (skill_name, skill_level y
--    skill_level_up) y la barra de nivel (current_xp, xp_to_next_level). El
--    cálculo no cambia: misma copia de 005 con esos campos añadidos.
-- 2. complete_habit devuelve jsonb (antes void): la respuesta de _award más la
--    racha (streak, best_streak). Cambiar el tipo obliga a borrarla y crearla
--    de nuevo; se vuelven a dar los mismos permisos que en 005.

begin;

-- 1. _award ----------------------------------------------------------------------
create or replace function public._award(
  p_uid uuid,
  p_source public.quest_source,
  p_source_id uuid,Con
  p_xp integer,
  p_coins integer,
  p_skill_id uuid default null,
  p_result public.quest_result default 'completed',
  p_hp integer default 0
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_stats public.character_stats;
  v_xp_mult numeric;
  v_coin_mult numeric;
  v_xp integer;
  v_coins integer;
  v_earned integer;
  v_full integer;
  v_half integer;
  v_cap integer;
  v_wallet integer;
  v_treasury integer;
  v_level integer;
  v_cur integer;
  v_next integer;
  v_skill_name text;
  v_skill_before integer;
  v_skill_after integer;
begin
  insert into public.character_stats (user_id) values (p_uid)
  on conflict (user_id) do nothing;
  select * into v_stats from public.character_stats where user_id = p_uid for update;

  select dl.xp_multiplier, dl.coin_multiplier into v_xp_mult, v_coin_mult
  from public.game_master_settings g
  join public.difficulty_levels dl on dl.level = g.difficulty
  where g.user_id = p_uid;

  v_xp := floor(greatest(p_xp, 0) * coalesce(v_xp_mult, 1)
                * case when v_stats.is_weakened then public.rule('weakened_xp_factor') else 1 end);
  v_coins := floor(greatest(p_coins, 0) * coalesce(v_coin_mult, 1));

  -- Tope suave: las primeras 50 completas, las 50 siguientes a la mitad.
  select coalesce(sum(coin_awarded), 0) into v_earned
  from public.quest_log_entries
  where user_id = p_uid and occurred_at >= current_date and occurred_at < current_date + 1;
  v_full := least(v_coins, greatest(0, public.rule('daily_coins_full') - v_earned));
  v_half := least(
    floor((v_coins - v_full) / 2.0),
    greatest(0, floor(public.rule('daily_coins_half') / 2)
                - greatest(0, v_earned - public.rule('daily_coins_full'))));
  v_coins := v_full + v_half;

  -- Bolsa: 400 + 25 por nivel (máx. 1.000); lo que no cabe va al Tesoro.
  v_cap := least(public.rule('purse_base') + public.rule('purse_per_level') * v_stats.level,
                 public.rule('purse_max'));
  v_wallet := least(v_coins, greatest(0, v_cap - v_stats.coins));
  v_treasury := v_coins - v_wallet;

  v_level := v_stats.level;
  v_cur := v_stats.current_xp + v_xp;
  v_next := v_stats.xp_to_next_level;
  while v_cur >= v_next loop
    v_cur := v_cur - v_next;
    v_level := v_level + 1;
    v_next := public._level_threshold(v_level);
  end loop;

  update public.character_stats
  set level = v_level,
      current_xp = v_cur,
      xp_to_next_level = v_next,
      coins = coins + v_wallet,
      treasury = treasury + v_treasury,
      hp_current = least(hp_max, greatest(0, hp_current + p_hp)),
      last_active_on = current_date,
      updated_at = now()
  where user_id = p_uid;

  select name, level into v_skill_name, v_skill_before
  from public.skills where id = p_skill_id and user_id = p_uid;
  v_skill_after := v_skill_before;

  if p_skill_id is not null and v_xp > 0 then
    update public.skills s
    set current_xp = x.cur, level = x.lvl, xp_to_next_level = x.nxt
    from (
      with recursive up (lvl, cur, nxt) as (
        select level, current_xp + v_xp, xp_to_next_level
        from public.skills where id = p_skill_id and user_id = p_uid
        union all
        select lvl + 1, cur - nxt, public._level_threshold(lvl + 1)
        from up where cur >= nxt
      )
      select lvl, cur, nxt from up order by lvl desc limit 1
    ) x
    where s.id = p_skill_id and s.user_id = p_uid
    returning s.level into v_skill_after;
  end if;

  insert into public.quest_log_entries
    (user_id, source_type, source_id, result, xp_awarded, coin_awarded, hp_change, skill_id)
  values (p_uid, p_source, p_source_id, p_result, v_xp, v_coins, p_hp, p_skill_id);

  return jsonb_build_object(
    'xp', v_xp, 'coins', v_wallet, 'treasury', v_treasury, 'hp_change', p_hp,
    'level', v_level, 'level_up', v_level > v_stats.level,
    'current_xp', v_cur, 'xp_to_next_level', v_next,
    'skill_name', v_skill_name, 'skill_level', v_skill_after,
    'skill_level_up', coalesce(v_skill_after > v_skill_before, false));
end $$;


-- 2. complete_habit --------------------------------------------------------------
drop function if exists public.complete_habit(uuid, date);

create or replace function public.complete_habit(p_habit_id uuid, p_day date)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_habit public.habits;
  v_prev date;
  v_streak integer;
  v_xp integer;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  if p_day is null or abs(p_day - current_date) > 1 then
    raise exception 'invalid_day' using errcode = '22023';
  end if;
  select * into v_habit from public.habits
  where id = p_habit_id and user_id = v_uid for update;
  if not found then
    raise exception 'habit_not_found' using errcode = 'P0002';
  end if;
  if v_habit.type <> 'good' then
    raise exception 'not_a_good_habit' using errcode = '22023';
  end if;
  if v_habit.frequency = 'specific_days'
     and not (extract(dow from p_day)::int = any (v_habit.specific_days)) then
    raise exception 'not_scheduled' using errcode = '22023';
  end if;
  if exists (select 1 from public.habit_records
             where habit_id = p_habit_id and completed_on = p_day) then
    raise exception 'already_completed' using errcode = '23505';
  end if;

  v_prev := p_day - 1;
  if v_habit.frequency = 'specific_days' then
    while not (extract(dow from v_prev)::int = any (v_habit.specific_days))
          and v_prev > p_day - 7 loop
      v_prev := v_prev - 1;
    end loop;
  end if;
  v_streak := case
    when exists (select 1 from public.habit_records
                 where habit_id = p_habit_id and completed_on = v_prev)
    then v_habit.current_streak + 1
    else 1
  end;

  insert into public.habit_records (habit_id, user_id, completed_on)
  values (p_habit_id, v_uid, p_day);
  update public.habits
  set current_streak = v_streak, best_streak = greatest(best_streak, v_streak)
  where id = p_habit_id;

  v_xp := public.rule('habit_good_xp')::integer;
  return public._award(v_uid, 'habit', p_habit_id, v_xp,
    round(v_xp * public.rule('coin_ratio'))::integer, v_habit.skill_id)
    || jsonb_build_object('streak', v_streak,
                          'best_streak', greatest(v_habit.best_streak, v_streak));
end $$;


revoke all on function public._award(uuid, public.quest_source, uuid, integer, integer, uuid, public.quest_result, integer)
  from public, anon, authenticated;
revoke all on function public.complete_habit(uuid, date) from public, anon;
grant execute on function public.complete_habit(uuid, date) to authenticated;

commit;
