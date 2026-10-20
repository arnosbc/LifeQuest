-- Migración 007 · Job diario, avisos y vistas (requiere 006).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
-- Plan: docs/plan-cambios-esquema.md §5.4, §5.5, §5.7, pasos 5, 8 y 10.
--
-- 1. daily_maintenance(día): vence plazos (−5 de vida, RF-030), rompe rachas
--    (guarda la racha 48 h para salvarla), +4 de vida si hubo hábito bueno
--    (+1 por nivel del Huerto) o −5 si no se jugó. Corre con pg_cron.
-- 2. Notificaciones anti-estrés: event_key único, categoría, digest y
--    frecuencia decreciente al ignorar 5 seguidas (CLAUDE.md §7).
-- 3. Vistas v_daily_highlight (RF-089) y v_user_store (RF-048).
--
-- ⚠️ pg_cron: actívalo en Supabase → Database → Extensions antes de ejecutar;
-- si no está, la migración crea todo menos la programación (aviso en NOTICE).

begin;

-- 1. Job diario -------------------------------------------------------------------
-- Días ya procesados: la vida diaria se aplica una sola vez por día.
create table if not exists public.daily_runs (
  day date primary key,
  ran_at timestamptz not null default now()
);
alter table public.daily_runs enable row level security;
revoke all on public.daily_runs from authenticated, anon;

-- p_day = el día que terminó (UTC). Se puede repetir para un mismo día sin
-- castigar dos veces: cada plazo vence una sola vez y cada racha se rompe una vez.
-- shortcut: los ajustes diarios de vida no van a la Bitácora (no tienen
-- source_id); sumar una fuente 'daily' si el Diario debe mostrarlos.
create or replace function public.daily_maintenance(p_day date default current_date - 1)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_end timestamptz := (p_day + 1)::timestamptz;
  v_hp integer := public.rule('hp_deadline_missed')::integer;
  v_row record;
  v_expired integer := 0;
  v_broken integer := 0;
begin
  perform set_config('lifequest.internal', 'on', true);

  -- Plazos incumplidos: tarea, proyecto o meta (mismo valor, RF-030).
  for v_row in
    update public.tasks set status = 'expired'
    where status in ('pending', 'in_progress') and parent_task_id is null
      and due_date is not null and due_date < v_end
    returning id, user_id, skill_id, 'task'::public.quest_source as src
  loop
    perform public._award(v_row.user_id, v_row.src, v_row.id, 0, 0, v_row.skill_id, 'failed',
      -round(v_hp * public._hp_multiplier(v_row.user_id))::integer);
    v_expired := v_expired + 1;
  end loop;
  for v_row in
    update public.projects set status = 'expired'
    where status in ('not_started', 'in_progress') and archived_at is null
      and end_date is not null and end_date <= p_day
    returning id, user_id, skill_id
  loop
    perform public._award(v_row.user_id, 'project', v_row.id, 0, 0, v_row.skill_id, 'failed',
      -round(v_hp * public._hp_multiplier(v_row.user_id))::integer);
    v_expired := v_expired + 1;
  end loop;
  -- «El jefe escapó… por ahora»: se conserva la XP de cada golpe.
  for v_row in
    update public.goals set status = 'expired'
    where status in ('not_started', 'in_progress') and archived_at is null
      and due_date is not null and due_date <= p_day
    returning id, user_id, skill_id
  loop
    perform public._award(v_row.user_id, 'goal', v_row.id, 0, 0, v_row.skill_id, 'failed',
      -round(v_hp * public._hp_multiplier(v_row.user_id))::integer);
    v_expired := v_expired + 1;
  end loop;

  -- Rachas: las que caducaron su ventana de 48 h se olvidan.
  update public.habits set broken_streak = 0, broken_on = null
  where broken_on is not null
    and (broken_on + 1)::timestamptz
        + make_interval(hours => public.rule('streak_recovery_hours')::integer) <= v_end;

  -- Rachas rotas hoy: hábito bueno programado en p_day sin registro.
  update public.habits h
  set broken_streak = h.current_streak, broken_on = p_day, current_streak = 0
  where h.type = 'good' and h.current_streak > 0
    and (h.frequency = 'daily' or extract(dow from p_day)::int = any (h.specific_days))
    and h.created_at < v_end
    and not exists (select 1 from public.habit_records r
                    where r.habit_id = h.id and r.completed_on = p_day);
  get diagnostics v_broken = row_count;

  -- Vida del día: +4 (+Huerto) con un hábito bueno; −5 si no hubo actividad.
  update public.character_stats s
  set hp_current = least(s.hp_max, greatest(0, s.hp_current + d.delta)), updated_at = now()
  from (
    select p.id as user_id,
      case
        when exists (select 1 from public.habit_records r join public.habits h on h.id = r.habit_id
                     where r.user_id = p.id and r.completed_on = p_day
                       and h.type = 'good' and not r.recovered)
        then (public.rule('hp_daily_good_habit') + public.rule('hp_huerto_per_level')
              * coalesce((select level from public.refuge_upgrades
                          where user_id = p.id and building = 'huerto'), 0))::integer
        when not exists (select 1 from public.quest_log_entries q
                         where q.user_id = p.id and q.result = 'completed'
                           and q.occurred_at >= p_day::timestamptz and q.occurred_at < v_end)
        then -round(public.rule('hp_idle_day') * public._hp_multiplier(p.id))::integer
        else 0
      end as delta
    from public.profiles p
    where p.created_at < p_day::timestamptz
  ) d
  where s.user_id = d.user_id and d.delta <> 0
    -- Una sola vez por día (daily_runs).
    and not exists (select 1 from public.daily_runs dr where dr.day = p_day);

  insert into public.daily_runs (day) values (p_day) on conflict (day) do nothing;
  return jsonb_build_object('day', p_day, 'expired', v_expired, 'streaks_broken', v_broken);
end $$;

revoke all on function public.daily_maintenance(date) from public, anon, authenticated;

do $$
begin
  begin
    create extension if not exists pg_cron;
  exception when others then
    raise notice 'pg_cron no disponible: programa daily_maintenance() a mano (%).', sqlerrm;
  end;
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    perform cron.unschedule(jobid) from cron.job where jobname = 'lifequest_daily';
    perform cron.schedule('lifequest_daily', '5 0 * * *', 'select public.daily_maintenance()');
  end if;
end $$;

-- 2. Notificaciones ------------------------------------------------------------
do $$ begin
  create type public.digest_slot as enum ('morning', 'evening');
exception when duplicate_object then null; end $$;

alter table public.notifications
  add column if not exists event_key text,
  add column if not exists category text,
  add column if not exists digest_slot public.digest_slot;
-- Nunca notificar dos veces el mismo evento: <categoría>:<entidad_id>:<fecha>.
create unique index if not exists notifications_event_key_key
  on public.notifications (user_id, event_key) where event_key is not null;

alter table public.game_master_settings
  add column if not exists critical_bypass_silence boolean not null default false,
  add column if not exists digest_time time;
grant update (critical_bypass_silence, digest_time) on public.game_master_settings to authenticated;

create table if not exists public.notification_category_state (
  user_id uuid not null references public.profiles (id) on delete cascade,
  category text not null,
  consecutive_ignored integer not null default 0,
  reduced boolean not null default false,
  updated_at timestamptz not null default now(),
  primary key (user_id, category)
);
alter table public.notification_category_state enable row level security;
drop policy if exists "read own rows" on public.notification_category_state;
create policy "read own rows" on public.notification_category_state
  for select using (auth.uid() = user_id);

create or replace function public.track_notification_ignored()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare v_threshold integer;
begin
  if new.category is null then
    return new;
  end if;
  select ignore_threshold into v_threshold from public.game_master_settings where user_id = new.user_id;
  if new.ignored and not old.ignored then
    insert into public.notification_category_state as s (user_id, category, consecutive_ignored)
    values (new.user_id, new.category, 1)
    on conflict (user_id, category) do update
    set consecutive_ignored = s.consecutive_ignored + 1,
        reduced = s.consecutive_ignored + 1 >= coalesce(v_threshold, 5),
        updated_at = now();
  elsif new.read_at is not null and old.read_at is null then
    update public.notification_category_state
    set consecutive_ignored = 0, reduced = false, updated_at = now()
    where user_id = new.user_id and category = new.category;
  end if;
  return new;
end $$;
drop trigger if exists trg_track_notification_ignored on public.notifications;
create trigger trg_track_notification_ignored after update of ignored, read_at on public.notifications
  for each row execute function public.track_notification_ignored();

-- 3. Vistas ------------------------------------------------------------------------
create or replace view public.v_daily_highlight with (security_invoker = true) as
select t.id, t.user_id, t.title, t.priority, t.due_date, t.status, t.xp_reward, t.coin_reward,
  case
    when t.status = 'delegated' then 'pending'
    when t.due_date is not null and t.due_date < now() + interval '24 hours' then 'urgent'
    else t.priority::text
  end as bucket,
  case
    when t.status = 'delegated' then 5
    when t.due_date is not null and t.due_date < now() + interval '24 hours' then 1
    when t.priority = 'high' then 2
    when t.priority = 'medium' then 3
    else 4
  end as bucket_order
from public.tasks t
where t.parent_task_id is null and t.status in ('pending', 'in_progress', 'delegated');

create table if not exists public.user_market_selection (
  user_id uuid not null references public.profiles (id) on delete cascade,
  market_item_id uuid not null references public.market_items (id) on delete cascade,
  primary key (user_id, market_item_id)
);
alter table public.user_market_selection enable row level security;
drop policy if exists "own rows" on public.user_market_selection;
create policy "own rows" on public.user_market_selection
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Sin selección se ve todo el catálogo; con selección, solo lo elegido (RF-048).
create or replace view public.v_user_store with (security_invoker = true) as
select m.id, m.code, m.category, m.name, m.description, m.coin_cost, m.hp_restore,
       m.daily_limit, m.active_limit
from public.market_items m
where m.is_active
  and (not exists (select 1 from public.user_market_selection s where s.user_id = auth.uid())
       or exists (select 1 from public.user_market_selection s
                  where s.user_id = auth.uid() and s.market_item_id = m.id));

grant select on public.v_daily_highlight, public.v_user_store to authenticated;

commit;
