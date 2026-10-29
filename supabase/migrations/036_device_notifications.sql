-- Migración 036 · Avisos en el dispositivo (requiere 001–029; no depende de 030–035).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- El móvil revisa cada ~15 min en segundo plano (workmanager) y muestra como
-- notificación local lo que esta migración le entrega. Las reglas anti-estrés
-- de CLAUDE.md §7 se aplican aquí, en el servidor:
--   ▲ crítico       uno por uno y al momento. Respeta la ventana de silencio
--                   salvo critical_bypass_silence. La racha solo se avisa desde
--                   las notify_streak_hour (últimas horas del día).
--   ● motivacional  al momento, sin repetirse nunca.
--   ○ informativo   agrupado en un digest desde digest_time (o notify_digest_hour).
--   Lo no crítico espera mientras dure la ventana de silencio o una sesión de
--   Mazmorra, y cuenta para notification_daily_limit (un digest cuenta 1).
--   Un aviso entregado y sin leer en notify_ignored_after_hours queda como
--   ignorado: el trigger de 007 baja la frecuencia de su categoría tras 5.
--
-- 1. device_registrations: un código aleatorio por dispositivo (solo se guarda
--    su hash). El proceso de fondo no usa la sesión de Supabase: si refrescara
--    el token a la vez que la app abierta, una de las dos perdería la sesión.
-- 2. register_device() / unregister_device(token).
-- 3. _generate_notifications(uid, día): la generación de 029, ahora reutilizable;
--    notifications_overview la llama y devuelve lo mismo que antes.
-- 4. device_notifications(token, día, hora): genera, aplica las reglas, marca
--    delivered_at y devuelve lo que hay que mostrar.

begin;

alter table public.notifications add column if not exists delivered_at timestamptz;

insert into public.game_rules (key, value, provisional, note) values
  ('notify_streak_hour',         18, true, 'hora local desde la que se avisa una racha en riesgo'),
  ('notify_digest_hour',          8, true, 'hora local del digest si el usuario no eligió digest_time'),
  ('notify_ignored_after_hours', 24, true, 'horas sin leer tras las que un aviso entregado cuenta como ignorado')
on conflict (key) do nothing;

-- 1. Dispositivos ------------------------------------------------------------
create table if not exists public.device_registrations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  token_hash bytea not null unique,
  created_at timestamptz not null default now(),
  last_seen_at timestamptz
);
-- Sin políticas: solo se toca con las funciones de abajo.
alter table public.device_registrations enable row level security;
revoke all on public.device_registrations from anon, authenticated;

-- 2. Registro ----------------------------------------------------------------
create or replace function public.register_device()
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_token text := replace(gen_random_uuid()::text || gen_random_uuid()::text, '-', '');
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  insert into public.device_registrations (user_id, token_hash)
  values (v_uid, sha256(convert_to(v_token, 'UTF8')));
  -- Como mucho 5 dispositivos por jugador: se olvidan los más viejos.
  delete from public.device_registrations
  where user_id = v_uid and id not in (
    select id from public.device_registrations where user_id = v_uid
    order by created_at desc limit 5);
  return v_token;
end $$;

-- Quien tiene el código puede darlo de baja (también tras cerrar sesión).
create or replace function public.unregister_device(p_token text)
returns void
language sql
security definer
set search_path = ''
as $$
  delete from public.device_registrations
  where token_hash = sha256(convert_to(coalesce(p_token, ''), 'UTF8'))
$$;

-- 3. Generación (antes dentro de notifications_overview, 029) -----------------
create or replace function public._generate_notifications(p_uid uuid, p_day date)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_reduced text[];
begin
  select coalesce(array_agg(category), '{}') into v_reduced
  from public.notification_category_state where user_id = p_uid and reduced;

  insert into public.notifications (user_id, type, category, event_key, title, message,
                                    related_entity_type, related_entity_id, sent_at)
  select p_uid, x.type::public.notification_type, x.category, x.key, x.title, x.message,
         x.entity_type, x.entity_id, now()
  from (
    -- ▲ Racha en riesgo (tono de invitación, nunca de amenaza).
    select 'critical' type, 'streak' category,
           'streak:' || h.id || ':' || p_day key,
           'Tu racha te está esperando 🔥' title,
           'Llevas ' || h.current_streak || ' días con «' || h.name || '». Hoy puedes sumar uno más.' message,
           'habit' entity_type, h.id entity_id
    from public.habits h
    where h.user_id = p_uid and h.type = 'good' and coalesce(h.current_streak, 0) > 0
      and (h.frequency = 'daily' or extract(dow from p_day)::int = any (h.specific_days))
      and not exists (select 1 from public.habit_records r
                      where r.habit_id = h.id and r.completed_on = p_day)
    union all
    -- ▲ Proyecto en 🔴.
    select 'critical', 'project', 'project:' || p.id || ':' || p_day,
           'Un proyecto necesita tu atención',
           '«' || p.title || '» va con el tiempo justo. Una misión hoy lo pone al día.',
           'project', p.id
    from public.projects p
    cross join lateral (
      select count(*)::int total, count(*) filter (where t.status = 'completed')::int done
      from public.tasks t where t.project_id = p.id and t.parent_task_id is null) c
    where p.user_id = p_uid and p.archived_at is null and p.status in ('not_started', 'in_progress')
      and public._project_urgency(c.total, c.done, coalesce(p.start_date, p.created_at::date),
                                  p.end_date, p_day) = 'high'
    union all
    -- ● Cerca de subir de nivel.
    select 'motivational', 'level', 'level:' || p_uid || ':' || s.level,
           'Estás a un paso del nivel ' || (s.level + 1),
           'Te faltan ' || (s.xp_to_next_level - s.current_xp) || ' XP. Una misión más y lo logras.',
           null, null
    from public.character_stats s
    where s.user_id = p_uid and s.current_xp >= s.xp_to_next_level * 0.9
      and not ('level' = any (v_reduced))
    union all
    -- ● Cofre del día listo (misma regla que claim_daily_chest).
    select 'motivational', 'chest', 'chest:' || p_uid || ':' || p_day,
           'Tu cofre del día está listo',
           'Cumpliste tus misiones de hoy. Ábrelo en el Inicio.',
           null, null
    where (select count(*) from public.quest_log_entries
           where user_id = p_uid and source_type::text in ('task', 'npc') and result = 'completed'
             and coin_awarded > 0 and occurred_at >= current_date and occurred_at < current_date + 1)
          >= public.rule('daily_chest_min_missions')
      and not exists (select 1 from public.quest_log_entries
                      where user_id = p_uid and source_type::text = 'daily_chest'
                        and occurred_at >= current_date and occurred_at < current_date + 1)
      and not ('chest' = any (v_reduced))
    union all
    -- ○ Lo que vence hoy.
    select 'informational', 'due', 'due:' || p_uid || ':' || p_day,
           'Tu día de hoy',
           case when n = 1 then 'Hoy vence 1 misión. Tú decides cuándo.'
                else 'Hoy vencen ' || n || ' misiones. Tú decides el orden.' end,
           null, null
    from (select count(*) n from public.tasks
          where user_id = p_uid and parent_task_id is null
            and status in ('pending', 'in_progress')
            and due_date >= p_day::timestamptz and due_date < (p_day + 1)::timestamptz) d
    where n > 0 and not ('due' = any (v_reduced))
  ) x
  on conflict (user_id, event_key) where event_key is not null do nothing;
end $$;

create or replace function public.notifications_overview(p_day date)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  perform public._generate_notifications(v_uid, p_day);

  return jsonb_build_object(
    'items', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', n.id, 'type', n.type, 'title', n.title, 'message', n.message,
        'created_at', n.created_at, 'read', n.read_at is not null)
        order by n.created_at desc)
      from (select * from public.notifications where user_id = v_uid
            order by created_at desc limit 50) n
    ), '[]'::jsonb),
    'unread', (select count(*) from public.notifications
               where user_id = v_uid and read_at is null)
  );
end $$;

-- 4. Entrega al dispositivo --------------------------------------------------
-- p_day y p_time son la fecha y la hora local del móvil.
create or replace function public.device_notifications(p_token text, p_day date, p_time time)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
  v_now timestamptz := now();
  g public.game_master_settings;
  v_silent boolean;
  v_quiet boolean;
  v_left integer;
  v_count integer;
  v_items jsonb;
  v_digest jsonb;
begin
  update public.device_registrations set last_seen_at = v_now
  where token_hash = sha256(convert_to(coalesce(p_token, ''), 'UTF8'))
  returning user_id into v_uid;
  if v_uid is null then
    raise exception 'device_not_registered' using errcode = '28000';
  end if;

  -- Frecuencia decreciente: lo entregado y no leído a tiempo cuenta como ignorado.
  update public.notifications set ignored = true
  where user_id = v_uid and type <> 'critical' and not ignored and read_at is null
    and delivered_at < v_now - make_interval(hours => public.rule('notify_ignored_after_hours')::int);

  perform public._generate_notifications(v_uid, p_day);

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

do $$
declare f text;
begin
  foreach f in array array['public.register_device()', 'public.notifications_overview(date)',
    'public._generate_notifications(uuid, date)'] loop
    execute format('revoke all on function %s from public, anon', f);
  end loop;
  revoke all on function public._generate_notifications(uuid, date) from authenticated;
  grant execute on function public.register_device() to authenticated;
  grant execute on function public.notifications_overview(date) to authenticated;
  -- El proceso de fondo llama sin sesión: lo protege el código del dispositivo.
  foreach f in array array['public.unregister_device(text)',
    'public.device_notifications(text, date, time)'] loop
    execute format('revoke all on function %s from public', f);
    execute format('grant execute on function %s to anon, authenticated', f);
  end loop;
end $$;

commit;
