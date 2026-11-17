-- Migración 049 · Hora de Colombia en el job diario y en los avisos (requiere 007,
-- 036 y 048). Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- Supabase trabaja en UTC: medianoche UTC son las 19:00 en Colombia. Por eso:
--   · daily_maintenance corría a las 19:05 (hora local): rompía la racha de quien
--     hacía su hábito de noche y contaba el «día» de 19:00 a 19:00.
--   · «Vence hoy» se calculaba hasta las 19:00 locales: una tarea de hoy 23:59 no
--     contaba para los avisos ni los recordatorios.
-- Ahora esas funciones calculan los días en America/Bogota (sin horario de
-- verano, UTC−5) y el job corre a las 00:05 hora local (05:05 UTC).
-- shortcut: zona fija para la app de un solo país; si llega a otros, guardar la
-- zona en profiles y usarla por usuario.

begin;

alter function public.daily_maintenance(date) set timezone to 'America/Bogota';
alter function public._generate_notifications(uuid, date) set timezone to 'America/Bogota';
alter function public._generate_reminders(uuid, date, time) set timezone to 'America/Bogota';
alter function public.device_notifications(text, date, time) set timezone to 'America/Bogota';
alter function public.notifications_overview(date) set timezone to 'America/Bogota';

-- 00:05 en Colombia. El día por defecto (current_date − 1) se calcula al llamar,
-- en UTC: a las 05:05 UTC la fecha UTC ya es la local, así que procesa ayer.
do $$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    perform cron.unschedule(jobid) from cron.job where jobname = 'lifequest_daily';
    perform cron.schedule('lifequest_daily', '5 5 * * *', 'select public.daily_maintenance()');
  else
    raise notice 'pg_cron no está activo: actívalo en Database → Extensions y vuelve a ejecutar esta migración.';
  end if;
end $$;

commit;
