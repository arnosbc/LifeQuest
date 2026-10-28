-- Migración 029 · Centro de avisos (requiere 001–028).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- 1. notifications_overview(p_day): genera los avisos del día que falten y
--    devuelve los últimos 50. Cada evento tiene event_key único
--    (<categoría>:<entidad_id>:<fecha>), así que nunca se repite (CLAUDE.md §7).
--      ▲ crítico       streak  racha en curso de un hábito que toca hoy y no se ha cumplido
--                      project proyecto con urgencia 🔴 (_project_urgency, 013)
--      ● motivacional  level   a ≤ 10 % de XP de subir de nivel
--                      chest   cofre del día listo para abrir (027)
--      ○ informativo   due     misiones que vencen hoy
--    Si una categoría no crítica se ignoró 5 veces seguidas
--    (notification_category_state.reduced, 007), deja de generarse.
-- 2. mark_notifications_read(p_ids): marca leídas las indicadas, o todas si
--    p_ids es null; el trigger de 007 reinicia el contador de ignoradas.
--
-- shortcut: solo el centro de avisos dentro de la app. Las notificaciones
-- push, el digest y la ventana de silencio necesitan Edge Functions.

begin;

create or replace function public.notifications_overview(p_day date)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_reduced text[];
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  select coalesce(array_agg(category), '{}') into v_reduced
  from public.notification_category_state where user_id = v_uid and reduced;

  insert into public.notifications (user_id, type, category, event_key, title, message,
                                    related_entity_type, related_entity_id, sent_at)
  select v_uid, x.type::public.notification_type, x.category, x.key, x.title, x.message,
         x.entity_type, x.entity_id, now()
  from (
    -- ▲ Racha en riesgo (tono de invitación, nunca de amenaza).
    select 'critical' type, 'streak' category,
           'streak:' || h.id || ':' || p_day key,
           'Tu racha te está esperando 🔥' title,
           'Llevas ' || h.current_streak || ' días con «' || h.name || '». Hoy puedes sumar uno más.' message,
           'habit' entity_type, h.id entity_id
    from public.habits h
    where h.user_id = v_uid and h.type = 'good' and coalesce(h.current_streak, 0) > 0
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
    where p.user_id = v_uid and p.archived_at is null and p.status in ('not_started', 'in_progress')
      and public._project_urgency(c.total, c.done, coalesce(p.start_date, p.created_at::date),
                                  p.end_date, p_day) = 'high'
    union all
    -- ● Cerca de subir de nivel.
    select 'motivational', 'level', 'level:' || v_uid || ':' || s.level,
           'Estás a un paso del nivel ' || (s.level + 1),
           'Te faltan ' || (s.xp_to_next_level - s.current_xp) || ' XP. Una misión más y lo logras.',
           null, null
    from public.character_stats s
    where s.user_id = v_uid and s.current_xp >= s.xp_to_next_level * 0.9
      and not ('level' = any (v_reduced))
    union all
    -- ● Cofre del día listo (misma regla que claim_daily_chest).
    select 'motivational', 'chest', 'chest:' || v_uid || ':' || p_day,
           'Tu cofre del día está listo',
           'Cumpliste tus misiones de hoy. Ábrelo en el Inicio.',
           null, null
    where (select count(*) from public.quest_log_entries
           where user_id = v_uid and source_type::text in ('task', 'npc') and result = 'completed'
             and coin_awarded > 0 and occurred_at >= current_date and occurred_at < current_date + 1)
          >= public.rule('daily_chest_min_missions')
      and not exists (select 1 from public.quest_log_entries
                      where user_id = v_uid and source_type::text = 'daily_chest'
                        and occurred_at >= current_date and occurred_at < current_date + 1)
      and not ('chest' = any (v_reduced))
    union all
    -- ○ Lo que vence hoy.
    select 'informational', 'due', 'due:' || v_uid || ':' || p_day,
           'Tu día de hoy',
           case when n = 1 then 'Hoy vence 1 misión. Tú decides cuándo.'
                else 'Hoy vencen ' || n || ' misiones. Tú decides el orden.' end,
           null, null
    from (select count(*) n from public.tasks
          where user_id = v_uid and parent_task_id is null
            and status in ('pending', 'in_progress')
            and due_date >= p_day::timestamptz and due_date < (p_day + 1)::timestamptz) d
    where n > 0 and not ('due' = any (v_reduced))
  ) x
  on conflict (user_id, event_key) where event_key is not null do nothing;

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

create or replace function public.mark_notifications_read(p_ids uuid[] default null)
returns void
language sql
security invoker
set search_path = ''
as $$
  update public.notifications set read_at = now()
  where user_id = auth.uid() and read_at is null
    and (p_ids is null or id = any (p_ids))
$$;

do $$
declare f text;
begin
  foreach f in array array['public.notifications_overview(date)',
    'public.mark_notifications_read(uuid[])'] loop
    execute format('revoke all on function %s from public, anon', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;

commit;
