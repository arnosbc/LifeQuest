-- Migración 053 · Recordatorios del día con la voz de Nevi (requiere 048 y 049).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- La mascota se llama Nevi (decisión del usuario 2026-11-14). Solo cambian los
-- títulos y mensajes de _generate_reminders (048): Nevi habla en primera persona
-- y con tono de invitación (§7). Momentos, reglas y event_key son los mismos.

begin;

create or replace function public._generate_reminders(p_uid uuid, p_day date, p_time time)
returns void
language plpgsql
security definer
set search_path = ''
-- Hora de Colombia (049): reemplazar la función sin esto volvería a UTC.
set timezone to 'America/Bogota'
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
    v_title := (array['Nevi: ¡buenos días! ☀️', 'Nevi: tu camino de hoy ya está listo 🗺️',
                      'Nevi: ¡nuevo día, nueva misión! ⚔️'])[v_pick];
    v_message := 'Hoy te esperan ' || v_todo || '. Yo empezaría por lo más pequeño.';
  elsif v_slot = 'midday' then
    v_title := (array['Nevi: ¿cinco minutos conmigo? ⏱️', 'Nevi: pausa productiva 🌱',
                      'Nevi: mitad del día, buen momento 💡'])[v_pick];
    v_message := v_quedan || v_todo || '. Cinco minutos ya cuentan, te acompaño.';
  elsif v_slot = 'afternoon' then
    v_title := (array['Nevi: aún estamos a tiempo 💪', 'Nevi: tu yo del futuro te lo agradecerá ✨',
                      'Nevi: un pasito más hoy 🚶'])[v_pick];
    v_message := 'Pendiente: ' || v_todo || '. ¿Empezamos con uno?';
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
      v_title := 'Nevi: tu racha de ' || v_streak || ' días te espera 🔥';
      v_message := 'Un hábito hoy y la mantenemos. Te faltan ' || v_todo || '.';
    else
      v_title := (array['Nevi: cerremos el día con una victoria 🏁', 'Nevi: último empujón del día 🌙',
                        'Nevi: terminemos con algo hecho ✅'])[v_pick];
      v_message := v_quedan || v_todo || '. Te espero en el camino.';
    end if;
  else -- last_call: solo si hay una racha que mantener y hoy no se hizo nada
    if v_streak = 0 or v_habits = 0 or v_done_today then
      return;
    end if;
    -- §7: invitación, nunca amenaza (antes «Última oportunidad»).
    v_title := 'Nevi: tu racha de ' || v_streak || ' días sigue encendida 🔥';
    v_message := 'Un hábito rápido antes de dormir y la mantenemos juntos.';
  end if;

  insert into public.notifications (user_id, type, category, event_key, title, message, sent_at)
  values (p_uid, 'critical', 'reminder', 'reminder:' || p_uid || ':' || p_day || ':' || v_slot,
          v_title, v_message, now())
  on conflict (user_id, event_key) where event_key is not null do nothing;
end $$;

commit;
