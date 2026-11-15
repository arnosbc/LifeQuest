-- Migración 060 · El Protector de racha también cuida la racha diaria (requiere 054 y 056).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- Como el «congelar racha» de Duolingo: cada noche (00:10 en Colombia), si
-- ayer no hubo actividad, la racha diaria estaba viva y hay un Protector
-- guardado (recovery_passes sin usar), se gasta solo para proteger ayer
-- (habit_id null, protected_day = ayer) y Nevi lo cuenta en el resumen de la
-- mañana (informativo: nunca despierta a nadie). El día protegido une la
-- racha pero no suma días: la racha cuenta solo días con actividad real.
-- Los protectores son los mismos de los hábitos (use_recovery_pass, 006).

begin;

-- 1. La racha salta los días protegidos ---------------------------------------
create or replace function public._activity_streak(
  p_uid uuid,
  p_day date,
  p_utc_offset_minutes integer default 0
)
returns integer
language sql
stable
-- invoker: lee quest_log_entries y recovery_passes con su RLS.
security invoker
set search_path = ''
as $$
  with days as (
    select d, bool_or(real) as real
    from (
      -- Día local del usuario de cada actividad (mismo desfase que el Inicio).
      select (q.occurred_at at time zone 'UTC'
              + make_interval(mins => p_utc_offset_minutes))::date as d, true as real
      from public.quest_log_entries q
      where q.user_id = p_uid
        and q.result = 'completed'
        and q.source_type::text in ('task', 'npc', 'habit', 'dungeon', 'task_step', 'project', 'goal')
        and q.occurred_at > now() - interval '400 days'
      union all
      -- Días cubiertos por un Protector de la racha diaria (060).
      select r.protected_day, false
      from public.recovery_passes r
      where r.user_id = p_uid and r.habit_id is null and r.protected_day is not null
    ) x
    group by d
  ),
  anchor as (
    select case when exists (select 1 from days where d = p_day) then p_day
                else p_day - 1 end as a
  ),
  ranked as (
    select d, real, row_number() over (order by d desc) as rn
    from days, anchor where d <= anchor.a
  )
  -- Días seguidos hacia atrás desde el ancla; solo suman los de actividad real.
  select (count(*) filter (where real))::int
  from ranked, anchor where ranked.d = anchor.a - (ranked.rn::int - 1)
$$;

-- 2. Gastar un Protector por la noche -------------------------------------------
create or replace function public._protect_daily_streaks()
returns integer
language plpgsql
security definer
set search_path = ''
set timezone to 'America/Bogota'
as $$
declare
  -- shortcut: día y desfase de Colombia (049), app de un solo país.
  v_today date := now()::date;
  v_uid uuid;
  v_streak integer;
  v_pass uuid;
  v_used integer := 0;
begin
  for v_uid in
    select distinct user_id from public.recovery_passes where used_at is null
  loop
    -- Hoy y ayer sin actividad (0) pero la racha seguía viva hasta anteayer.
    if public._activity_streak(v_uid, v_today, -300) > 0 then
      continue;
    end if;
    v_streak := public._activity_streak(v_uid, v_today - 1, -300);
    if v_streak = 0 then
      continue;
    end if;
    select id into v_pass from public.recovery_passes
    where user_id = v_uid and used_at is null
    order by acquired_at limit 1 for update;
    update public.recovery_passes
    set used_at = now(), protected_day = v_today - 1
    where id = v_pass;
    insert into public.notifications (user_id, type, category, event_key, title, message, sent_at)
    values (v_uid, 'informational', 'streak_protector', 'streak_protector:' || (v_today - 1),
            'Nevi: usé un Protector y tu racha sigue viva 🛡️',
            'Ayer no hubo actividad, así que gasté un Protector de racha. Tus '
              || v_streak || case when v_streak = 1 then ' día' else ' días' end
              || ' de racha siguen en pie.',
            now())
    on conflict (user_id, event_key) where event_key is not null do nothing;
    v_used := v_used + 1;
  end loop;
  return v_used;
end $$;

revoke all on function public._protect_daily_streaks() from public, anon, authenticated;

-- 3. Cron: 05:10 UTC = 00:10 en Colombia, después de lifequest_daily (05:05) ----
do $$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    perform cron.unschedule(jobid) from cron.job where jobname = 'lifequest_streak_protector';
    perform cron.schedule('lifequest_streak_protector', '10 5 * * *',
                          'select public._protect_daily_streaks()');
  else
    raise notice 'Activa pg_cron (Database → Extensions) y vuelve a ejecutar esta migración.';
  end if;
end $$;

commit;
