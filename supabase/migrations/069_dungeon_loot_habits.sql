-- Migración 069 · El botín de Foco cuenta los hábitos cumplidos en la sesión
-- (requiere 066 y 068). Ejecutar una vez en Supabase → SQL Editor. Se puede
-- volver a ejecutar.
--
-- Prueba en el teléfono (2026-11-16): un hábito marcado dentro de Foco subía
-- la XP del personaje, pero «Recompensas de la sesión» y el resumen no lo
-- sumaban. Ahora _dungeon_loot (cuerpo de 066) suma también los hábitos de la
-- sesión (focus_session_habits) cobrados mientras estaba abierta.

begin;

create or replace function public._dungeon_loot(p_session_id uuid)
returns table (xp bigint, coins bigint, missions bigint)
language sql
stable
security invoker
set search_path = ''
as $$
  with s as (
    select * from public.focus_sessions where id = p_session_id
  ),
  q as (
    select q.xp_awarded, q.coin_awarded, q.source_type
    from public.quest_log_entries q, s
    where q.user_id = s.user_id
      and (
        (q.source_type = 'dungeon'
         and q.source_id in (select r.id from public.dungeon_runs r where r.session_id = s.id))
        or
        (q.source_type in ('task', 'npc')
         and q.result = 'completed'
         and q.occurred_at >= s.started_at
         and q.occurred_at <= coalesce(s.ended_at, now())
         and q.source_id in (select f.task_id from public.focus_session_tasks f
                             where f.session_id = s.id))
        or
        -- 066: pasos de las tareas de la mochila pagados durante la sesión.
        (q.source_type = 'task_step'
         and q.occurred_at >= s.started_at
         and q.occurred_at <= coalesce(s.ended_at, now())
         and q.source_id in (select ts.id from public.task_steps ts
                             join public.focus_session_tasks f on f.task_id = ts.task_id
                             where f.session_id = s.id))
        or
        -- 069: hábitos de la sesión cumplidos mientras estaba abierta.
        (q.source_type = 'habit'
         and q.occurred_at >= s.started_at
         and q.occurred_at <= coalesce(s.ended_at, now())
         and q.source_id in (select fh.habit_id from public.focus_session_habits fh
                             where fh.session_id = s.id))
      )
  )
  select coalesce(sum(xp_awarded), 0),
         coalesce(sum(coin_awarded), 0),
         count(*) filter (where source_type in ('task', 'npc'))
  from q
$$;

commit;
