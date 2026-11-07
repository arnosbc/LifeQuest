-- Migración 043 · Avisos que abren su acción (rework, mejoras).
-- Requiere 001–042. Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- notifications_overview devolvía título y texto, pero no de qué trataba el aviso:
-- la app no podía llevar al usuario a la tarea, el hábito o el proyecto. Se
-- envuelve la función (como 031 con stage_overview) y cada item suma su
-- `category` (streak, project, level, due…) desde public.notifications.

begin;

do $$
begin
  if to_regprocedure('public.notifications_overview_before_targets(date)') is null then
    alter function public.notifications_overview(date)
      rename to notifications_overview_before_targets;
  end if;
end $$;

create or replace function public.notifications_overview(p_day date)
returns jsonb
language plpgsql
volatile
security invoker
set search_path = ''
as $$
declare
  v_data jsonb;
begin
  -- Primero genera los avisos; la lectura de abajo ya ve las filas nuevas.
  v_data := public.notifications_overview_before_targets(p_day);
  return jsonb_set(v_data, '{items}', coalesce((
    select jsonb_agg(item || jsonb_build_object('category', n.category) order by ord)
    from jsonb_array_elements(coalesce(v_data->'items', '[]'::jsonb))
      with ordinality as e(item, ord)
    left join public.notifications n on n.id = (item->>'id')::uuid
  ), '[]'::jsonb), true);
end $$;

revoke all on function public.notifications_overview(date) from public, anon;
grant execute on function public.notifications_overview(date) to authenticated;
revoke all on function public.notifications_overview_before_targets(date) from public, anon;
grant execute on function public.notifications_overview_before_targets(date) to authenticated;

commit;
