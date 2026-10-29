-- Migración 034 · Del Brain Dump a una Meta S.M.A.R.T. (requiere 001–033).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- Antes, el G.T.D. del Brain Dump mandaba a Stage cuando la idea era «un
-- resultado de meses» y no creaba nada: la idea seguía en la bandeja y había
-- que volver a escribirla. Ahora el formulario S.M.A.R.T. se abre en el propio
-- Brain Dump (RF-014: Goal pasa por S.M.A.R.T.) y:
--
-- 1. convert_thought_to_goal: crea la Meta con create_goal (014, mismas
--    validaciones) y marca la idea como convertida, en una transacción.
-- 2. brain_dump_overview: añade `skills` para vincular la Meta a un Área.

begin;

-- 1. Convertir en Meta ------------------------------------------------------------------
create or replace function public.convert_thought_to_goal(
  p_id uuid,
  p_title text,
  p_specific text,
  p_measurable text,
  p_achievable text,
  p_relevant text,
  p_due_date date,
  p_timebound text default null,
  p_skill_id uuid default null
)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_id uuid;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  perform 1 from public.brain_dump_entries
  where id = p_id and user_id = v_uid and status <> 'converted' for update;
  if not found then
    raise exception 'thought_not_found' using errcode = 'P0002';
  end if;
  v_id := public.create_goal(p_title, p_specific, p_measurable, p_achievable, p_relevant,
                             p_due_date, p_timebound, p_skill_id);
  update public.brain_dump_entries
  set status = 'converted', converted_to_type = 'goal', converted_to_id = v_id
  where id = p_id;
  return jsonb_build_object('id', v_id, 'type', 'goal');
end $$;

-- 2. Bandeja con las skills del jugador -------------------------------------------------
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
    ),
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
  foreach f in array array['public.brain_dump_overview()',
    'public.convert_thought_to_goal(uuid, text, text, text, text, text, date, text, uuid)'] loop
    execute format('revoke all on function %s from public, anon', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;

commit;
