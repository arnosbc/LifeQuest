-- Migración 050 · Notificaciones push con Firebase (FCM) (requiere 036, 048 y 049).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- Supabase decide qué aviso toca y cuándo (mismas reglas de 036/048); FCM solo
-- lo entrega al teléfono al instante, aunque la app esté cerrada.
--   1. device_registrations.fcm_token: el token FCM de cada teléfono.
--   2. set_push_token(código, token): el teléfono guarda su token FCM.
--   3. _deliver_notifications(uid, día, hora): la entrega de device_notifications,
--      ahora reutilizable. device_notifications (revisión del teléfono cada
--      ~15 min) la sigue usando: queda de respaldo y nunca duplica, porque los
--      dos caminos marcan delivered_at.
--   4. push_dispatch(): para cada usuario con token FCM, entrega lo que toca a
--      la hora de Colombia. Solo service_role (la Edge Function push-dispatch).
--   5. clear_push_token(token): FCM avisa que el token ya no existe.
--   6. pg_cron + pg_net llaman a push-dispatch cada 5 min. La URL del proyecto
--      y la clave del cron se leen del Vault (ver docs al final).

begin;

-- 1. Token FCM ----------------------------------------------------------------
alter table public.device_registrations add column if not exists fcm_token text;
create unique index if not exists device_registrations_fcm_token_idx
  on public.device_registrations (fcm_token) where fcm_token is not null;

-- 2. El teléfono registra su token FCM --------------------------------------
create or replace function public.set_push_token(p_token text, p_fcm_token text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_fcm_token is null or length(p_fcm_token) not between 20 and 4096 then
    raise exception 'invalid_push_token' using errcode = '22023';
  end if;
  -- Un token FCM pertenece a un solo teléfono: si cambió de cuenta, se mueve.
  update public.device_registrations set fcm_token = null
  where fcm_token = p_fcm_token
    and token_hash <> sha256(convert_to(coalesce(p_token, ''), 'UTF8'));
  update public.device_registrations set fcm_token = p_fcm_token, last_seen_at = now()
  where token_hash = sha256(convert_to(coalesce(p_token, ''), 'UTF8'));
  if not found then
    raise exception 'device_not_registered' using errcode = '28000';
  end if;
end $$;

-- 3. Entrega reutilizable -----------------------------------------------------
create or replace function public._deliver_notifications(p_uid uuid, p_day date, p_time time)
returns jsonb
language plpgsql
security definer
set search_path = ''
set timezone to 'America/Bogota'
as $$
declare
  v_uid uuid := p_uid;
  v_now timestamptz := now();
  g public.game_master_settings;
  v_silent boolean;
  v_quiet boolean;
  v_left integer;
  v_count integer;
  v_items jsonb;
  v_digest jsonb;
begin
  -- Frecuencia decreciente: lo entregado y no leído a tiempo cuenta como ignorado.
  update public.notifications set ignored = true
  where user_id = v_uid and type <> 'critical' and not ignored and read_at is null
    and delivered_at < v_now - make_interval(hours => public.rule('notify_ignored_after_hours')::int);

  perform public._generate_notifications(v_uid, p_day);
  -- 048: recordatorios del día a distintas horas.
  perform public._generate_reminders(v_uid, p_day, p_time);

  select * into g from public.game_master_settings where user_id = v_uid;
  v_silent := coalesce(case
    when g.silence_window_start <= g.silence_window_end
      then p_time >= g.silence_window_start and p_time < g.silence_window_end
    else p_time >= g.silence_window_start or p_time < g.silence_window_end end, false);
  v_quiet := v_silent or exists (select 1 from public.focus_sessions
                                 where user_id = v_uid and status in ('active', 'paused'));
  -- Entregas no críticas desde la medianoche local (un digest cuenta 1).
  select coalesce(g.notification_daily_limit - (
           count(*) filter (where digest_slot is null)
           + count(distinct delivered_at) filter (where digest_slot is not null))::int,
         2147483647)
  into v_left
  from public.notifications
  where user_id = v_uid and type <> 'critical'
    and delivered_at >= v_now - (p_time - time '00:00');

  -- ▲ Críticos.
  with sent as (
    update public.notifications n set delivered_at = v_now
    where n.user_id = v_uid and n.delivered_at is null and n.read_at is null
      and n.created_at >= v_now - interval '24 hours' and n.type = 'critical'
      and (not v_silent or coalesce(g.critical_bypass_silence, false))
      and (n.category is distinct from 'streak'
           or p_time >= make_time(public.rule('notify_streak_hour')::int, 0, 0))
    returning n.id, n.type, n.title, n.message, n.created_at)
  select coalesce(jsonb_agg(jsonb_build_object('id', id, 'type', type, 'title', title,
           'message', message, 'created_at', created_at) order by created_at), '[]'::jsonb)
  into v_items from sent;

  -- ● Motivacionales, hasta el límite del día.
  if not v_quiet and v_left > 0 then
    with sent as (
      update public.notifications n set delivered_at = v_now
      where n.id in (select id from public.notifications
                     where user_id = v_uid and delivered_at is null and read_at is null
                       and created_at >= v_now - interval '24 hours' and type = 'motivational'
                     order by created_at limit v_left)
      returning n.id, n.type, n.title, n.message, n.created_at)
    select v_items || coalesce(jsonb_agg(jsonb_build_object('id', id, 'type', type,
             'title', title, 'message', message, 'created_at', created_at)
             order by created_at), '[]'::jsonb), count(*)
    into v_items, v_count from sent;
    v_left := v_left - v_count;
  end if;

  -- ○ Informativos, juntos en un digest.
  if not v_quiet and v_left > 0
     and p_time >= coalesce(g.digest_time, make_time(public.rule('notify_digest_hour')::int, 0, 0)) then
    with sent as (
      update public.notifications n set delivered_at = v_now,
        digest_slot = case when p_time < time '14:00' then 'morning' else 'evening' end::public.digest_slot
      where n.user_id = v_uid and n.delivered_at is null and n.read_at is null
        and n.created_at >= v_now - interval '24 hours' and n.type = 'informational'
      returning n.id, n.title, n.message, n.created_at)
    select case
      when count(*) = 1 then jsonb_build_object('id', min(id::text), 'type', 'informational',
        'title', min(title), 'message', min(message), 'created_at', min(created_at))
      when count(*) > 1 then jsonb_build_object('id', min(id::text), 'type', 'informational',
        'title', 'Tu resumen del día',
        'message', 'Tienes ' || count(*) || ' avisos: ' || string_agg(title, ' · ' order by created_at) || '.',
        'created_at', min(created_at))
      end
    into v_digest from sent;
    if v_digest is not null then
      v_items := v_items || jsonb_build_array(v_digest);
    end if;
  end if;

  return jsonb_build_object('items', v_items);
end $$;

create or replace function public.device_notifications(p_token text, p_day date, p_time time)
returns jsonb
language plpgsql
security definer
set search_path = ''
set timezone to 'America/Bogota'
as $$
declare
  v_uid uuid;
begin
  update public.device_registrations set last_seen_at = now()
  where token_hash = sha256(convert_to(coalesce(p_token, ''), 'UTF8'))
  returning user_id into v_uid;
  if v_uid is null then
    raise exception 'device_not_registered' using errcode = '28000';
  end if;
  return public._deliver_notifications(v_uid, p_day, p_time);
end $$;

-- 4. Envío push -----------------------------------------------------------------
-- [{ "tokens": [...], "items": [{id, type, title, message, created_at}] }]
create or replace function public.push_dispatch()
returns jsonb
language plpgsql
security definer
set search_path = ''
set timezone to 'America/Bogota'
as $$
declare
  v_local timestamp := now()::timestamp;  -- ya en hora de Colombia
  v_user record;
  v_items jsonb;
  v_out jsonb := '[]'::jsonb;
begin
  for v_user in
    select user_id, array_agg(fcm_token) tokens
    from public.device_registrations
    where fcm_token is not null
    group by user_id
  loop
    v_items := public._deliver_notifications(
      v_user.user_id, v_local::date, v_local::time) -> 'items';
    if jsonb_array_length(coalesce(v_items, '[]'::jsonb)) > 0 then
      v_out := v_out || jsonb_build_array(jsonb_build_object(
        'tokens', to_jsonb(v_user.tokens), 'items', v_items));
    end if;
  end loop;
  return v_out;
end $$;

-- 5. Token que FCM ya no reconoce ---------------------------------------------
create or replace function public.clear_push_token(p_fcm_token text)
returns void
language sql
security definer
set search_path = ''
as $$
  update public.device_registrations set fcm_token = null where fcm_token = p_fcm_token
$$;

revoke all on function public._deliver_notifications(uuid, date, time) from public, anon, authenticated;
revoke all on function public.push_dispatch() from public, anon, authenticated;
revoke all on function public.clear_push_token(text) from public, anon, authenticated;
grant execute on function public.push_dispatch() to service_role;
grant execute on function public.clear_push_token(text) to service_role;
revoke all on function public.set_push_token(text, text) from public;
grant execute on function public.set_push_token(text, text) to anon, authenticated;
grant execute on function public.device_notifications(text, date, time) to anon, authenticated;

-- 6. Cron cada 5 minutos --------------------------------------------------------
-- Necesita pg_cron, pg_net y dos secretos en el Vault (Project Settings → Vault):
--   lifequest_project_url = https://<proyecto>.supabase.co
--   lifequest_push_secret = el mismo valor del secret PUSH_CRON_SECRET de la función
do $$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron')
     and exists (select 1 from pg_extension where extname = 'pg_net') then
    perform cron.unschedule(jobid) from cron.job where jobname = 'lifequest_push';
    perform cron.schedule('lifequest_push', '*/5 * * * *', $job$
      select net.http_post(
        url := (select decrypted_secret from vault.decrypted_secrets
                where name = 'lifequest_project_url') || '/functions/v1/push-dispatch',
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'x-push-secret', (select decrypted_secret from vault.decrypted_secrets
                            where name = 'lifequest_push_secret')),
        body := '{}'::jsonb)
    $job$);
  else
    raise notice 'Activa pg_cron y pg_net (Database → Extensions) y vuelve a ejecutar esta migración.';
  end if;
end $$;

commit;
