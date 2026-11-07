-- Migración 036 · Repara funciones que otra rama cambió directo en Supabase.
-- Requiere 001–035. Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- En la base desplegada, home_dashboard, stage_overview_before_historical_pace
-- (la que envuelve stage_overview, 031), journal_overview, stats_overview,
-- complete_task y audit_double_rewards no eran las del repo: leían la tabla
-- npcs, que 035 borró ("relation public.npcs does not exist"). Aquí vuelven
-- las versiones del repo, idénticas a las que prueba supabase/tests.
-- create or replace conserva los permisos de cada función.
--
-- shortcut: quedan en la base funciones de esa rama que la app no llama
-- (add_npc_document, remove_npc_document, toggle_task_step, _dungeon_loot,
-- _generate_notifications) y las políticas del bucket npc-context; borrarlas
-- cuando nadie use esa rama.

begin;

-- De 001_home.sql.
create or replace function public.home_dashboard(
  p_day date,
  p_utc_offset_minutes integer default 0
)
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  with day as (
    select start_at, start_at + interval '1 day' as end_at
    from (
      select (p_day::timestamp - make_interval(mins => p_utc_offset_minutes))
             at time zone 'UTC' as start_at
    ) s
  ),
  today_habits as (
    select h.id, h.name, h.current_streak, h.created_at,
           exists (
             select 1 from public.habit_records r
             where r.habit_id = h.id and r.completed_on = p_day
           ) as done
    from public.habits h
    where h.user_id = auth.uid()
      and h.type = 'good'
      and (h.frequency = 'daily'
           or extract(dow from p_day)::int = any (h.specific_days))
  )
  select jsonb_build_object(
    'display_name', p.display_name,
    'character_class', p.character_class,
    'level', s.level,
    'current_xp', s.current_xp,
    'xp_to_next_level', s.xp_to_next_level,
    'coins', s.coins,
    'hp_current', s.hp_current,
    'hp_max', s.hp_max,
    'is_weakened', s.is_weakened,
    'priority_mission', (
      select jsonb_build_object(
        'id', t.id,
        'title', t.title,
        'due_date', t.due_date,
        'priority', t.priority,
        'xp_reward', t.xp_reward,
        'coin_reward', t.coin_reward
      )
      from public.tasks t
      where t.user_id = auth.uid()
        and t.parent_task_id is null
        and t.status in ('pending', 'in_progress')
      order by coalesce(t.due_date < now() + interval '24 hours', false) desc,
               t.priority desc,
               t.due_date asc nulls last,
               t.created_at
      limit 1
    ),
    'habits', coalesce((
      select jsonb_agg(
        jsonb_build_object('id', id, 'name', name, 'done', done)
        order by created_at
      )
      from today_habits
    ), '[]'::jsonb),
    'habits_done', (select count(*) from today_habits where done),
    'habits_total', (select count(*) from today_habits),
    'streak_days', (select coalesce(max(current_streak), 0) from today_habits),
    'missions_done', (
      select count(*) from public.tasks t, day
      where t.user_id = auth.uid()
        and t.parent_task_id is null
        and t.status = 'completed'
        and t.completed_at >= day.start_at and t.completed_at < day.end_at
    ),
    'missions_total', (
      select count(*) from public.tasks t, day
      where t.user_id = auth.uid()
        and t.parent_task_id is null
        and ((t.status = 'completed'
              and t.completed_at >= day.start_at
              and t.completed_at < day.end_at)
             or (t.status in ('pending', 'in_progress')
                 and t.due_date >= day.start_at
                 and t.due_date < day.end_at))
    ),
    'focus_minutes', (
      select coalesce(sum(least(
        f.total_minutes,
        floor(extract(epoch from coalesce(f.ended_at, now()) - f.started_at)
              / 60)::int
      )), 0)
      from public.focus_sessions f, day
      where f.user_id = auth.uid()
        and f.started_at >= day.start_at and f.started_at < day.end_at
    )
  )
  from public.profiles p
  left join public.character_stats s on s.user_id = p.id
  where p.id = auth.uid()
$$;

-- De 014_goals.sql.
create or replace function public.stage_overview_before_historical_pace(p_day date)
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  with p as (
    select p.*,
      (select count(*) from public.tasks t where t.project_id = p.id and t.parent_task_id is null)::int as total,
      (select count(*) from public.tasks t where t.project_id = p.id and t.parent_task_id is null
         and t.status = 'completed')::int as done
    from public.projects p
  )
  select jsonb_build_object(
    'highlight', coalesce((
      select jsonb_agg(jsonb_build_object('id', h.id, 'title', h.title, 'bucket', h.bucket,
                                          'due_date', h.due_date) order by h.n)
      -- Mismo orden que missions_overview (010): empata por antigüedad.
      from (select v.*, row_number() over (order by v.bucket_order, v.due_date nulls last,
                                                    t.created_at) n
            from public.v_daily_highlight v join public.tasks t on t.id = v.id) h
      where h.n <= 5
    ), '[]'::jsonb),
    'highlight_total', (select count(*) from public.v_daily_highlight),
    'projects', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', p.id,
        'title', p.title,
        'skill_name', s.name,
        'goal_title', g.title,
        'end_date', p.end_date,
        'tasks_total', p.total,
        'tasks_done', p.done,
        'urgency', public._project_urgency(p.total, p.done,
                     coalesce(p.start_date, p.created_at::date), p.end_date, p_day),
        'tasks', coalesce((
          select jsonb_agg(jsonb_build_object('id', t.id, 'title', t.title,
                                              'done', t.status = 'completed')
                           order by t.status = 'completed', t.created_at)
          from public.tasks t
          where t.project_id = p.id and t.parent_task_id is null
            and t.status in ('pending', 'in_progress', 'delegated', 'completed')
        ), '[]'::jsonb)
      ) order by p.end_date nulls last, p.created_at)
      from p
      left join public.skills s on s.id = p.skill_id
      left join public.goals g on g.id = p.goal_id
      where p.status in ('not_started', 'in_progress') and p.archived_at is null
    ), '[]'::jsonb),
    'areas', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', s.id,
        'name', s.name,
        'level', s.level,
        'open_tasks', (select count(*) from public.tasks t where t.skill_id = s.id
                         and t.parent_task_id is null
                         and t.status in ('pending', 'in_progress', 'delegated')),
        'projects', (select count(*) from public.projects pr where pr.skill_id = s.id
                       and pr.status in ('not_started', 'in_progress') and pr.archived_at is null),
        'habits', (select count(*) from public.habits hb where hb.skill_id = s.id)
      ) order by s.created_at)
      from public.skills s
    ), '[]'::jsonb),
    'resources', coalesce((
      select jsonb_agg(jsonb_build_object('id', r.id, 'title', r.title, 'url', r.file_url)
                       order by r.created_at desc)
      from public.resources r
      where r.archived_at is null
    ), '[]'::jsonb),
    'archive', jsonb_build_object(
      'projects', (select count(*) from public.projects
                   where archived_at is not null or status in ('completed', 'expired')),
      'goals', (select count(*) from public.goals
                where archived_at is not null or status in ('completed', 'expired')),
      'resources', (select count(*) from public.resources where archived_at is not null)
    ),
    'skills', coalesce((
      select jsonb_agg(jsonb_build_object('id', id, 'name', name) order by created_at)
      from public.skills
    ), '[]'::jsonb),
    'goals', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', g.id,
        'title', g.title,
        'skill_name', s.name,
        'due_date', g.due_date,
        'boss_hp', g.boss_current_hp,
        'boss_max_hp', g.boss_max_hp,
        'projects', (select count(*) from public.projects pr where pr.goal_id = g.id
                       and pr.status in ('not_started', 'in_progress') and pr.archived_at is null),
        'open_tasks', (select count(*) from public.tasks t where t.goal_id = g.id
                         and t.parent_task_id is null
                         and t.status in ('pending', 'in_progress', 'delegated'))
      ) order by g.due_date nulls last, g.created_at)
      from public.goals g
      left join public.skills s on s.id = g.skill_id
      where g.status in ('not_started', 'in_progress') and g.archived_at is null
    ), '[]'::jsonb)
  )
$$;

-- De 020_journal.sql.
create or replace function public.journal_overview(p_day date)
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  with q as (
    select q.*, (q.occurred_at >= (p_day - 6)::timestamptz) as this_week
    from public.quest_log_entries q
    where q.occurred_at >= (p_day - 13)::timestamptz
      and q.occurred_at < (p_day + 1)::timestamptz
  ),
  week as (
    select this_week,
           sum(xp_awarded) as xp,
           count(*) filter (where result = 'completed'
                            and source_type::text in ('task', 'npc', 'project')) as missions,
           count(*) filter (where source_type::text = 'dungeon') as cycles
    from q group by this_week
  )
  select jsonb_build_object(
    'summary', jsonb_build_object(
      'xp', coalesce((select xp from week where this_week), 0),
      'xp_prev', coalesce((select xp from week where not this_week), 0),
      'missions', coalesce((select missions from week where this_week), 0),
      'missions_prev', coalesce((select missions from week where not this_week), 0),
      'cycles', coalesce((select cycles from week where this_week), 0),
      'cycles_prev', coalesce((select cycles from week where not this_week), 0),
      'best_streak', coalesce((select max(current_streak) from public.habits where type = 'good'), 0)
    ),
    'entries', coalesce((
      select jsonb_agg(e order by e->>'occurred_at' desc)
      from (
        select jsonb_build_object(
          'id', l.id,
          'source', l.source_type,
          'result', l.result,
          'xp', l.xp_awarded,
          'coins', l.coin_awarded,
          'hp', l.hp_change,
          'occurred_at', l.occurred_at,
          'title', case l.source_type::text
            when 'task' then (select title from public.tasks where id = l.source_id)
            when 'npc' then (select title from public.tasks where id = l.source_id)
            when 'project' then (select title from public.projects where id = l.source_id)
            when 'goal' then (select title from public.goals where id = l.source_id)
            when 'habit' then (select name from public.habits where id = l.source_id)
            when 'dungeon' then (select t.title from public.dungeon_runs r
                                 join public.tasks t on t.id = r.task_id where r.id = l.source_id)
            when 'achievement' then (select name from public.achievements where id = l.source_id)
            else null end
        ) as e
        from public.quest_log_entries l
        where l.occurred_at >= (p_day - 59)::timestamptz
        order by l.occurred_at desc
        limit 150
      ) x
    ), '[]'::jsonb)
  )
$$;

-- De 025_stats.sql.
create or replace function public.stats_overview(p_day date)
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  with q as (
    select q.*, q.occurred_at >= (p_day - 6)::timestamptz as this_week,
           (q.occurred_at at time zone 'UTC')::date as day
    from public.quest_log_entries q
    where q.occurred_at >= (p_day - 13)::timestamptz
      and q.occurred_at < (p_day + 1)::timestamptz
  ),
  runs as (
    select r.ended_at >= (p_day - 6)::timestamptz as this_week, s.cycle_minutes
    from public.dungeon_runs r join public.focus_sessions s on s.id = r.session_id
    where r.completed and r.ended_at >= (p_day - 13)::timestamptz
      and r.ended_at < (p_day + 1)::timestamptz
  )
  select jsonb_build_object(
    'xp', coalesce((select sum(xp_awarded) from q where this_week), 0),
    'xp_prev', coalesce((select sum(xp_awarded) from q where not this_week), 0),
    'missions', (select count(*) from q where this_week and result = 'completed'
                 and source_type::text in ('task', 'npc', 'project')),
    'missions_prev', (select count(*) from q where not this_week and result = 'completed'
                      and source_type::text in ('task', 'npc', 'project')),
    'focus_minutes', coalesce((select sum(cycle_minutes) from runs where this_week), 0),
    'focus_minutes_prev', coalesce((select sum(cycle_minutes) from runs where not this_week), 0),
    'best_streak', coalesce((select max(current_streak) from public.habits where type = 'good'), 0),
    'record_streak', coalesce((select max(best_streak) from public.habits where type = 'good'), 0),
    'xp_by_day', (
      select jsonb_agg(jsonb_build_object('day', d,
               'xp', coalesce((select sum(xp_awarded) from q where q.day = d), 0)) order by d)
      from (select g::date as d from generate_series(p_day - 6, p_day, interval '1 day') g) days
    ),
    'xp_by_skill', coalesce((
      select jsonb_agg(jsonb_build_object('name', s.name, 'xp', t.xp) order by t.xp desc)
      from (select skill_id, sum(xp_awarded) xp from q
            where this_week and skill_id is not null group by skill_id) t
      join public.skills s on s.id = t.skill_id
      where t.xp > 0
    ), '[]'::jsonb),
    'top_habits', coalesce((
      select jsonb_agg(jsonb_build_object('name', name, 'days', days, 'streak', current_streak)
                       order by days desc, name)
      from (
        select h.name, h.current_streak, count(r.id) days
        from public.habits h
        join public.habit_records r on r.habit_id = h.id
          and r.completed_on > p_day - 30 and r.completed_on <= p_day
        where h.type = 'good'
        group by h.id
        order by days desc
        limit 3
      ) t
    ), '[]'::jsonb)
  )
$$;

-- De 005_rewards.sql.
create or replace function public.complete_task(p_task_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_task public.tasks;
  v_xp integer;
  v_coins integer;
  v_res jsonb;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  select * into v_task from public.tasks
  where id = p_task_id and user_id = v_uid for update;
  if not found then
    raise exception 'task_not_found' using errcode = 'P0002';
  end if;
  if v_task.status not in ('pending', 'in_progress', 'delegated') then
    raise exception 'task_not_open' using errcode = '22023';
  end if;

  v_xp := v_task.xp_reward;
  v_coins := v_task.coin_reward;
  -- Anti-trampa: completada a menos de 2 min de crearla.
  if now() - v_task.created_at < make_interval(secs => public.rule('task_min_seconds')) then
    v_xp := public.rule('task_xp_base')::integer;
    v_coins := 0;
  end if;
  -- Anti-trampa: máximo 15 tareas con Monedas al día.
  if v_coins > 0 and (
    select count(*) from public.quest_log_entries
    where user_id = v_uid and source_type in ('task', 'npc') and coin_awarded > 0
      and occurred_at >= current_date and occurred_at < current_date + 1
  ) >= public.rule('task_daily_coin_limit') then
    v_coins := 0;
  end if;

  perform set_config('lifequest.internal', 'on', true);
  update public.tasks set status = 'completed', completed_at = now() where id = p_task_id;

  v_res := public._award(v_uid,
    case when v_task.npc_id is not null then 'npc'::public.quest_source else 'task'::public.quest_source end,
    p_task_id, v_xp, v_coins, v_task.skill_id);
  if v_task.goal_id is not null then
    v_res := v_res || jsonb_build_object('boss',
      public._damage_boss(v_uid, v_task.goal_id, v_task.xp_reward));
  end if;
  return v_res;
end $$;

-- De 008_fix_exploits.sql.
create or replace function public.audit_double_rewards()
returns table (kind text, user_id uuid, source_type text, source_id uuid,
               times integer, allowed integer, extra_xp integer, extra_coins integer)
language sql
stable
security definer
set search_path = ''
as $$
  -- La misma entidad cobrada más de una vez; de más = total − primer cobro.
  select 'duplicate_award', q.user_id, q.source_type::text, q.source_id, count(*)::integer, 1,
         (sum(q.xp_awarded) - (array_agg(q.xp_awarded order by q.occurred_at, q.id))[1])::integer,
         (sum(q.coin_awarded) - (array_agg(q.coin_awarded order by q.occurred_at, q.id))[1])::integer
  from public.quest_log_entries q
  where q.result = 'completed' and q.source_type::text in ('task', 'project', 'goal', 'npc')
  group by q.user_id, q.source_type, q.source_id
  having count(*) > 1
  union all
  -- Sesiones con más ciclos cobrados de los que caben.
  select 'dungeon_overcycled', s.user_id, 'dungeon', s.id, x.times, x.allowed, x.extra_xp, x.extra_coins
  from public.focus_sessions s
  cross join lateral (
    select count(distinct r.id)::integer as times,
           floor(s.total_minutes::numeric / s.cycle_minutes)::integer as allowed,
           coalesce(sum(q.xp_awarded) filter (
             where r.cycle_number > floor(s.total_minutes::numeric / s.cycle_minutes)), 0)::integer as extra_xp,
           coalesce(sum(q.coin_awarded) filter (
             where r.cycle_number > floor(s.total_minutes::numeric / s.cycle_minutes)), 0)::integer as extra_coins
    from public.dungeon_runs r
    left join public.quest_log_entries q on q.source_type = 'dungeon' and q.source_id = r.id
    where r.session_id = s.id
  ) x
  where x.times > x.allowed
  union all
  -- Usuarios con varias sesiones abiertas a la vez.
  select 'multiple_open_sessions', f.user_id, null::text, null::uuid, count(*)::integer, 1, 0, 0
  from public.focus_sessions f
  where f.status in ('active', 'paused')
  group by f.user_id
  having count(*) > 1
$$;

commit;
