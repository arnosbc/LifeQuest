-- Migración 013 · Stage · P.A.R.A. (requiere 001–012).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- Stage es una vista: no tiene tablas propias. Lee tasks, projects, skills,
-- resources y lo archivado.
-- 1. stage_overview(p_day): Daily Highlight (RF-089), Proyectos con su
--    urgencia automática (RF-019/020, derivada, no se guarda), Áreas
--    (skills), Recursos y Archivo, en una sola llamada.
-- 2. RPC create_project y create_resource (Quick Add, RF-014: Proyecto y
--    Recurso se crean directo; la Tarea va por Misiones).
-- 3. RPC archive_item: manda un proyecto o recurso al Archivo.
-- Completar un proyecto sigue siendo complete_project (008).
--
-- shortcut: Quick Add no pasa por el Diagnosis G.T.D. ni por S.M.A.R.T.;
-- sumarlos cuando exista el Brain Dump. RF-021 (avisar cada cambio de
-- urgencia) queda para cuando haya notificaciones.

begin;

-- 1. Datos de la pantalla Stage ---------------------------------------------------
-- Urgencia: ritmo_necesario = restante / días_restantes y ritmo_actual =
-- hechas / días_transcurridos; > ×1,5 → high, > ×1,2 → medium, si no low.
-- Sin fecha de fin o sin tareas: low. Vencido con trabajo pendiente: high.
create or replace function public._project_urgency(
  p_total integer, p_done integer, p_start date, p_end date, p_day date)
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
        else 'low' end
      from (select (p_total - p_done)::numeric / (p_end - p_day) as needed,
                   p_done::numeric / greatest(p_day - p_start, 1) as current_pace) r
    )
  end::public.urgency_level
$$;

create or replace function public.stage_overview(p_day date)
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
                     coalesce(p.start_date, p.created_at::date), p.end_date, p_day)
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
      select jsonb_agg(jsonb_build_object('id', id, 'title', title) order by created_at)
      from public.goals
      where status in ('not_started', 'in_progress') and archived_at is null
    ), '[]'::jsonb)
  )
$$;

-- 2. Quick Add ---------------------------------------------------------------------
-- security invoker: los insert pasan por el RLS y los grants de columna de 003.
create or replace function public.create_project(
  p_title text,
  p_description text default null,
  p_end_date date default null,
  p_skill_id uuid default null,
  p_goal_id uuid default null
)
returns uuid
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_title text := trim(coalesce(p_title, ''));
  v_id uuid;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  if v_title = '' or length(v_title) > 200 then
    raise exception 'invalid_title' using errcode = '22023';
  end if;
  if p_end_date is not null and p_end_date < current_date - 1 then
    raise exception 'invalid_end_date' using errcode = '22023';
  end if;
  if p_skill_id is not null
     and not exists (select 1 from public.skills where id = p_skill_id and user_id = v_uid) then
    raise exception 'skill_not_found' using errcode = 'P0002';
  end if;
  if p_goal_id is not null and not exists (
    select 1 from public.goals where id = p_goal_id and user_id = v_uid
      and status in ('not_started', 'in_progress') and archived_at is null) then
    raise exception 'goal_not_found' using errcode = 'P0002';
  end if;
  insert into public.projects (user_id, title, description, start_date, end_date, skill_id, goal_id)
  values (v_uid, v_title, nullif(trim(coalesce(p_description, '')), ''), current_date,
          p_end_date, p_skill_id, p_goal_id)
  returning id into v_id;
  return v_id;
end $$;

create or replace function public.create_resource(p_title text, p_url text)
returns uuid
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_title text := trim(coalesce(p_title, ''));
  v_url text := trim(coalesce(p_url, ''));
  v_id uuid;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  if v_title = '' or length(v_title) > 200 then
    raise exception 'invalid_title' using errcode = '22023';
  end if;
  if v_url !~* '^https?://[^\s]+$' or length(v_url) > 2000 then
    raise exception 'invalid_url' using errcode = '22023';
  end if;
  insert into public.resources (user_id, title, file_url)
  values (v_uid, v_title, v_url)
  returning id into v_id;
  return v_id;
end $$;

-- 3. Archivo ---------------------------------------------------------------------
-- security definer: resources no tiene grant de update para el cliente; aquí
-- solo se toca archived_at de una fila propia.
create or replace function public.archive_item(p_kind text, p_id uuid)
returns void
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
  if p_kind = 'project' then
    update public.projects set archived_at = now()
    where id = p_id and user_id = v_uid and archived_at is null;
  elsif p_kind = 'resource' then
    update public.resources set archived_at = now()
    where id = p_id and user_id = v_uid and archived_at is null;
  else
    raise exception 'invalid_kind' using errcode = '22023';
  end if;
  if not found then
    raise exception 'item_not_found' using errcode = 'P0002';
  end if;
end $$;

-- Permisos ---------------------------------------------------------------------
revoke all on function public._project_urgency(integer, integer, date, date, date) from public, anon;
grant execute on function public._project_urgency(integer, integer, date, date, date) to authenticated;
do $$
declare f text;
begin
  foreach f in array array['public.stage_overview(date)',
    'public.create_project(text, text, date, uuid, uuid)',
    'public.create_resource(text, text)',
    'public.archive_item(text, uuid)'] loop
    execute format('revoke all on function %s from public, anon', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;

commit;
