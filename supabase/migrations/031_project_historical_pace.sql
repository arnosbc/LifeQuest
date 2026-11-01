-- Migración 031 · Urgencia de proyectos con ritmo histórico de 14 días.
-- Requiere 001–030. Conserva los umbrales de RF-019/020; si no hay tareas
-- terminadas en la ventana reciente, usa el ritmo acumulado existente.

begin;

create or replace function public._project_urgency(
  p_total integer,
  p_done integer,
  p_start date,
  p_end date,
  p_day date,
  p_recent_done integer
)
returns public.urgency_level
language sql
immutable
set search_path = ''
as $$
  select case
    when p_end is null or p_total = 0 or p_done >= p_total then 'low'
    when p_end <= p_day then 'high'
    else (
      select case
        when needed > current_pace * 1.5 then 'high'
        when needed > current_pace * 1.2 then 'medium'
        else 'low'
      end
      from (
        select (p_total - p_done)::numeric / (p_end - p_day) as needed,
               case when p_recent_done > 0 then p_recent_done::numeric / 14
                    else p_done::numeric / greatest(p_day - p_start, 1)
               end as current_pace
      ) pace
    )
  end::public.urgency_level
$$;

do $$
begin
  if to_regprocedure('public.stage_overview_before_historical_pace(date)') is null then
    alter function public.stage_overview(date)
      rename to stage_overview_before_historical_pace;
  end if;
end $$;

create or replace function public.stage_overview(p_day date)
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  with base as (
    select public.stage_overview_before_historical_pace(p_day) as data
  ),
  projects as (
    select coalesce(jsonb_agg(
      jsonb_set(
        item.project,
        '{urgency}',
        to_jsonb(public._project_urgency(
          (item.project->>'tasks_total')::integer,
          (item.project->>'tasks_done')::integer,
          coalesce(p.start_date, p.created_at::date),
          p.end_date,
          p_day,
          (
            select count(*)::integer
            from public.tasks t
            where t.project_id = p.id
              and t.parent_task_id is null
              and t.status = 'completed'
              and t.completed_at >= (p_day - 13)::timestamptz
              and t.completed_at < (p_day + 1)::timestamptz
          )
        )::text)
      )
    ), '[]'::jsonb) as data
    from base
    cross join lateral jsonb_array_elements(
      coalesce(base.data->'projects', '[]'::jsonb)
    ) as item(project)
    join public.projects p on p.id = (item.project->>'id')::uuid
  )
  select jsonb_set(base.data, '{projects}', projects.data, true)
  from base cross join projects
$$;

revoke all on function public.stage_overview(date) from public, anon;
grant execute on function public.stage_overview(date) to authenticated;

commit;
