-- Migración 042 · Aviso antes de que un proyecto pase a 🔴 (rework, RF-021).
-- Requiere 001–041. Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- La urgencia se calcula al leer (_project_urgency, 031) y no hay push del
-- servidor, así que un cambio a 🔴 nunca llegaba fuera de la app. sync_reminders
-- ahora devuelve, para cada proyecto abierto que hoy no está en 🔴, el primer día
-- de los próximos 7 en que lo estaría si no se avanza. El teléfono programa un
-- aviso local ese día; si el usuario avanza, el siguiente sync lo mueve o lo quita.
-- Un aviso por cambio de nivel: cuando ya está en 🔴 deja de salir aquí.

begin;

-- Cuerpo de 032 más 'projects'.
create or replace function public.sync_reminders(p_time_zone text)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_gms public.game_master_settings;
  v_today date;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  update public.game_master_settings set time_zone = p_time_zone
  where user_id = auth.uid() and p_time_zone is not null and time_zone is distinct from p_time_zone;
  select * into v_gms from public.game_master_settings where user_id = auth.uid();
  begin
    v_today := (now() at time zone p_time_zone)::date;
  exception when others then
    v_today := current_date;
  end;
  -- Los avisos de tareas y hábitos no son críticos: la app los salta en la ventana de silencio.
  return jsonb_build_object(
    'silence_start', v_gms.silence_window_start,
    'silence_end', v_gms.silence_window_end,
    'tasks', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', t.id, 'title', t.title, 'scheduled_at', t.scheduled_at,
        'reminder_minutes', t.reminder_minutes) order by t.scheduled_at)
      from public.tasks t
      where t.user_id = auth.uid() and t.reminder_minutes is not null
        and t.status in ('pending', 'in_progress', 'delegated')
        and t.scheduled_at - make_interval(mins => t.reminder_minutes) > now()
        and t.scheduled_at < now() + interval '7 days'
    ), '[]'::jsonb),
    'habits', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', h.id, 'name', h.name, 'reminder_time', h.reminder_time,
        'days', case when h.frequency = 'daily' then '[0,1,2,3,4,5,6]'::jsonb
                     else to_jsonb(coalesce(h.specific_days, '{}')) end) order by h.created_at)
      from public.habits h
      where h.user_id = auth.uid() and h.type = 'good' and h.reminder_time is not null
    ), '[]'::jsonb),
    'projects', coalesce((
      select jsonb_agg(jsonb_build_object('id', x.id, 'title', x.title, 'day', x.day)
                       order by x.day)
      from (
        select p.id, p.title, (
                 -- Sin más avance: ritmo reciente con la ventana de 14 días de ese día.
                 select min(g.d)
                 from (select (v_today + n) as d from generate_series(1, 7) n) g
                 where public._project_urgency(c.total, c.done, c.start_day, p.end_date, g.d,
                         (select count(*)::integer from public.tasks t
                          where t.project_id = p.id and t.parent_task_id is null
                            and t.status = 'completed'
                            and t.completed_at >= (g.d - 13)::timestamptz)) = 'high'
               ) as day
        from public.projects p
        cross join lateral (
          select count(*)::integer as total,
                 (count(*) filter (where t.status = 'completed'))::integer as done,
                 coalesce(p.start_date, p.created_at::date) as start_day,
                 (count(*) filter (where t.status = 'completed'
                    and t.completed_at >= (v_today - 13)::timestamptz))::integer as recent
          from public.tasks t
          where t.project_id = p.id and t.parent_task_id is null
        ) c
        where p.user_id = auth.uid() and p.archived_at is null and p.end_date is not null
          and p.status in ('not_started', 'in_progress')
          and public._project_urgency(c.total, c.done, c.start_day, p.end_date, v_today,
                                      c.recent) <> 'high'
      ) x
      where x.day is not null
    ), '[]'::jsonb)
  );
end $$;

revoke all on function public.sync_reminders(text) from public, anon;
grant execute on function public.sync_reminders(text) to authenticated;

commit;
