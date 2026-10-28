-- Migración 023 · Brain Dump y Diagnosis G.T.D. (requiere 001–022).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- 1. brain_dump_overview(): bandeja (pending), Algún día y Referencia.
-- 2. capture_thought: captura con la mínima fricción (Modelo de Fogg).
-- 3. file_thought: el paso 1 del G.T.D. (no accionable → reference/someday)
--    o devolverlo a la bandeja.
-- 4. convert_thought: resultado del G.T.D. (CLAUDE.md §5). 'task' crea una
--    tarea con source = 'gtd_diagnosis'; 'delegated' la crea delegada con
--    «¿a quién?» (RF-011); 'done' la crea y la completa al instante (regla de
--    los 2 min: complete_task paga el mínimo, sin Monedas); 'project' usa
--    create_project. Las Metas pasan por S.M.A.R.T. en Stage (RF-014).
-- 5. delete_thought.

begin;

-- 1. Lectura ---------------------------------------------------------------------
create or replace function public.brain_dump_overview()
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  select jsonb_build_object(
    'inbox', coalesce((
      select jsonb_agg(jsonb_build_object('id', id, 'content', content, 'created_at', created_at)
                       order by created_at desc)
      from public.brain_dump_entries where status = 'pending'
    ), '[]'::jsonb),
    'someday', coalesce((
      select jsonb_agg(jsonb_build_object('id', id, 'content', content, 'created_at', created_at)
                       order by created_at desc)
      from public.brain_dump_entries where status = 'someday'
    ), '[]'::jsonb),
    'reference', coalesce((
      select jsonb_agg(jsonb_build_object('id', id, 'content', content, 'created_at', created_at)
                       order by created_at desc)
      from public.brain_dump_entries where status = 'reference'
    ), '[]'::jsonb),
    'converted_today', (
      select count(*) from public.brain_dump_entries
      where status = 'converted' and created_at >= current_date
    )
  )
$$;

-- 2. Capturar ---------------------------------------------------------------------
create or replace function public.capture_thought(p_content text)
returns uuid
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_content text := trim(coalesce(p_content, ''));
  v_id uuid;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  if v_content = '' or length(v_content) > 500 then
    raise exception 'invalid_content' using errcode = '22023';
  end if;
  insert into public.brain_dump_entries (user_id, content)
  values (v_uid, v_content) returning id into v_id;
  return v_id;
end $$;

-- 3. Archivar en Algún día / Referencia, o volver a la bandeja ----------------------
create or replace function public.file_thought(p_id uuid, p_status public.brain_dump_status)
returns void
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  if p_status = 'converted' then
    raise exception 'invalid_status' using errcode = '22023';
  end if;
  update public.brain_dump_entries set status = p_status
  where id = p_id and user_id = auth.uid() and status <> 'converted';
  if not found then
    raise exception 'thought_not_found' using errcode = 'P0002';
  end if;
end $$;

-- 4. Convertir (resultado del G.T.D.) -------------------------------------------------
create or replace function public.convert_thought(
  p_id uuid,
  p_kind text,
  p_title text,
  p_priority public.urgency_level default 'low',
  p_due_date timestamptz default null,
  p_delegated_to text default null
)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_title text := trim(coalesce(p_title, ''));
  v_id uuid;
  v_type public.entity_type := 'task';
  v_reward jsonb;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  perform 1 from public.brain_dump_entries
  where id = p_id and user_id = v_uid and status <> 'converted' for update;
  if not found then
    raise exception 'thought_not_found' using errcode = 'P0002';
  end if;
  if v_title = '' or length(v_title) > 200 then
    raise exception 'invalid_title' using errcode = '22023';
  end if;

  if p_kind in ('task', 'done') then
    insert into public.tasks (user_id, title, priority, due_date, source)
    values (v_uid, v_title, coalesce(p_priority, 'low'), p_due_date, 'gtd_diagnosis')
    returning id into v_id;
    if p_kind = 'done' then
      v_reward := public.complete_task(v_id);
    end if;
  elsif p_kind = 'delegated' then
    insert into public.tasks (user_id, title, priority, due_date, source, status, delegated_to)
    values (v_uid, v_title, coalesce(p_priority, 'low'), p_due_date, 'gtd_diagnosis', 'delegated',
            nullif(left(trim(coalesce(p_delegated_to, '')), 100), ''))
    returning id into v_id;
  elsif p_kind = 'project' then
    v_id := public.create_project(v_title, null, p_due_date::date);
    v_type := 'project';
  else
    raise exception 'invalid_kind' using errcode = '22023';
  end if;

  update public.brain_dump_entries
  set status = 'converted', converted_to_type = v_type, converted_to_id = v_id
  where id = p_id;
  return jsonb_build_object('id', v_id, 'type', v_type, 'reward', v_reward);
end $$;

-- 5. Borrar ---------------------------------------------------------------------------
create or replace function public.delete_thought(p_id uuid)
returns void
language plpgsql
security invoker
set search_path = ''
as $$
begin
  delete from public.brain_dump_entries where id = p_id and user_id = auth.uid();
  if not found then
    raise exception 'thought_not_found' using errcode = 'P0002';
  end if;
end $$;

-- Permisos ---------------------------------------------------------------------
do $$
declare f text;
begin
  foreach f in array array['public.brain_dump_overview()', 'public.capture_thought(text)',
    'public.file_thought(uuid, public.brain_dump_status)',
    'public.convert_thought(uuid, text, text, public.urgency_level, timestamptz, text)',
    'public.delete_thought(uuid)'] loop
    execute format('revoke all on function %s from public, anon', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;

commit;
