-- Migración 014 · Metas (Boss) en Stage · P.A.R.A. (requiere 001–013).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- 1. RPC create_goal: crea una Meta con el formulario S.M.A.R.T. (RF-014:
--    en Quick Add la Meta pasa por S.M.A.R.T.). La vida del jefe es la de
--    la columna (boss_max_hp, 100 por defecto).
-- 2. stage_overview: cuerpo de 013 más la sección Metas (vida del jefe,
--    fecha, proyectos y misiones vinculadas) y las misiones de cada proyecto.
-- 3. archive_item: también archiva metas.
--
-- shortcut: la vida del jefe es fija (100); el diseño no fija cómo escala
-- con el tamaño de la meta (docs/plan-cambios-esquema.md §7).

begin;

-- 1. Crear Meta --------------------------------------------------------------------
-- security invoker: el insert pasa por el RLS y los grants de columna de 003.
create or replace function public.create_goal(
  p_title text,
  p_specific text,
  p_measurable text,
  p_achievable text,
  p_relevant text,
  p_due_date date,
  p_timebound text default null,
  p_skill_id uuid default null
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
  if trim(coalesce(p_specific, '')) = '' or trim(coalesce(p_measurable, '')) = ''
     or trim(coalesce(p_achievable, '')) = '' or trim(coalesce(p_relevant, '')) = '' then
    raise exception 'smart_incomplete' using errcode = '22023';
  end if;
  if p_due_date is null or p_due_date < current_date then
    raise exception 'invalid_due_date' using errcode = '22023';
  end if;
  if p_skill_id is not null
     and not exists (select 1 from public.skills where id = p_skill_id and user_id = v_uid) then
    raise exception 'skill_not_found' using errcode = 'P0002';
  end if;
  insert into public.goals (user_id, skill_id, title, smart_specific, smart_measurable,
                            smart_achievable, smart_relevant, smart_timebound,
                            start_date, due_date)
  values (v_uid, p_skill_id, v_title, trim(p_specific), trim(p_measurable),
          trim(p_achievable), trim(p_relevant), nullif(trim(coalesce(p_timebound, '')), ''),
          current_date, p_due_date)
  returning id into v_id;
  return v_id;
end $$;

-- 2. Datos de la pantalla Stage ---------------------------------------------------
-- Cuerpo de 013 con: 'goals' ampliado (vida del jefe, fecha, vínculos) y
-- 'tasks' dentro de cada proyecto (misiones sin subtareas, abiertas primero).
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

-- 3. Archivo (cuerpo de 013 más las metas) ---------------------------------------
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
  elsif p_kind = 'goal' then
    update public.goals set archived_at = now()
    where id = p_id and user_id = v_uid and archived_at is null;
  else
    raise exception 'invalid_kind' using errcode = '22023';
  end if;
  if not found then
    raise exception 'item_not_found' using errcode = 'P0002';
  end if;
end $$;

-- Permisos ---------------------------------------------------------------------
do $$
declare f text;
begin
  foreach f in array array[
    'public.create_goal(text, text, text, text, text, date, text, uuid)',
    'public.stage_overview(date)', 'public.archive_item(text, uuid)'] loop
    execute format('revoke all on function %s from public, anon', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;

commit;
