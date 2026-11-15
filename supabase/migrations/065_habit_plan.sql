-- Migración 065 · Plan de hábito de Nevi (requiere 011 y 039).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- La IA (Edge Function npc-mission en modo hábito) propone un plan al estilo
-- Atomic Habits / Tiny Habits: la versión mínima de 2 minutos, el disparador
-- («después de X, hago Y»), la recompensa y por qué importa. Para un mal
-- hábito: cómo evitar el disparador y con qué reemplazarlo.
--   · habits.plan jsonb {tiny, cue, reward, why} (null = sin plan).
--   · attach_habit_plan(hábito, plan): solo el dueño; recorta cada campo.
-- La app lo lee con el select de habits (RLS «own rows»).

begin;

alter table public.habits add column if not exists plan jsonb;

create or replace function public.attach_habit_plan(p_habit_id uuid, p_plan jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_plan jsonb;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  v_plan := jsonb_strip_nulls(jsonb_build_object(
    'tiny', nullif(left(trim(coalesce(p_plan ->> 'tiny', '')), 200), ''),
    'cue', nullif(left(trim(coalesce(p_plan ->> 'cue', '')), 200), ''),
    'reward', nullif(left(trim(coalesce(p_plan ->> 'reward', '')), 200), ''),
    'why', nullif(left(trim(coalesce(p_plan ->> 'why', '')), 300), '')));
  if v_plan ->> 'tiny' is null then
    raise exception 'invalid_plan' using errcode = '22023';
  end if;
  update public.habits set plan = v_plan
  where id = p_habit_id and user_id = auth.uid();
  if not found then
    raise exception 'habit_not_found' using errcode = 'P0002';
  end if;
  return v_plan;
end $$;

revoke all on function public.attach_habit_plan(uuid, jsonb) from public, anon;
grant execute on function public.attach_habit_plan(uuid, jsonb) to authenticated;

commit;

notify pgrst, 'reload schema';
