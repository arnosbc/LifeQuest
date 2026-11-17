-- Migración 061 · Resumen semanal de Nevi (requiere 056 y 060).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- Cada domingo a las 19:00 de Colombia (cron lunes 00:00 UTC) Nevi manda un
-- aviso con la semana (lunes a hoy): XP, días con actividad, tareas y racha,
-- comparando la XP con la semana pasada. Solo a quien tuvo actividad en las
-- últimas 2 semanas: a quien dejó la app no se le insiste (§9).

begin;

create or replace function public._weekly_summary()
returns integer
language plpgsql
security definer
set search_path = ''
set timezone to 'America/Bogota'
as $$
declare
  -- shortcut: semana y desfase de Colombia (049), app de un solo país.
  v_today date := now()::date;
  v_start date := date_trunc('week', now())::date;  -- lunes
  u record;
  v_streak integer;
  v_title text;
  v_message text;
  v_sent integer := 0;
begin
  for u in
    select q.user_id,
           coalesce(sum(q.xp_awarded) filter (where q.occurred_at >= v_start::timestamptz), 0)::int xp,
           coalesce(sum(q.xp_awarded) filter (where q.occurred_at < v_start::timestamptz), 0)::int xp_prev,
           count(distinct q.occurred_at::date) filter (
             where q.occurred_at >= v_start::timestamptz and q.result = 'completed'
               and q.source_type::text in ('task', 'npc', 'habit', 'dungeon', 'task_step', 'project', 'goal')
           )::int days,
           count(*) filter (
             where q.occurred_at >= v_start::timestamptz and q.result = 'completed'
               and q.source_type::text in ('task', 'npc')
           )::int tasks
    from public.quest_log_entries q
    where q.occurred_at >= (v_start - 7)::timestamptz
    group by q.user_id
  loop
    v_streak := public._activity_streak(u.user_id, v_today, -300);
    if u.days = 0 then
      v_title := 'Nevi: una semana tranquila 🌙';
      v_message := 'Esta semana descansamos. Mañana empieza otra: te espero con algo pequeño.';
    else
      v_title := 'Nevi: tu semana en LifeQuest 📊';
      v_message := u.xp || ' XP, ' || u.days || ' de 7 días con actividad y '
        || u.tasks || case when u.tasks = 1 then ' tarea' else ' tareas' end || '.'
        || case when u.xp > u.xp_prev and u.xp_prev > 0
                  then ' ¡' || (u.xp - u.xp_prev) || ' XP más que la semana pasada!'
                else '' end
        || case when v_streak > 0
                  then ' Tu racha va en ' || v_streak
                       || case when v_streak = 1 then ' día' else ' días' end || ' 🔥.'
                else '' end
        || ' ¡Vamos por otra semana!';
    end if;
    insert into public.notifications (user_id, type, category, event_key, title, message, sent_at)
    values (u.user_id, 'motivational', 'weekly', 'weekly:' || v_start, v_title, v_message, now())
    on conflict (user_id, event_key) where event_key is not null do nothing;
    v_sent := v_sent + 1;
  end loop;
  return v_sent;
end $$;

revoke all on function public._weekly_summary() from public, anon, authenticated;

-- Lunes 00:00 UTC = domingo 19:00 en Colombia; el reloj de push lo entrega en ≤ 5 min.
do $$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    perform cron.unschedule(jobid) from cron.job where jobname = 'lifequest_weekly';
    perform cron.schedule('lifequest_weekly', '0 0 * * 1', 'select public._weekly_summary()');
  else
    raise notice 'Activa pg_cron (Database → Extensions) y vuelve a ejecutar esta migración.';
  end if;
end $$;

commit;
