-- Migración 048 · Recordatorios del día, estilo Duolingo (requiere 036 y 043).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- Hasta cinco recordatorios al día (09:00, 13:00, 16:00, 19:30 y 21:30), solo si
-- hay hábitos de hoy, tareas que vencen hoy o vencidas, o proyectos en 🔴. El de
-- la noche defiende la racha; el de las 21:30 solo llega si hay una racha y hoy
-- todavía no se hizo ningún hábito. Tono de invitación, nunca de amenaza.
--   · Llegan como críticos (salen arriba con sonido) y respetan la ventana de
--     silencio salvo critical_bypass_silence.
--   · Solo el último momento que pasó (hace < 2 h) genera aviso: si el móvil
--     estuvo apagado no llegan todos juntos. Si llegó otro aviso hace < 90 min,
--     ese momento se salta.
--   · game_master_settings.daily_reminders los apaga (Configuración → Avisos).

begin;

-- 1. Interruptor -------------------------------------------------------------
alter table public.game_master_settings
  add column if not exists daily_reminders boolean not null default true;
grant update (daily_reminders) on public.game_master_settings to authenticated;

-- 2. Recordatorios del día ---------------------------------------------------
-- Cinco momentos. Solo el último que ya pasó (y hace menos de 2 h) cuenta: si el
-- móvil estuvo apagado no llegan todos juntos. Uno por momento y día (event_key).
create or replace function public._generate_reminders(p_uid uuid, p_day date, p_time time)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_slot text;
  v_habits int;
  v_tasks int;
  v_projects int;
  v_streak int;
  v_done_today boolean;
  v_pick int;
  v_title text;
  v_message text;
  v_todo text;
  v_quedan text;
begin
  if not coalesce((select daily_reminders from public.game_master_settings
                   where user_id = p_uid), true) then
    return;
  end if;

  select s.slot into v_slot
  from (values ('morning', time '09:00'), ('midday', time '13:00'),
               ('afternoon', time '16:00'), ('evening', time '19:30'),
               ('last_call', time '21:30')) s(slot, at)
  where s.at <= p_time and p_time < s.at + interval '2 hours'
  order by s.at desc limit 1;
  if v_slot is null then
    return;
  end if;

  -- Si hace poco llegó otro aviso, este momento se salta.
  if exists (select 1 from public.notifications
             where user_id = p_uid and delivered_at > now() - interval '90 minutes') then
    return;
  end if;

  -- Hábitos buenos de hoy sin hacer.
  select count(*)::int into v_habits
  from public.habits h
  where h.user_id = p_uid and h.type = 'good'
    and (h.frequency = 'daily' or extract(dow from p_day)::int = any (h.specific_days))
    and not exists (select 1 from public.habit_records r
                    where r.habit_id = h.id and r.completed_on = p_day);
  -- La racha que se defiende es la más larga de los hábitos buenos.
  select coalesce(max(h.current_streak), 0)::int into v_streak
  from public.habits h where h.user_id = p_uid and h.type = 'good';

  -- Tareas que vencen hoy o ya vencieron.
  select count(*)::int into v_tasks
  from public.tasks
  where user_id = p_uid and parent_task_id is null
    and status in ('pending', 'in_progress')
    and due_date < (p_day + 1)::timestamptz;

  -- Proyectos en 🔴.
  select count(*)::int into v_projects
  from public.projects p
  cross join lateral (
    select count(*)::int total, count(*) filter (where t.status = 'completed')::int done
    from public.tasks t where t.project_id = p.id and t.parent_task_id is null) c
  where p.user_id = p_uid and p.archived_at is null and p.status in ('not_started', 'in_progress')
    and public._project_urgency(c.total, c.done, coalesce(p.start_date, p.created_at::date),
                                p.end_date, p_day) = 'high';

  if v_habits + v_tasks + v_projects = 0 then
    return; -- nada pendiente: no se molesta
  end if;

  v_done_today := exists (select 1 from public.habit_records r
                          join public.habits h on h.id = r.habit_id
                          where h.user_id = p_uid and r.completed_on = p_day);

  -- Resumen de lo pendiente: «2 hábitos y 1 tarea».
  v_todo := array_to_string(array_remove(array[
    case when v_habits = 1 then '1 hábito' when v_habits > 1 then v_habits || ' hábitos' end,
    case when v_tasks = 1 then '1 tarea' when v_tasks > 1 then v_tasks || ' tareas' end,
    case when v_projects = 1 then '1 proyecto urgente'
         when v_projects > 1 then v_projects || ' proyectos urgentes' end
  ], null), ' y ');

  v_quedan := case when v_habits + v_tasks + v_projects = 1 then 'Te queda ' else 'Te quedan ' end;

  -- El texto cambia cada día para no repetirse.
  v_pick := extract(doy from p_day)::int % 3 + 1;

  if v_slot = 'morning' then
    v_title := (array['Buenos días ☀️', 'Tu aventura de hoy empieza ya 🗺️',
                      'Un nuevo día, una nueva misión ⚔️'])[v_pick];
    v_message := 'Hoy tienes ' || v_todo || '. Empieza por lo más pequeño.';
  elsif v_slot = 'midday' then
    v_title := (array['¿Un momento para avanzar? ⏱️', 'Pausa productiva 🌱',
                      'Mitad del día, buen momento 💡'])[v_pick];
    v_message := v_quedan || v_todo || '. Cinco minutos ya cuentan.';
  elsif v_slot = 'afternoon' then
    v_title := (array['Aún estás a tiempo 💪', 'Tu yo del futuro te lo agradecerá ✨',
                      'Un paso más hoy 🚶'])[v_pick];
    v_message := 'Pendiente: ' || v_todo || '. ¿Empiezas con uno?';
  elsif v_slot = 'evening' then
    -- El aviso de racha de 036 (desde notify_streak_hour) ya salió hoy o sale
    -- en esta misma revisión: no repetir.
    if exists (select 1 from public.notifications
               where user_id = p_uid and category = 'streak'
                 and (delivered_at >= p_day::timestamptz
                      or (delivered_at is null and read_at is null
                          and created_at >= now() - interval '24 hours'
                          and p_time >= make_time(public.rule('notify_streak_hour')::int, 0, 0)))) then
      return;
    end if;
    if v_streak > 0 and v_habits > 0 and not v_done_today then
      v_title := 'Tu racha de ' || v_streak || ' días te espera 🔥';
      v_message := 'Un hábito hoy y la mantienes. Te faltan ' || v_todo || '.';
    else
      v_title := (array['Cierra el día con una victoria 🏁', 'Último empujón del día 🌙',
                        'Termina con algo hecho ✅'])[v_pick];
      v_message := v_quedan || v_todo || '.';
    end if;
  else -- last_call: solo si hay una racha que mantener y hoy no se hizo nada
    if v_streak = 0 or v_habits = 0 or v_done_today then
      return;
    end if;
    v_title := 'Última oportunidad para tu racha 🔥';
    v_message := 'Llevas ' || v_streak || ' días. Un hábito rápido antes de dormir y sigue viva.';
  end if;

  insert into public.notifications (user_id, type, category, event_key, title, message, sent_at)
  values (p_uid, 'critical', 'reminder', 'reminder:' || p_uid || ':' || p_day || ':' || v_slot,
          v_title, v_message, now())
  on conflict (user_id, event_key) where event_key is not null do nothing;
end $$;

-- 3. Entrega: igual que 036 + los recordatorios ------------------------------
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

-- 4. Configuración devuelve el interruptor -----------------------------------
create or replace function public.settings_overview()
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  select jsonb_build_object(
    'level', s.level,
    'current_xp', s.current_xp,
    'xp_to_next_level', s.xp_to_next_level,
    'difficulty', g.difficulty,
    'notification_daily_limit', g.notification_daily_limit,
    'silence_window_start', to_char(g.silence_window_start, 'HH24:MI'),
    -- 043: hora del resumen diario (null = la de notify_digest_hour).
    'digest_time', to_char(g.digest_time, 'HH24:MI'),
    'silence_window_end', to_char(g.silence_window_end, 'HH24:MI'),
    'critical_bypass_silence', g.critical_bypass_silence,
    -- 048: recordatorios del día (estilo Duolingo).
    'daily_reminders', coalesce(g.daily_reminders, true),
    'short_break_minutes', g.short_break_minutes,
    'long_break_minutes', g.long_break_minutes,
    'long_break_every_n_cycles', g.long_break_every_n_cycles,
    'difficulties', (
      select coalesce(jsonb_agg(jsonb_build_object(
        'level', dl.level,
        'xp_multiplier', dl.xp_multiplier,
        'hp_penalty_multiplier', dl.hp_penalty_multiplier,
        'coin_multiplier', dl.coin_multiplier
      ) order by dl.level), '[]'::jsonb)
      from public.difficulty_levels dl
    )
  )
  from public.profiles p
  left join public.character_stats s on s.user_id = p.id
  left join public.game_master_settings g on g.user_id = p.id
  where p.id = auth.uid()
$$;
revoke all on function public.settings_overview() from public, anon;
grant execute on function public.settings_overview() to authenticated;
revoke all on function public._generate_reminders(uuid, date, time) from public, anon, authenticated;

commit;
