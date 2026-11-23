-- Migración 048 · Avisos del día: resumen de la mañana, racha en peligro y límite diario
-- (rework, notificaciones; CLAUDE.md §7). Requiere 001–047. Ejecutar una vez en
-- Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- Questly avisa con notificaciones programadas en el teléfono (sync_reminders, 032/042):
-- no hay push del servidor. Para que el teléfono arme los avisos de los próximos 7 días
-- sin abrir la app, sync_reminders ahora devuelve además:
--   · days: por día local (hoy … hoy+6) cuántas tareas tocan (fecha o bloque ese día),
--     cuántos hábitos buenos tocan y cuántos tienen racha viva (hoy: solo los que aún
--     no se marcaron) con la racha más larga. El teléfono pone a las 8:00 «Tu día» y
--     a las 20:00 «racha en peligro» (crítico). Al marcar un hábito, la app vuelve a
--     sincronizar y el aviso de hoy desaparece.
--   · daily_limit y critical_bypass_silence de Ajustes, que el teléfono aplica.
-- Se envuelve la función (como 046 con day_agenda): no cambia nada de lo anterior.

begin;

do $$
begin
  if to_regprocedure('public.sync_reminders_before_nudges(text)') is null then
    alter function public.sync_reminders(text) rename to sync_reminders_before_nudges;
  end if;
end $$;

create or replace function public.sync_reminders(p_time_zone text)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_base jsonb;
  v_gms public.game_master_settings;
  v_tz text := coalesce(p_time_zone, 'UTC');
  v_today date;
begin
  -- Valida la sesión y guarda la zona horaria (032).
  v_base := public.sync_reminders_before_nudges(p_time_zone);
  select * into v_gms from public.game_master_settings where user_id = auth.uid();
  begin
    v_today := (now() at time zone v_tz)::date;
  exception when others then
    v_tz := 'UTC';
    v_today := current_date;
  end;
  return v_base || jsonb_build_object(
    'daily_limit', v_gms.notification_daily_limit,
    'critical_bypass_silence', coalesce(v_gms.critical_bypass_silence, false),
    'days', (
      with days as (
        select v_today + n as day from generate_series(0, 6) n
      ),
      -- Hábitos buenos que tocan cada día; «done» solo puede ser cierto hoy.
      hd as (
        select d.day, coalesce(h.current_streak, 0) as streak,
               d.day = v_today and exists (
                 select 1 from public.habit_records r
                 where r.habit_id = h.id and r.completed_on = v_today) as done
        from days d
        join public.habits h on h.user_id = auth.uid() and h.type = 'good'
          and (h.frequency = 'daily' or extract(dow from d.day)::int = any (h.specific_days))
      )
      select jsonb_agg(jsonb_build_object(
        'day', d.day,
        'tasks', (
          select count(*) from public.tasks t
          where t.user_id = auth.uid() and t.parent_task_id is null and not t.is_reminder
            and t.status in ('pending', 'in_progress')
            and (coalesce(t.scheduled_at, t.due_date) at time zone v_tz)::date = d.day),
        'habits', (select count(*) from hd where hd.day = d.day and not hd.done),
        'streak_habits', (select count(*) from hd
                          where hd.day = d.day and not hd.done and hd.streak > 0),
        'best_streak', (select coalesce(max(hd.streak), 0) from hd
                        where hd.day = d.day and not hd.done)
      ) order by d.day)
      from days d
    )
  );
end $$;

revoke all on function public.sync_reminders(text) from public, anon;
grant execute on function public.sync_reminders(text) to authenticated;
revoke all on function public.sync_reminders_before_nudges(text) from public, anon;
grant execute on function public.sync_reminders_before_nudges(text) to authenticated;

commit;
