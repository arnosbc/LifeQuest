-- Migración 037 · Foco con progreso visible (fase 2 del rework: Foco que guía).
-- Requiere 001–036. Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- dungeon_overview: cuerpo de 017 más
--   · session.tasks[].steps: las subtareas de cada tarea de la sesión, para
--     marcarlas en Foco con complete_task.
--   · progress: nivel y XP del personaje, para la barra en vivo.
--   · week: minutos de foco de los últimos 7 días y de los 7 anteriores, para
--     el resumen de la sesión.

begin;

create or replace function public.dungeon_overview()
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  with s as (
    select * from public.focus_sessions
    where user_id = auth.uid() and status in ('active', 'paused')
    order by started_at desc limit 1
  ),
  runs as (
    select r.* from public.dungeon_runs r join s on s.id = r.session_id
  ),
  -- Minutos medidos de cada sesión (como focus_minutes de home_dashboard).
  measured as (
    select f.started_at,
           least(f.total_minutes,
                 floor(extract(epoch from coalesce(f.ended_at, now()) - f.started_at) / 60)::int) as minutes
    from public.focus_sessions f
    where f.user_id = auth.uid() and f.started_at >= now() - interval '14 days'
  )
  select jsonb_build_object(
    'session', (
      select jsonb_build_object(
        'id', s.id,
        'total_minutes', s.total_minutes,
        'cycle_minutes', s.cycle_minutes,
        'started_at', s.started_at,
        'cycles_done', (select count(*) from runs),
        'xp_earned', (select coalesce(sum(q.xp_awarded), 0) from public.quest_log_entries q
                      where q.source_type = 'dungeon' and q.source_id in (select id from runs)),
        'coins_earned', (select coalesce(sum(q.coin_awarded), 0) from public.quest_log_entries q
                         where q.source_type = 'dungeon' and q.source_id in (select id from runs)),
        'tasks', coalesce((
          select jsonb_agg(jsonb_build_object(
            'id', t.id,
            'title', t.title,
            'done', t.status = 'completed',
            'cycles', (select count(*) from runs where runs.task_id = t.id),
            'steps', coalesce((
              select jsonb_agg(jsonb_build_object(
                'id', st.id, 'title', st.title, 'done', st.status = 'completed'
              ) order by st.created_at, st.id)
              from public.tasks st
              where st.parent_task_id = t.id and st.user_id = auth.uid()
            ), '[]'::jsonb)
          ) order by t.created_at)
          from public.focus_session_tasks f join public.tasks t on t.id = f.task_id
          where f.session_id = s.id
        ), '[]'::jsonb)
      )
      from s
    ),
    'candidates', coalesce((
      select jsonb_agg(jsonb_build_object('id', c.id, 'title', c.title, 'bucket', c.bucket)
                       order by c.bucket_order, c.due_date nulls last)
      from (select * from public.v_daily_highlight
            order by bucket_order, due_date nulls last limit 30) c
    ), '[]'::jsonb),
    'max_tasks', public.rule('dungeon_max_tasks')::integer,
    'cycle_xp', public.rule('dungeon_cycle_xp')::integer,
    -- RF-067: descansos que el jugador eligió en Configuración (016).
    'breaks', (
      select jsonb_build_object(
        'short_minutes', g.short_break_minutes,
        'long_minutes', g.long_break_minutes,
        'long_every_n_cycles', g.long_break_every_n_cycles
      )
      from public.game_master_settings g where g.user_id = auth.uid()
    ),
    'progress', (
      select jsonb_build_object(
        'level', c.level,
        'current_xp', c.current_xp,
        'xp_to_next_level', c.xp_to_next_level
      )
      from public.character_stats c where c.user_id = auth.uid()
    ),
    'week', jsonb_build_object(
      'minutes', (select coalesce(sum(minutes), 0) from measured
                  where started_at >= now() - interval '7 days'),
      'prev_minutes', (select coalesce(sum(minutes), 0) from measured
                       where started_at < now() - interval '7 days')
    )
  )
$$;

commit;
