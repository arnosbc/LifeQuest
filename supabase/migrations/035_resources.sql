-- Migración 035 · Recursos: enlaces, notas y documentos, con vínculos
-- (requiere 001–034). Ejecutar una vez en Supabase → SQL Editor. Se puede volver
-- a ejecutar.
--
-- Un Recurso de P.A.R.A. ya no es solo un enlace:
-- 1. resources.kind: 'link' (file_url = URL), 'note' (content) o 'document'
--    (file_url = ruta en Storage y storage_bucket). Vínculos opcionales a un
--    Proyecto, una Meta o una Skill (Área), con ON DELETE SET NULL (§8).
--    Los documentos de contexto de los NPC (032) pasan a ser 'document' del
--    bucket `npc-context`.
-- 2. Bucket privado `resources` (máx. 10 MB; ruta <user_id>/<archivo>) con las
--    mismas políticas por carpeta que `npc-context`.
-- 3. create_resource(título, tipo, enlace, nota, ruta, proyecto, meta, skill).
--    La llamada antigua create_resource(p_title, p_url) sigue valiendo.
-- 4. add_npc_document (032) guarda sus documentos como 'document'.
-- 5. stage_overview (014) devuelve el tipo, la nota, la ruta y los vínculos.

begin;

-- 1. Tipos y vínculos -----------------------------------------------------------------
do $$
begin
  if not exists (select 1 from pg_type where typname = 'resource_kind') then
    create type public.resource_kind as enum ('link', 'note', 'document');
  end if;
end $$;

alter table public.resources
  add column if not exists kind public.resource_kind not null default 'link',
  add column if not exists content text,
  add column if not exists storage_bucket text,
  add column if not exists project_id uuid references public.projects(id) on delete set null,
  add column if not exists goal_id uuid references public.goals(id) on delete set null,
  add column if not exists skill_id uuid references public.skills(id) on delete set null;
alter table public.resources alter column file_url drop not null;

-- Documentos de los NPC guardados antes de esta migración.
update public.resources
set kind = 'document', storage_bucket = 'npc-context'
where npc_id is not null and storage_bucket is null;

alter table public.resources drop constraint if exists resources_kind_fields;
alter table public.resources add constraint resources_kind_fields check (
  (kind = 'link' and file_url is not null)
  or (kind = 'note' and content is not null)
  or (kind = 'document' and file_url is not null and storage_bucket is not null)
);

-- 2. Bucket de documentos ---------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('resources', 'resources', false, 10485760, array[
  'application/pdf',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  'application/vnd.openxmlformats-officedocument.presentationml.presentation',
  'text/markdown', 'text/plain', 'image/png', 'image/jpeg'])
on conflict (id) do update
  set public = false,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "resources: leer lo propio" on storage.objects;
create policy "resources: leer lo propio" on storage.objects
  for select to authenticated
  using (bucket_id = 'resources' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "resources: subir a lo propio" on storage.objects;
create policy "resources: subir a lo propio" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'resources' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "resources: borrar lo propio" on storage.objects;
create policy "resources: borrar lo propio" on storage.objects
  for delete to authenticated
  using (bucket_id = 'resources' and (storage.foldername(name))[1] = auth.uid()::text);

-- 3. Crear un recurso ---------------------------------------------------------------------
drop function if exists public.create_resource(text, text);

create or replace function public.create_resource(
  p_title text,
  p_url text default null,
  p_kind public.resource_kind default 'link',
  p_content text default null,
  p_path text default null,
  p_project_id uuid default null,
  p_goal_id uuid default null,
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
  v_url text := nullif(trim(coalesce(p_url, '')), '');
  v_content text := nullif(trim(coalesce(p_content, '')), '');
  v_path text := nullif(trim(coalesce(p_path, '')), '');
  v_kind public.resource_kind := coalesce(p_kind, 'link');
  v_id uuid;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  if v_title = '' or length(v_title) > 200 then
    raise exception 'invalid_title' using errcode = '22023';
  end if;
  if v_kind = 'link' and (v_url is null or v_url !~* '^https?://[^\s]+$' or length(v_url) > 2000) then
    raise exception 'invalid_url' using errcode = '22023';
  end if;
  if v_kind = 'note' and (v_content is null or length(v_content) > 10000) then
    raise exception 'invalid_content' using errcode = '22023';
  end if;
  -- El archivo tiene que estar en la carpeta del usuario dentro del bucket.
  if v_kind = 'document'
     and (v_path is null or length(v_path) > 500 or v_path not like v_uid::text || '/%') then
    raise exception 'invalid_path' using errcode = '22023';
  end if;
  if p_project_id is not null and not exists (
       select 1 from public.projects where id = p_project_id and user_id = v_uid
       and archived_at is null) then
    raise exception 'project_not_found' using errcode = 'P0002';
  end if;
  if p_goal_id is not null and not exists (
       select 1 from public.goals where id = p_goal_id and user_id = v_uid
       and archived_at is null) then
    raise exception 'goal_not_found' using errcode = 'P0002';
  end if;
  if p_skill_id is not null and not exists (
       select 1 from public.skills where id = p_skill_id and user_id = v_uid) then
    raise exception 'skill_not_found' using errcode = 'P0002';
  end if;
  insert into public.resources (user_id, title, kind, file_url, content, storage_bucket,
                                project_id, goal_id, skill_id)
  values (v_uid, v_title, v_kind,
          case v_kind when 'link' then v_url when 'document' then v_path end,
          case when v_kind = 'note' then v_content end,
          case when v_kind = 'document' then 'resources' end,
          p_project_id, p_goal_id, p_skill_id)
  returning id into v_id;
  return v_id;
end $$;

-- 4. Documentos de los NPC como 'document' (cuerpo de 032) ------------------------------
create or replace function public.add_npc_document(
  p_npc_id uuid,
  p_title text,
  p_path text,
  p_summary text
)
returns uuid
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_title text := trim(coalesce(p_title, ''));
  v_summary text := trim(coalesce(p_summary, ''));
  v_id uuid;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  perform 1 from public.npcs where id = p_npc_id and user_id = v_uid;
  if not found then
    raise exception 'npc_not_found' using errcode = 'P0002';
  end if;
  if v_title = '' or length(v_title) > 120 then
    raise exception 'invalid_title' using errcode = '22023';
  end if;
  if p_path is null or p_path not like v_uid::text || '/' || p_npc_id::text || '/%' then
    raise exception 'invalid_path' using errcode = '22023';
  end if;
  if v_summary = '' or length(v_summary) > 8000 then
    raise exception 'invalid_summary' using errcode = '22023';
  end if;
  if (select count(*) from public.resources
      where npc_id = p_npc_id and archived_at is null) >= 3 then
    raise exception 'npc_document_limit' using errcode = 'P0001';
  end if;
  insert into public.resources (user_id, npc_id, title, kind, file_url, storage_bucket, ai_summary)
  values (v_uid, p_npc_id, v_title, 'document', p_path, 'npc-context', v_summary)
  returning id into v_id;
  return v_id;
end $$;

-- 5. Stage con los recursos completos (cuerpo de 014) -----------------------------------
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
      select jsonb_agg(jsonb_build_object(
        'id', r.id,
        'title', r.title,
        'kind', r.kind,
        'url', case when r.kind = 'link' then r.file_url end,
        'content', r.content,
        'path', case when r.kind = 'document' then r.file_url end,
        'bucket', r.storage_bucket,
        'project_id', r.project_id,
        'project_title', pr.title,
        'goal_id', r.goal_id,
        'goal_title', g.title,
        'skill_id', r.skill_id,
        'skill_name', s.name,
        'npc_name', n.name
      ) order by r.created_at desc)
      from public.resources r
      left join public.projects pr on pr.id = r.project_id
      left join public.goals g on g.id = r.goal_id
      left join public.skills s on s.id = r.skill_id
      left join public.npcs n on n.id = r.npc_id
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

-- Permisos ---------------------------------------------------------------------
do $$
declare f text;
begin
  foreach f in array array['public.stage_overview(date)',
    'public.create_resource(text, text, public.resource_kind, text, text, uuid, uuid, uuid)',
    'public.add_npc_document(uuid, text, text, text)'] loop
    execute format('revoke all on function %s from public, anon', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;

commit;
