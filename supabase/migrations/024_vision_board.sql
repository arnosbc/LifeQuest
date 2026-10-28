-- Migración 024 · Vision Board (requiere 001–023).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- 1. vision_overview(): el texto de la visión (1 por usuario), la identidad
--    del perfil y las Metas y Proyectos abiertos con su vínculo a la visión.
-- 2. save_vision: guarda el texto (upsert).
-- 3. set_vision_link: marca o desmarca una Meta o un Proyecto como parte de
--    la visión (goals/projects.linked_to_vision, 004).

begin;

create or replace function public.vision_overview()
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  select jsonb_build_object(
    'content', (select content from public.vision_boards),
    'updated_at', (select updated_at from public.vision_boards),
    'identity', (select identity_statement from public.profiles where id = auth.uid()),
    'items', coalesce((
      select jsonb_agg(x order by (x->>'linked')::boolean desc, x->>'kind', x->>'title')
      from (
        select jsonb_build_object('kind', 'goal', 'id', id, 'title', title,
                                  'linked', linked_to_vision) x
        from public.goals
        where archived_at is null and status in ('not_started', 'in_progress')
        union all
        select jsonb_build_object('kind', 'project', 'id', id, 'title', title,
                                  'linked', linked_to_vision)
        from public.projects
        where archived_at is null and status in ('not_started', 'in_progress')
      ) i
    ), '[]'::jsonb)
  )
$$;

create or replace function public.save_vision(p_content text)
returns void
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_content text := nullif(trim(coalesce(p_content, '')), '');
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  if length(v_content) > 2000 then
    raise exception 'invalid_content' using errcode = '22023';
  end if;
  insert into public.vision_boards (user_id, content, updated_at)
  values (v_uid, v_content, now())
  on conflict (user_id) do update set content = excluded.content, updated_at = now();
end $$;

create or replace function public.set_vision_link(p_kind text, p_id uuid, p_linked boolean)
returns void
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  if p_kind = 'goal' then
    update public.goals set linked_to_vision = coalesce(p_linked, false)
    where id = p_id and user_id = auth.uid();
  elsif p_kind = 'project' then
    update public.projects set linked_to_vision = coalesce(p_linked, false)
    where id = p_id and user_id = auth.uid();
  else
    raise exception 'invalid_kind' using errcode = '22023';
  end if;
  if not found then
    raise exception 'item_not_found' using errcode = 'P0002';
  end if;
end $$;

do $$
declare f text;
begin
  foreach f in array array['public.vision_overview()', 'public.save_vision(text)',
    'public.set_vision_link(text, uuid, boolean)'] loop
    execute format('revoke all on function %s from public, anon', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;

commit;
