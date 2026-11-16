-- Migración 071 · Hora para cada hábito con su aviso (requiere 051 y 058).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- Mejora 1 del plan del usuario (2026-11-16): «Leer después de cenar a las
-- 8 p. m.» (intención de implementación). La persona elige una hora por
-- hábito y, si a esa hora aún no lo cumplió, Nevi le avisa una vez.
-- 1. habits.reminder_time (hora local de Colombia, null = sin hora).
-- 2. set_habit_time(): la pone o la quita (solo el dueño, solo hábitos buenos).
-- 3. _habit_time_reminders(): aviso crítico «Nevi: es hora de …» dentro de la
--    hora siguiente a la elegida (el cron de push corre cada 5 min, 054).
-- 4. _generate_reminders (058) pasa a llamarse _generate_daily_reminders y la
--    nueva _generate_reminders llama a las dos: los 5 recordatorios del día y
--    los de cada hábito. Quien la llamaba (050) no cambia.
-- 5. habits_overview (cuerpo de 051) devuelve reminder_time.

begin;

-- 1. Hora del hábito ----------------------------------------------------------
alter table public.habits add column if not exists reminder_time time;

-- 2. Poner o quitar la hora ----------------------------------------------------
create or replace function public.set_habit_time(p_habit_id uuid, p_time time)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  update public.habits set reminder_time = p_time
  where id = p_habit_id and user_id = auth.uid() and type = 'good';
  if not found then
    raise exception 'habit_not_found' using errcode = 'P0002';
  end if;
end $$;
revoke all on function public.set_habit_time(uuid, time) from public, anon;
grant execute on function public.set_habit_time(uuid, time) to authenticated;

-- 3. Aviso a la hora de cada hábito ----------------------------------------------
create or replace function public._habit_time_reminders(p_uid uuid, p_day date, p_time time)
returns void
language sql
security definer
set search_path = ''
set timezone to 'America/Bogota'
as $$
  insert into public.notifications (user_id, type, category, event_key, title, message, sent_at)
  select p_uid, 'critical', 'habit_time',
         'habit_time:' || h.id || ':' || p_day,
         'Nevi: es hora de «' || left(h.name, 60) || '» ⏰',
         'Lo planeaste para las ' || to_char(h.reminder_time, 'FMHH12:MI') ||
           case when h.reminder_time < time '12:00' then ' a. m.' else ' p. m.' end ||
           '. Hazlo ahora y suma a tu racha.',
         now()
  from public.habits h
  where h.user_id = p_uid and h.type = 'good' and h.reminder_time is not null
    and p_time >= h.reminder_time and p_time - h.reminder_time < interval '1 hour'
    and (h.frequency = 'daily' or extract(dow from p_day)::int = any (h.specific_days))
    and not exists (select 1 from public.habit_records r
                    where r.habit_id = h.id and r.completed_on = p_day)
  on conflict (user_id, event_key) where event_key is not null do nothing;
$$;
revoke all on function public._habit_time_reminders(uuid, date, time) from public, anon, authenticated;

-- 4. Los recordatorios del día y los de cada hábito -------------------------------
do $$
begin
  if to_regprocedure('public._generate_daily_reminders(uuid, date, time)') is null then
    alter function public._generate_reminders(uuid, date, time)
      rename to _generate_daily_reminders;
  end if;
end $$;

create or replace function public._generate_reminders(p_uid uuid, p_day date, p_time time)
returns void
language plpgsql
security definer
set search_path = ''
set timezone to 'America/Bogota'
as $$
begin
  -- Primero el del hábito: así el «hace poco llegó otro aviso» (048) no lo tapa.
  perform public._habit_time_reminders(p_uid, p_day, p_time);
  perform public._generate_daily_reminders(p_uid, p_day, p_time);
end $$;
revoke all on function public._generate_reminders(uuid, date, time) from public, anon, authenticated;

-- 5. habits_overview con la hora (cuerpo de 051) -----------------------------------
create or replace function public.habits_overview(p_day date)
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  with week as (
    select generate_series(p_day - 6, p_day, interval '1 day')::date as day
  ),
  h as (
    select h.*,
           h.frequency = 'daily' or extract(dow from p_day)::int = any (h.specific_days) as scheduled_today
    from public.habits h
  ),
  -- Días de la semana en que tocaba cada hábito bueno (desde que existe).
  scheduled as (
    select h.id, w.day
    from h cross join week w
    where h.type = 'good' and w.day >= h.created_at::date
      and (h.frequency = 'daily' or extract(dow from w.day)::int = any (h.specific_days))
  )
  select jsonb_build_object(
    'habits', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', h.id,
        'name', h.name,
        'priority', h.priority,
        -- 071: hora elegida para el hábito (hora local, «HH:MM» o null).
        'reminder_time', to_char(h.reminder_time, 'HH24:MI'),
        'type', h.type,
        'frequency', h.frequency,
        'specific_days', coalesce(to_jsonb(h.specific_days), '[]'::jsonb),
        'skill_name', s.name,
        'hp_penalty', h.hp_penalty,
        'current_streak', coalesce(h.current_streak, 0),
        'best_streak', coalesce(h.best_streak, 0),
        'scheduled_today', h.scheduled_today,
        'done_today', exists (select 1 from public.habit_records r
                              where r.habit_id = h.id and r.completed_on = p_day),
        'today_count', (select count(*) from public.habit_records r
                        where r.habit_id = h.id and r.completed_on = p_day),
        'week', (select jsonb_agg(exists (select 1 from public.habit_records r
                                          where r.habit_id = h.id and r.completed_on = w.day)
                                  order by w.day)
                 from week w)
      ) order by h.type, h.created_at)
      from h left join public.skills s on s.id = h.skill_id
    ), '[]'::jsonb),
    'week_xp', (
      select coalesce(sum(q.xp_awarded), 0) from public.quest_log_entries q
      where q.source_type = 'habit' and q.occurred_at >= (p_day - 6)::timestamptz
    ),
    'week_done', (
      select count(*) from scheduled sc
      where exists (select 1 from public.habit_records r
                    where r.habit_id = sc.id and r.completed_on = sc.day)
    ),
    'week_scheduled', (select count(*) from scheduled),
    'bad_free_days', (
      select count(*) from week w
      where not exists (select 1 from public.habit_records r join h on h.id = r.habit_id
                        where h.type = 'bad' and r.completed_on = w.day)
    ),
    'month_days', coalesce((
      select jsonb_agg(distinct extract(day from r.completed_on)::int)
      from public.habit_records r join h on h.id = r.habit_id
      where h.type = 'good'
        and r.completed_on >= date_trunc('month', p_day)::date and r.completed_on <= p_day
    ), '[]'::jsonb),
    -- 042: Estadísticas de crecimiento y mapa de calor de Habitos.dc.html.
    'month_heat', coalesce((
      select jsonb_object_agg(d, n) from (
        select extract(day from r.completed_on)::int as d, count(*) as n
        from public.habit_records r join h on h.id = r.habit_id
        where h.type = 'good'
          and r.completed_on >= date_trunc('month', p_day)::date and r.completed_on <= p_day
        group by 1) x
    ), '{}'::jsonb),
    'month_done', (
      select count(*) from public.habit_records r join h on h.id = r.habit_id
      where h.type = 'good'
        and r.completed_on >= date_trunc('month', p_day)::date and r.completed_on <= p_day
    ),
    'year_done', (
      select count(*) from public.habit_records r join h on h.id = r.habit_id
      where h.type = 'good'
        and r.completed_on >= date_trunc('year', p_day)::date and r.completed_on <= p_day
    ),
    'skills', coalesce((
      select jsonb_agg(jsonb_build_object('id', id, 'name', name) order by created_at)
      from public.skills
    ), '[]'::jsonb)
  )
$$;
revoke all on function public.habits_overview(date) from public, anon;
grant execute on function public.habits_overview(date) to authenticated;

commit;

notify pgrst, 'reload schema';
