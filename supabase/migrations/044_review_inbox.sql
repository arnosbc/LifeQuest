-- Migración 044 · La Bandeja entra al cierre del día (rework, mejoras).
-- Requiere 001–043. Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- Lo que se anota en la Bandeja y no se decide se acumulaba en silencio. La
-- revisión (cierre del día y de la semana) ahora cuenta las notas pendientes
-- (`inbox`) para invitar a decidirlas. Se envuelve weekly_review (como 031).

begin;

do $$
begin
  if to_regprocedure('public.weekly_review_before_inbox(date, integer)') is null then
    alter function public.weekly_review(date, integer)
      rename to weekly_review_before_inbox;
  end if;
end $$;

create or replace function public.weekly_review(
  p_day date,
  p_utc_offset_minutes integer default 0
)
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  select public.weekly_review_before_inbox(p_day, p_utc_offset_minutes)
    || jsonb_build_object('inbox', (
         select count(*) from public.brain_dump_entries
         where user_id = auth.uid() and status = 'pending'))
$$;

revoke all on function public.weekly_review(date, integer) from public, anon;
grant execute on function public.weekly_review(date, integer) to authenticated;
revoke all on function public.weekly_review_before_inbox(date, integer) from public, anon;
grant execute on function public.weekly_review_before_inbox(date, integer) to authenticated;

commit;
