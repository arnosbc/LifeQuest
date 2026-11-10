-- Migración 045 · Recursos con contexto y Foco que deja algo.
-- Requiere 001–044. Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- 1. resources: se adjuntan a una tarea, un proyecto o una meta (máx. un padre)
--    y son de 4 tipos: enlace, foto, PDF (en Storage) o nota. Una nota o foto
--    en un paso es su «prueba» en Foco.
-- 2. tasks.resume_note / resume_at: «Dónde lo dejé» al cerrar Foco.
-- 3. Bucket privado `resources` (10 MB, fotos y PDF), cada usuario en su carpeta.
-- 4. RPC attach_resource, item_resources, delete_resource, set_resume_note.
-- 5. dungeon_overview: nota de retomar, número de recursos y prueba de cada paso.
-- 6. stage_overview: la lista de Recursos solo muestra los enlaces sueltos.
-- shortcut: borrar una tarea, proyecto o meta borra sus filas por cascada pero
-- no los archivos de Storage; limpiar huérfanos con un job cuando ocupen espacio.

begin;

-- 1. Tabla ------------------------------------------------------------------------
do $$ begin
  create type public.resource_kind as enum ('link', 'image', 'pdf', 'note');
exception when duplicate_object then null; end $$;

alter table public.resources
  add column if not exists task_id uuid references public.tasks(id) on delete cascade,
  add column if not exists project_id uuid references public.projects(id) on delete cascade,
  add column if not exists goal_id uuid references public.goals(id) on delete cascade,
  add column if not exists kind public.resource_kind not null default 'link',
  add column if not exists storage_path text,
  add column if not exists size_bytes integer,
  add column if not exists note text;
alter table public.resources alter column file_url drop not null;

alter table public.resources drop constraint if exists resources_one_parent;
alter table public.resources add constraint resources_one_parent
  check (num_nonnulls(task_id, project_id, goal_id) <= 1);
alter table public.resources drop constraint if exists resources_kind_shape;
alter table public.resources add constraint resources_kind_shape check (
  (kind = 'link' and file_url is not null)
  or (kind in ('image', 'pdf') and storage_path is not null
      and size_bytes between 1 and 10485760)
  or (kind = 'note' and length(note) between 1 and 2000)
);
create index if not exists resources_task_idx on public.resources (task_id) where task_id is not null;
create index if not exists resources_project_idx on public.resources (project_id) where project_id is not null;
create index if not exists resources_goal_idx on public.resources (goal_id) where goal_id is not null;

-- 2. Dónde lo dejé ------------------------------------------------------------------
alter table public.tasks
  add column if not exists resume_note text,
  add column if not exists resume_at timestamptz;

-- 3. Storage (solo existe en Supabase; en las pruebas se salta) ----------------------
do $$ begin
  if to_regclass('storage.buckets') is not null then
    insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
    values ('resources', 'resources', false, 10485760,
            array['image/jpeg', 'image/png', 'image/webp', 'application/pdf'])
    on conflict (id) do update set public = false,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;
    execute 'drop policy if exists "resources own folder read" on storage.objects';
    execute 'drop policy if exists "resources own folder insert" on storage.objects';
    execute 'drop policy if exists "resources own folder delete" on storage.objects';
    execute $p$create policy "resources own folder read" on storage.objects for select to authenticated
      using (bucket_id = 'resources' and (storage.foldername(name))[1] = auth.uid()::text)$p$;
    execute $p$create policy "resources own folder insert" on storage.objects for insert to authenticated
      with check (bucket_id = 'resources' and (storage.foldername(name))[1] = auth.uid()::text)$p$;
    execute $p$create policy "resources own folder delete" on storage.objects for delete to authenticated
      using (bucket_id = 'resources' and (storage.foldername(name))[1] = auth.uid()::text)$p$;
  end if;
end $$;

-- 4. RPC ------------------------------------------------------------------------------
-- p_target: 'task' | 'project' | 'goal'. ¿El padre es del usuario?
create or replace function public._owns_target(p_target text, p_id uuid)
returns boolean
language sql
stable
security invoker
set search_path = ''
as $$
  select case p_target
    when 'task' then exists (select 1 from public.tasks where id = p_id and user_id = auth.uid())
    when 'project' then exists (select 1 from public.projects where id = p_id and user_id = auth.uid())
    when 'goal' then exists (select 1 from public.goals where id = p_id and user_id = auth.uid())
    else false end
$$;

create or replace function public.attach_resource(
  p_target text, p_target_id uuid, p_kind text, p_title text,
  p_url text default null, p_path text default null,
  p_size integer default null, p_note text default null)
returns uuid
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_kind public.resource_kind;
  v_title text := trim(coalesce(p_title, ''));
  v_url text := nullif(trim(coalesce(p_url, '')), '');
  v_note text := nullif(trim(coalesce(p_note, '')), '');
  v_id uuid;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  if not public._owns_target(p_target, p_target_id) then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
  if p_kind is null or p_kind not in ('link', 'image', 'pdf', 'note') then
    raise exception 'invalid_kind' using errcode = '22023';
  end if;
  v_kind := p_kind::public.resource_kind;
  if v_title = '' and v_kind = 'note' then v_title := 'Nota'; end if;
  if v_title = '' or length(v_title) > 200 then
    raise exception 'invalid_title' using errcode = '22023';
  end if;
  if v_kind = 'link' and (v_url is null or v_url !~* '^https?://[^\s]+$' or length(v_url) > 2000) then
    raise exception 'invalid_url' using errcode = '22023';
  end if;
  -- El archivo ya subió a Storage, en la carpeta del usuario.
  if v_kind = 'image' and coalesce(p_path, '') !~ ('^' || v_uid::text || '/[0-9a-f-]{36}\.(jpg|jpeg|png|webp)$') then
    raise exception 'invalid_path' using errcode = '22023';
  end if;
  if v_kind = 'pdf' and coalesce(p_path, '') !~ ('^' || v_uid::text || '/[0-9a-f-]{36}\.pdf$') then
    raise exception 'invalid_path' using errcode = '22023';
  end if;
  if v_kind in ('image', 'pdf') and (p_size is null or p_size not between 1 and 10485760) then
    raise exception 'invalid_size' using errcode = '22023';
  end if;
  if v_kind = 'note' and (v_note is null or length(v_note) > 2000) then
    raise exception 'invalid_note' using errcode = '22023';
  end if;

  insert into public.resources (user_id, title, kind, file_url, storage_path, size_bytes, note,
                                task_id, project_id, goal_id)
  values (v_uid, v_title, v_kind,
          case when v_kind = 'link' then v_url end,
          case when v_kind in ('image', 'pdf') then p_path end,
          case when v_kind in ('image', 'pdf') then p_size end,
          case when v_kind = 'note' then v_note end,
          case when p_target = 'task' then p_target_id end,
          case when p_target = 'project' then p_target_id end,
          case when p_target = 'goal' then p_target_id end)
  returning id into v_id;
  return v_id;
end $$;

create or replace function public.item_resources(p_target text, p_target_id uuid)
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  select coalesce(jsonb_agg(jsonb_build_object(
    'id', r.id, 'kind', r.kind, 'title', r.title, 'url', r.file_url,
    'path', r.storage_path, 'size', r.size_bytes, 'note', r.note, 'created_at', r.created_at
  ) order by r.created_at desc), '[]'::jsonb)
  from public.resources r
  where r.user_id = auth.uid()
    and case p_target
      when 'task' then r.task_id = p_target_id
      when 'project' then r.project_id = p_target_id
      when 'goal' then r.goal_id = p_target_id
      else false end
$$;

-- Devuelve la ruta en Storage (o null) para que el cliente borre el archivo.
create or replace function public.delete_resource(p_id uuid)
returns text
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_path text;
begin
  delete from public.resources where id = p_id and user_id = auth.uid()
  returning storage_path into v_path;
  if not found then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
  return v_path;
end $$;

-- security definer: el cliente no tiene grant de update en estas columnas.
create or replace function public.set_resume_note(p_task_id uuid, p_note text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_note text := nullif(trim(coalesce(p_note, '')), '');
begin
  if auth.uid() is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  if length(v_note) > 500 then
    raise exception 'invalid_note' using errcode = '22023';
  end if;
  update public.tasks
  set resume_note = v_note, resume_at = case when v_note is null then null else now() end
  where id = p_task_id and user_id = auth.uid();
  if not found then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
end $$;

revoke all on function public._owns_target(text, uuid) from public, anon;
revoke all on function public.attach_resource(text, uuid, text, text, text, text, integer, text) from public, anon;
revoke all on function public.item_resources(text, uuid) from public, anon;
revoke all on function public.delete_resource(uuid) from public, anon;
revoke all on function public.set_resume_note(uuid, text) from public, anon;
grant execute on function public._owns_target(text, uuid) to authenticated;
grant execute on function public.attach_resource(text, uuid, text, text, text, text, integer, text) to authenticated;
grant execute on function public.item_resources(text, uuid) to authenticated;
grant execute on function public.delete_resource(uuid) to authenticated;
grant execute on function public.set_resume_note(uuid, text) to authenticated;

-- 5. dungeon_overview: cuerpo de 037 más resume_note, resources y la prueba de cada paso.
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
            'resume_note', t.resume_note,
            'resume_at', t.resume_at,
            'resources', (select count(*) from public.resources r
                          where r.task_id = t.id and r.user_id = auth.uid()),
            'steps', coalesce((
              select jsonb_agg(jsonb_build_object(
                'id', st.id, 'title', st.title, 'done', st.status = 'completed',
                'proof', (select r.note from public.resources r
                          where r.task_id = st.id and r.user_id = auth.uid() and r.kind = 'note'
                          order by r.created_at desc limit 1),
                'proof_photo', exists (select 1 from public.resources r
                                       where r.task_id = st.id and r.user_id = auth.uid()
                                         and r.kind = 'image')
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

-- 6. stage_overview (paso base de 036): Recursos solo lista los enlaces sueltos.
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
      where r.archived_at is null and r.kind = 'link'
        and r.task_id is null and r.project_id is null and r.goal_id is null
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

commit;
