-- Migración 010 · Misiones: listar y crear tareas (requiere 001–009).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- 1. missions_overview: misiones abiertas en el orden del Daily Highlight
--    (RF-089, vista v_daily_highlight de 007) y las opciones para vincular
--    (skills, proyectos y metas abiertos) en una sola llamada.
-- 2. RPC create_task: crea la misión y sus subtareas en una transacción
--    (RF-016). La recompensa la pone el trigger trg_set_task_reward de 005.
-- Completar sigue siendo la RPC complete_task de 005.

begin;

-- 1. Datos de la pantalla Misiones -----------------------------------------
-- security invoker: todo se lee con el RLS de cada tabla.
create or replace function public.missions_overview()
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  select jsonb_build_object(
    'missions', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', t.id,
        'title', t.title,
        'description', t.description,
        'priority', t.priority,
        'due_date', t.due_date,
        'status', t.status,
        'bucket', h.bucket,
        'xp_reward', t.xp_reward,
        'coin_reward', t.coin_reward,
        'skill_name', s.name,
        'project_title', p.title,
        'goal_title', g.title,
        'subtasks_total', (select count(*) from public.tasks c where c.parent_task_id = t.id),
        'subtasks_done', (select count(*) from public.tasks c
                          where c.parent_task_id = t.id and c.status = 'completed')
      ) order by h.bucket_order, t.due_date nulls last, t.created_at)
      from public.v_daily_highlight h
      join public.tasks t on t.id = h.id
      left join public.skills s on s.id = t.skill_id
      left join public.projects p on p.id = t.project_id
      left join public.goals g on g.id = t.goal_id
    ), '[]'::jsonb),
    'skills', coalesce((
      select jsonb_agg(jsonb_build_object('id', id, 'name', name) order by created_at)
      from public.skills
    ), '[]'::jsonb),
    'projects', coalesce((
      select jsonb_agg(jsonb_build_object('id', id, 'title', title, 'goal_id', goal_id) order by created_at)
      from public.projects
      where status in ('not_started', 'in_progress') and archived_at is null
    ), '[]'::jsonb),
    'goals', coalesce((
      select jsonb_agg(jsonb_build_object('id', id, 'title', title) order by created_at)
      from public.goals
      where status in ('not_started', 'in_progress') and archived_at is null
    ), '[]'::jsonb)
  )
$$;

-- 2. Crear misión -------------------------------------------------------------
-- security invoker: el insert pasa por el RLS y los grants de columna de 003.
-- Los vínculos se validan aquí porque la FK no comprueba el dueño. Las
-- subtareas no heredan Proyecto ni Meta: así no suman bonus ni golpean al jefe.
create or replace function public.create_task(
  p_title text,
  p_description text default null,
  p_priority public.urgency_level default 'low',
  p_due_date timestamptz default null,
  p_skill_id uuid default null,
  p_project_id uuid default null,
  p_goal_id uuid default null,
  p_subtasks text[] default '{}'
)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_title text := trim(coalesce(p_title, ''));
  v_task public.tasks;
  v_sub text;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  if v_title = '' or length(v_title) > 200 then
    raise exception 'invalid_title' using errcode = '22023';
  end if;
  if p_skill_id is not null
     and not exists (select 1 from public.skills where id = p_skill_id and user_id = v_uid) then
    raise exception 'skill_not_found' using errcode = 'P0002';
  end if;
  if p_project_id is not null and not exists (
    select 1 from public.projects where id = p_project_id and user_id = v_uid
      and status in ('not_started', 'in_progress') and archived_at is null) then
    raise exception 'project_not_found' using errcode = 'P0002';
  end if;
  if p_goal_id is not null and not exists (
    select 1 from public.goals where id = p_goal_id and user_id = v_uid
      and status in ('not_started', 'in_progress') and archived_at is null) then
    raise exception 'goal_not_found' using errcode = 'P0002';
  end if;

  insert into public.tasks (user_id, title, description, priority, due_date,
                            skill_id, project_id, goal_id)
  values (v_uid, v_title, nullif(trim(coalesce(p_description, '')), ''), p_priority,
          p_due_date, p_skill_id, p_project_id, p_goal_id)
  returning * into v_task;

  foreach v_sub in array coalesce(p_subtasks, '{}') loop
    if trim(v_sub) <> '' then
      insert into public.tasks (user_id, parent_task_id, title, skill_id)
      values (v_uid, v_task.id, left(trim(v_sub), 200), p_skill_id);
    end if;
  end loop;

  return jsonb_build_object('id', v_task.id, 'xp_reward', v_task.xp_reward,
                            'coin_reward', v_task.coin_reward);
end $$;

-- Permisos ---------------------------------------------------------------------
do $$
declare f text;
begin
  foreach f in array array['public.missions_overview()',
    'public.create_task(text, text, public.urgency_level, timestamptz, uuid, uuid, uuid, text[])'] loop
    execute format('revoke all on function %s from public, anon', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;

commit;
