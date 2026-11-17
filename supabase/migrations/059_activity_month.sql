-- Migración 059 · Calendario de racha del Perfil (requiere 056).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- activity_month(día, desfase): la racha diaria (056) y, para el mes de ese
-- día, cuántas actividades reales hubo cada día local ({"14": 3, …}). Mismas
-- fuentes que _activity_streak: cofres, desafíos, logros y malos hábitos no cuentan.

begin;

create or replace function public.activity_month(
  p_day date,
  p_utc_offset_minutes integer default 0
)
returns jsonb
language sql
stable
-- invoker: lee quest_log_entries con su RLS (cada quien solo ve lo suyo).
security invoker
set search_path = ''
as $$
  with days as (
    select (q.occurred_at at time zone 'UTC'
            + make_interval(mins => p_utc_offset_minutes))::date as d
    from public.quest_log_entries q
    where q.user_id = auth.uid()
      and q.result = 'completed'
      and q.source_type::text in ('task', 'npc', 'habit', 'dungeon', 'task_step', 'project', 'goal')
      -- Un día de margen a cada lado; el desfase decide en qué día local cae.
      and q.occurred_at >= date_trunc('month', p_day) - interval '1 day'
      and q.occurred_at < date_trunc('month', p_day) + interval '1 month 1 day'
  )
  select jsonb_build_object(
    'streak', public._activity_streak(auth.uid(), p_day, p_utc_offset_minutes),
    'days', coalesce((
      select jsonb_object_agg(extract(day from d)::int, n)
      from (select d, count(*)::int n from days
            where date_trunc('month', d) = date_trunc('month', p_day)
            group by d) c
    ), '{}'::jsonb))
$$;

revoke all on function public.activity_month(date, integer) from public, anon;
grant execute on function public.activity_month(date, integer) to authenticated;

commit;

notify pgrst, 'reload schema';
