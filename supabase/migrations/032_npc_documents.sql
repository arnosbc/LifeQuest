-- Migración 032 · Documentos de contexto del NPC (requiere 001–031).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- El usuario adjunta al NPC un documento (p. ej. el plan de la asignatura) en
-- PDF, Word (.docx) o Markdown. La Edge Function npc-context lo resume UNA vez
-- con Gemini (temas, unidades, objetivos) y npc-mission usa ese resumen para
-- proponer misiones en el orden del documento (PLAN-REDISENO §13, prioridad 1).
--
-- 1. Bucket privado `npc-context` (máx. 10 MB; ruta <user_id>/<npc_id>/<archivo>)
--    con políticas de Storage: cada usuario solo ve, sube y borra su carpeta.
-- 2. resources.ai_summary: el resumen. El documento es un Recurso de P.A.R.A.
--    con npc_id (CLAUDE.md §4) y file_url = ruta en el bucket.
-- 3. add_npc_document: la llama npc-context con el JWT del usuario tras resumir.
--    Máx. 3 documentos por NPC.
-- 4. remove_npc_document: borra la fila y devuelve la ruta para quitar el archivo.
-- 5. tavern_overview: cada NPC lista sus documentos.

begin;

-- 1. Bucket y políticas de Storage ---------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('npc-context', 'npc-context', false, 10485760, array[
  'application/pdf',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'text/markdown', 'text/plain'])
on conflict (id) do update
  set public = false,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "npc-context: leer lo propio" on storage.objects;
create policy "npc-context: leer lo propio" on storage.objects
  for select to authenticated
  using (bucket_id = 'npc-context' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "npc-context: subir a lo propio" on storage.objects;
create policy "npc-context: subir a lo propio" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'npc-context' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "npc-context: borrar lo propio" on storage.objects;
create policy "npc-context: borrar lo propio" on storage.objects
  for delete to authenticated
  using (bucket_id = 'npc-context' and (storage.foldername(name))[1] = auth.uid()::text);

-- 2. Resumen del documento -------------------------------------------------------------
alter table public.resources add column if not exists ai_summary text;

-- 3. Guardar el documento ya resumido ----------------------------------------------------
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
  -- El archivo tiene que estar en la carpeta del usuario y del NPC.
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
  insert into public.resources (user_id, npc_id, title, file_url, ai_summary)
  values (v_uid, p_npc_id, v_title, p_path, v_summary)
  returning id into v_id;
  return v_id;
end $$;

-- 4. Quitar un documento ----------------------------------------------------------------
-- Devuelve la ruta en el bucket para que la app borre también el archivo.
create or replace function public.remove_npc_document(p_id uuid)
returns text
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_path text;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  delete from public.resources
  where id = p_id and user_id = auth.uid() and npc_id is not null
  returning file_url into v_path;
  if v_path is null then
    raise exception 'document_not_found' using errcode = 'P0002';
  end if;
  return v_path;
end $$;

-- 5. Taverna con los documentos de cada NPC ------------------------------------------
create or replace function public.tavern_overview()
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  select jsonb_build_object(
    'npcs', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', n.id,
        'name', n.name,
        'noble_mission', n.noble_mission,
        'frequency', n.frequency,
        'skill_name', s.name,
        'free_at', case when n.last_mission_at is not null
                        then n.last_mission_at
                             + make_interval(hours => public.rule('npc_free_hours')::integer) end,
        'open_mission', (
          select jsonb_build_object('id', t.id, 'title', t.title,
                                    'description', t.description, 'xp_reward', t.xp_reward)
          from public.tasks t
          where t.npc_id = n.id and t.status in ('pending', 'in_progress')
          order by t.created_at desc limit 1),
        'completed', (select count(*) from public.tasks t
                      where t.npc_id = n.id and t.status = 'completed'),
        'documents', coalesce((
          select jsonb_agg(jsonb_build_object('id', r.id, 'title', r.title)
                           order by r.created_at)
          from public.resources r
          where r.npc_id = n.id and r.archived_at is null
        ), '[]'::jsonb)
      ) order by n.created_at)
      from public.npcs n join public.skills s on s.id = n.skill_id
    ), '[]'::jsonb),
    'npc_limit', public.rule('npc_base_limit') + coalesce((
      select level from public.refuge_upgrades where building = 'estandarte'), 0),
    'instant_cost', public.rule('npc_instant_cost'),
    'coins', coalesce((select coins from public.character_stats), 0),
    'skills', coalesce((
      select jsonb_agg(jsonb_build_object('id', id, 'name', name) order by created_at)
      from public.skills
    ), '[]'::jsonb)
  )
$$;

-- Permisos ---------------------------------------------------------------------
do $$
declare f text;
begin
  foreach f in array array['public.add_npc_document(uuid, text, text, text)',
    'public.remove_npc_document(uuid)', 'public.tavern_overview()'] loop
    execute format('revoke all on function %s from public, anon', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;

commit;
