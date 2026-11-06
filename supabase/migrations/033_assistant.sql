-- Migración 033 · Asistente con IA (rework fase 3, docs/plan-rework.md).
-- Requiere 001–032. Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- 1. game_master_settings.ai_enabled: apagado por defecto. En la capa gratis
--    de Gemini, Google puede usar el texto enviado; el usuario lo activa a sabiendas.
-- 2. ai_usage + consume_ai_call(): tope diario por usuario (game_rules.ai_daily_limit).
--    La Edge Function `assistant` la llama con el JWT del usuario antes de ir a Gemini.
-- 3. assistant_status(): si la IA está activa y cuántas llamadas quedan hoy.
-- 4. settings_overview devuelve ai_enabled.

begin;

-- 1. Interruptor ------------------------------------------------------------------
alter table public.game_master_settings
  add column if not exists ai_enabled boolean not null default false;
grant update (ai_enabled) on public.game_master_settings to authenticated;

-- 2. Tope diario -------------------------------------------------------------------
insert into public.game_rules (key, value, provisional, note)
values ('ai_daily_limit', 40, true, 'Llamadas de IA por usuario al día (capa gratis de Gemini)')
on conflict (key) do nothing;

create table if not exists public.ai_usage (
  user_id uuid not null references public.profiles(id) on delete cascade,
  day date not null,
  calls integer not null default 0,
  primary key (user_id, day)
);
alter table public.ai_usage enable row level security;
drop policy if exists "read own rows" on public.ai_usage;
create policy "read own rows" on public.ai_usage for select using (auth.uid() = user_id);
-- Solo consume_ai_call escribe.
revoke insert, update, delete on public.ai_usage from authenticated, anon;
grant select on public.ai_usage to authenticated;

-- Cuenta una llamada y devuelve las que quedan hoy. Falla con ai_disabled o
-- ai_limit sin contar nada.
create or replace function public.consume_ai_call()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_limit integer := coalesce(public.rule('ai_daily_limit'), 40)::integer;
  v_calls integer;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  if not coalesce((select ai_enabled from public.game_master_settings where user_id = v_uid), false) then
    raise exception 'ai_disabled' using errcode = '42501';
  end if;
  insert into public.ai_usage as u (user_id, day, calls)
  values (v_uid, current_date, 1)
  on conflict (user_id, day) do update set calls = u.calls + 1
    where u.calls < v_limit
  returning calls into v_calls;
  if v_calls is null then
    raise exception 'ai_limit' using errcode = 'P0001';
  end if;
  return v_limit - v_calls;
end $$;

-- 3. Estado del asistente ---------------------------------------------------------
create or replace function public.assistant_status()
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  select jsonb_build_object(
    'ai_enabled', coalesce((select ai_enabled from public.game_master_settings
                            where user_id = auth.uid()), false),
    'calls_left', greatest(0, coalesce(public.rule('ai_daily_limit'), 40)::integer - coalesce((
      select calls from public.ai_usage where user_id = auth.uid() and day = current_date), 0))
  )
$$;

-- 4. Ajustes con el interruptor (cuerpo de 016 más ai_enabled) -----------------------
create or replace function public.settings_overview()
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  select jsonb_build_object(
    'level', s.level,
    'current_xp', s.current_xp,
    'xp_to_next_level', s.xp_to_next_level,
    'difficulty', g.difficulty,
    'notification_daily_limit', g.notification_daily_limit,
    'silence_window_start', to_char(g.silence_window_start, 'HH24:MI'),
    'silence_window_end', to_char(g.silence_window_end, 'HH24:MI'),
    'critical_bypass_silence', g.critical_bypass_silence,
    'short_break_minutes', g.short_break_minutes,
    'long_break_minutes', g.long_break_minutes,
    'long_break_every_n_cycles', g.long_break_every_n_cycles,
    'ai_enabled', coalesce(g.ai_enabled, false),
    'difficulties', (
      select coalesce(jsonb_agg(jsonb_build_object(
        'level', dl.level,
        'xp_multiplier', dl.xp_multiplier,
        'hp_penalty_multiplier', dl.hp_penalty_multiplier,
        'coin_multiplier', dl.coin_multiplier
      ) order by dl.level), '[]'::jsonb)
      from public.difficulty_levels dl
    )
  )
  from public.profiles p
  left join public.character_stats s on s.user_id = p.id
  left join public.game_master_settings g on g.user_id = p.id
  where p.id = auth.uid()
$$;

-- Permisos -----------------------------------------------------------------------------
do $$
declare f text;
begin
  foreach f in array array['public.consume_ai_call()', 'public.assistant_status()',
    'public.settings_overview()'] loop
    execute format('revoke all on function %s from public, anon', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;

commit;
