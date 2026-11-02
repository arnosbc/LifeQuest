-- Migración 045 · Más recordatorios en el teléfono (requiere 036).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- _generate_notifications suma dos avisos críticos (salen arriba con sonido):
--   ▲ hábitos de hoy pendientes que aún no tienen racha (uno que los agrupa,
--     desde notify_streak_hour como los de racha);
--   ▲ tareas vencidas sin terminar (uno por día).
-- El resto de la función es igual a la de 036.

begin;

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
    -- ▲ Hábitos de hoy sin hacer y aún sin racha: un solo aviso que los junta
    --   (los que tienen racha ya avisan arriba). Categoría streak: misma hora.
    select 'critical', 'streak', 'habits_pending:' || p_uid || ':' || p_day,
           'Tienes hábitos pendientes hoy',
           case when count(*) = 1 then 'Te falta «' || min(h.name) || '». Un paso pequeño también cuenta.'
                else 'Te faltan ' || count(*) || ' hábitos: ' || string_agg(h.name, ', ' order by h.name) || '.' end,
           null, null
    from public.habits h
    where h.user_id = p_uid and h.type = 'good' and coalesce(h.current_streak, 0) = 0
      and (h.frequency = 'daily' or extract(dow from p_day)::int = any (h.specific_days))
      and not exists (select 1 from public.habit_records r
                      where r.habit_id = h.id and r.completed_on = p_day)
    having count(*) > 0
    union all
    -- ▲ Tareas vencidas que siguen abiertas.
    select 'critical', 'overdue', 'overdue:' || p_uid || ':' || p_day,
           'Tienes tareas pendientes',
           case when n = 1 then '1 tarea ya pasó su fecha. Retómala cuando puedas.'
                else n || ' tareas ya pasaron su fecha. Elige una y empieza por ahí.' end,
           null, null
    from (select count(*) n from public.tasks
          where user_id = p_uid and parent_task_id is null
            and status in ('pending', 'in_progress')
            and due_date < p_day::timestamptz) o
    where n > 0
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

commit;
