-- Migración 001 · Lo que necesita el Home sobre el esquema desplegado
-- (supabase/schema_deployed.sql, v1). Ejecutar una vez en Supabase →
-- SQL Editor. Se puede volver a ejecutar sin romper nada.
--
-- 1. Rachas de hábitos buenos.
-- 2. is_weakened calculado por la base (RF-034).
-- 3. Perfil, estadísticas y Game Master al registrarse.
-- 4. Tablas económicas: el cliente solo lee (CLAUDE.md §8, anti-trampa).
-- 5. RPC complete_habit: registrar un hábito bueno y cobrar la recompensa.
-- 6. RPC home_dashboard: todo el Home en una sola llamada.

begin;

-- 1. Rachas ---------------------------------------------------------------
alter table public.habits
  add column if not exists current_streak integer not null default 0,
  add column if not exists best_streak integer not null default 0;

-- 2. Estado debilitado: HP ≤ 20 % de hp_max (RF-034). Nunca bloquea nada.
do $$
begin
  if not exists (
    select 1 from pg_attribute
    where attrelid = 'public.character_stats'::regclass
      and attname = 'is_weakened' and attgenerated = 's'
  ) then
    alter table public.character_stats drop column if exists is_weakened;
    alter table public.character_stats
      add column is_weakened boolean
      generated always as (hp_current * 5 <= hp_max) stored;
  end if;
end $$;

-- 3. Alta del personaje ---------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, nullif(trim(new.raw_user_meta_data ->> 'username'), ''))
  on conflict (id) do nothing;
  insert into public.character_stats (user_id) values (new.id)
  on conflict (user_id) do nothing;
  insert into public.game_master_settings (user_id) values (new.id)
  on conflict (user_id) do nothing;
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Usuarios que se registraron antes de este trigger.
insert into public.profiles (id, display_name)
select id, nullif(trim(raw_user_meta_data ->> 'username'), '') from auth.users
on conflict (id) do nothing;
insert into public.character_stats (user_id)
select id from public.profiles on conflict (user_id) do nothing;
insert into public.game_master_settings (user_id)
select id from public.profiles on conflict (user_id) do nothing;

-- 4. El cliente ve su oro, pero solo el servidor lo cambia ---------------
drop policy if exists "own rows" on public.character_stats;
drop policy if exists "read own rows" on public.character_stats;
create policy "read own rows" on public.character_stats
  for select using (auth.uid() = user_id);

drop policy if exists "own rows" on public.quest_log_entries;
drop policy if exists "read own rows" on public.quest_log_entries;
create policy "read own rows" on public.quest_log_entries
  for select using (auth.uid() = user_id);

-- Un registro de hábito suma racha y recompensa: solo entra por complete_habit.
drop policy if exists "own rows" on public.habit_records;
drop policy if exists "read own rows" on public.habit_records;
create policy "read own rows" on public.habit_records
  for select using (auth.uid() = user_id);

-- La racha la escribe el servidor; el resto del hábito lo edita su dueño.
revoke update on public.habits from authenticated, anon;
grant update (skill_id, name, type, frequency, specific_days, xp_reward,
              coin_reward, hp_penalty)
  on public.habits to authenticated;

-- 5. Registrar un hábito bueno -------------------------------------------
-- p_day es la fecha local del dispositivo; se acepta hoy ± 1 día (UTC) para
-- cubrir cualquier zona horaria sin permitir rellenar días pasados.
create or replace function public.complete_habit(p_habit_id uuid, p_day date)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_habit public.habits;
  v_prev date;
  v_streak integer;
  v_xp_mult numeric := 1;
  v_coin_mult numeric := 1;
  v_weakened boolean;
  v_xp integer;
  v_coins integer;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  if p_day is null or abs(p_day - current_date) > 1 then
    raise exception 'invalid_day' using errcode = '22023';
  end if;

  -- for update: dos toques simultáneos no cobran dos veces.
  select * into v_habit from public.habits
  where id = p_habit_id and user_id = v_uid
  for update;
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
  if exists (
    select 1 from public.habit_records
    where habit_id = p_habit_id and completed_on = p_day
  ) then
    raise exception 'already_completed' using errcode = '23505';
  end if;

  -- La racha sigue si se cumplió el día programado anterior.
  v_prev := p_day - 1;
  if v_habit.frequency = 'specific_days' then
    while not (extract(dow from v_prev)::int = any (v_habit.specific_days))
          and v_prev > p_day - 7 loop
      v_prev := v_prev - 1;
    end loop;
  end if;
  v_streak := case
    when exists (
      select 1 from public.habit_records
      where habit_id = p_habit_id and completed_on = v_prev
    ) then v_habit.current_streak + 1
    else 1
  end;

  select dl.xp_multiplier, dl.coin_multiplier
  into v_xp_mult, v_coin_mult
  from public.game_master_settings g
  join public.difficulty_levels dl on dl.level = g.difficulty
  where g.user_id = v_uid;
  v_xp_mult := coalesce(v_xp_mult, 1);
  v_coin_mult := coalesce(v_coin_mult, 1);

  insert into public.character_stats (user_id) values (v_uid)
  on conflict (user_id) do nothing;
  select is_weakened into v_weakened from public.character_stats
  where user_id = v_uid
  for update;

  -- shortcut: xp_reward/coin_reward del hábito los fija el cliente al
  -- crearlo; pasarlos a valores del servidor al cerrar la economía (§11).
  v_xp := floor(v_habit.xp_reward * v_xp_mult
                * case when v_weakened then 0.9 else 1 end);
  v_coins := floor(v_habit.coin_reward * v_coin_mult
                   * case when v_weakened then 0.9 else 1 end);

  insert into public.habit_records (habit_id, user_id, completed_on)
  values (p_habit_id, v_uid, p_day);

  update public.habits
  set current_streak = v_streak,
      best_streak = greatest(best_streak, v_streak)
  where id = p_habit_id;

  -- shortcut: al subir de nivel xp_to_next_level no cambia; la curva de
  -- niveles es una decisión abierta (CLAUDE.md §11).
  update public.character_stats
  set current_xp = (current_xp + v_xp) % xp_to_next_level,
      level = level + (current_xp + v_xp) / xp_to_next_level,
      coins = coins + v_coins,
      updated_at = now()
  where user_id = v_uid;

  if v_habit.skill_id is not null then
    update public.skills
    set current_xp = (current_xp + v_xp) % xp_to_next_level,
        level = level + (current_xp + v_xp) / xp_to_next_level
    where id = v_habit.skill_id and user_id = v_uid;
  end if;

  insert into public.quest_log_entries
    (user_id, source_type, source_id, result, xp_awarded, coin_awarded)
  values (v_uid, 'habit', p_habit_id, 'completed', v_xp, v_coins);
end $$;

revoke all on function public.complete_habit(uuid, date) from public, anon;
grant execute on function public.complete_habit(uuid, date) to authenticated;

-- 6. Datos del Home ------------------------------------------------------
-- security invoker: lee con el RLS del usuario. p_day y p_utc_offset_minutes
-- definen "hoy" en la zona horaria del dispositivo.
-- Misión prioritaria (RF-097): crítica (vencida o vence en < 24 h) →
-- urgencia high > medium > low → fecha límite más próxima.
create or replace function public.home_dashboard(
  p_day date,
  p_utc_offset_minutes integer default 0
)
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  with day as (
    select start_at, start_at + interval '1 day' as end_at
    from (
      select (p_day::timestamp - make_interval(mins => p_utc_offset_minutes))
             at time zone 'UTC' as start_at
    ) s
  ),
  today_habits as (
    select h.id, h.name, h.current_streak, h.created_at,
           exists (
             select 1 from public.habit_records r
             where r.habit_id = h.id and r.completed_on = p_day
           ) as done
    from public.habits h
    where h.user_id = auth.uid()
      and h.type = 'good'
      and (h.frequency = 'daily'
           or extract(dow from p_day)::int = any (h.specific_days))
  )
  select jsonb_build_object(
    'display_name', p.display_name,
    'character_class', p.character_class,
    'level', s.level,
    'current_xp', s.current_xp,
    'xp_to_next_level', s.xp_to_next_level,
    'coins', s.coins,
    'hp_current', s.hp_current,
    'hp_max', s.hp_max,
    'is_weakened', s.is_weakened,
    'priority_mission', (
      select jsonb_build_object(
        'id', t.id,
        'title', t.title,
        'due_date', t.due_date,
        'priority', t.priority,
        'xp_reward', t.xp_reward,
        'coin_reward', t.coin_reward
      )
      from public.tasks t
      where t.user_id = auth.uid()
        and t.parent_task_id is null
        and t.status in ('pending', 'in_progress')
      order by coalesce(t.due_date < now() + interval '24 hours', false) desc,
               t.priority desc,
               t.due_date asc nulls last,
               t.created_at
      limit 1
    ),
    'habits', coalesce((
      select jsonb_agg(
        jsonb_build_object('id', id, 'name', name, 'done', done)
        order by created_at
      )
      from today_habits
    ), '[]'::jsonb),
    'habits_done', (select count(*) from today_habits where done),
    'habits_total', (select count(*) from today_habits),
    'streak_days', (select coalesce(max(current_streak), 0) from today_habits),
    'missions_done', (
      select count(*) from public.tasks t, day
      where t.user_id = auth.uid()
        and t.parent_task_id is null
        and t.status = 'completed'
        and t.completed_at >= day.start_at and t.completed_at < day.end_at
    ),
    'missions_total', (
      select count(*) from public.tasks t, day
      where t.user_id = auth.uid()
        and t.parent_task_id is null
        and ((t.status = 'completed'
              and t.completed_at >= day.start_at
              and t.completed_at < day.end_at)
             or (t.status in ('pending', 'in_progress')
                 and t.due_date >= day.start_at
                 and t.due_date < day.end_at))
    ),
    'focus_minutes', (
      select coalesce(sum(least(
        f.total_minutes,
        floor(extract(epoch from coalesce(f.ended_at, now()) - f.started_at)
              / 60)::int
      )), 0)
      from public.focus_sessions f, day
      where f.user_id = auth.uid()
        and f.started_at >= day.start_at and f.started_at < day.end_at
    )
  )
  from public.profiles p
  left join public.character_stats s on s.user_id = p.id
  where p.id = auth.uid()
$$;

revoke all on function public.home_dashboard(date, integer) from public, anon;
grant execute on function public.home_dashboard(date, integer) to authenticated;

commit;
