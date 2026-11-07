-- Migración 035 · Limpieza del juego retirado (deuda de la fase 1 del rework).
-- Requiere 001–034. Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
-- ⚠️ Borra tablas y sus datos. La base es la misma que usaban las ramas viejas:
-- solo aplicarla cuando ninguna app de esas ramas apunte a este proyecto.
--
-- 1. notifications_overview sin el aviso del Cofre (ya no existe) y con
--    «tarea» en vez de «misión».
-- 2. Se borran las RPC de Tienda, Mercado negro, Pases, Refugio, Elixir, Cofre,
--    Taverna/NPCs, Vision Board, Inventario, títulos y Boss Fight que la app ya
--    no llama.
-- 3. Se borran las tablas que solo usaban esas RPC.
--
-- shortcut: quedan tablas que todavía leen funciones vivas: user_consumables
-- (complete_dungeon_cycle), refuge_upgrades y daily_runs (daily_maintenance),
-- achievements (journal_overview), titles/user_titles (profile_overview), y la
-- economía de Monedas/HP en character_stats y quest_log_entries (_award).
-- Quitarlas exige reescribir esas funciones; hacerlo en una migración aparte.

begin;

-- 1. Avisos sin el Cofre (cuerpo de 029) -------------------------------------------
create or replace function public.notifications_overview(p_day date)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_reduced text[];
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  select coalesce(array_agg(category), '{}') into v_reduced
  from public.notification_category_state where user_id = v_uid and reduced;

  insert into public.notifications (user_id, type, category, event_key, title, message,
                                    related_entity_type, related_entity_id, sent_at)
  select v_uid, x.type::public.notification_type, x.category, x.key, x.title, x.message,
         x.entity_type, x.entity_id, now()
  from (
    -- ▲ Racha en riesgo (tono de invitación, nunca de amenaza).
    select 'critical' type, 'streak' category,
           'streak:' || h.id || ':' || p_day key,
           'Tu racha te está esperando 🔥' title,
           'Llevas ' || h.current_streak || ' días con «' || h.name || '». Hoy puedes sumar uno más.' message,
           'habit' entity_type, h.id entity_id
    from public.habits h
    where h.user_id = v_uid and h.type = 'good' and coalesce(h.current_streak, 0) > 0
      and (h.frequency = 'daily' or extract(dow from p_day)::int = any (h.specific_days))
      and not exists (select 1 from public.habit_records r
                      where r.habit_id = h.id and r.completed_on = p_day)
    union all
    -- ▲ Proyecto en 🔴.
    select 'critical', 'project', 'project:' || p.id || ':' || p_day,
           'Un proyecto necesita tu atención',
           '«' || p.title || '» va con el tiempo justo. Una tarea hoy lo pone al día.',
           'project', p.id
    from public.projects p
    cross join lateral (
      select count(*)::int total, count(*) filter (where t.status = 'completed')::int done
      from public.tasks t where t.project_id = p.id and t.parent_task_id is null) c
    where p.user_id = v_uid and p.archived_at is null and p.status in ('not_started', 'in_progress')
      and public._project_urgency(c.total, c.done, coalesce(p.start_date, p.created_at::date),
                                  p.end_date, p_day) = 'high'
    union all
    -- ● Cerca de subir de nivel.
    select 'motivational', 'level', 'level:' || v_uid || ':' || s.level,
           'Estás a un paso del nivel ' || (s.level + 1),
           'Te faltan ' || (s.xp_to_next_level - s.current_xp) || ' XP. Una tarea más y lo logras.',
           null, null
    from public.character_stats s
    where s.user_id = v_uid and s.current_xp >= s.xp_to_next_level * 0.9
      and not ('level' = any (v_reduced))
    union all
    -- ○ Lo que vence hoy.
    select 'informational', 'due', 'due:' || v_uid || ':' || p_day,
           'Tu día de hoy',
           case when n = 1 then 'Hoy vence 1 tarea. Tú decides cuándo.'
                else 'Hoy vencen ' || n || ' tareas. Tú decides el orden.' end,
           null, null
    from (select count(*) n from public.tasks
          where user_id = v_uid and parent_task_id is null
            and status in ('pending', 'in_progress')
            and due_date >= p_day::timestamptz and due_date < (p_day + 1)::timestamptz) d
    where n > 0 and not ('due' = any (v_reduced))
  ) x
  on conflict (user_id, event_key) where event_key is not null do nothing;

  return jsonb_build_object(
    'items', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', n.id, 'type', n.type, 'title', n.title, 'message', n.message,
        'created_at', n.created_at, 'read', n.read_at is not null)
        order by n.created_at desc)
      from (select * from public.notifications where user_id = v_uid
            order by created_at desc limit 50) n
    ), '[]'::jsonb),
    'unread', (select count(*) from public.notifications
               where user_id = v_uid and read_at is null)
  );
end $$;

-- 2. RPC del juego retirado -----------------------------------------------------------
-- Se borran todas las sobrecargas de cada nombre.
do $$
declare r record;
begin
  for r in
    select p.oid::regprocedure as sig
    from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = any (array[
      'accept_npc_mission', 'activate_elixir', 'buy_black_market', 'claim_daily_chest',
      'create_npc', 'delete_npc', 'rename_npc', 'request_npc_mission', 'tavern_overview',
      'current_mission', 'daily_chest_status', 'goals_overview', 'inventory_overview',
      'market_overview', 'purchase', 'save_vision', 'set_vision_link', 'vision_overview',
      'set_active_title', 'upgrade_refuge', 'use_recovery_pass', '_spend', '_restore_streak'])
  loop
    execute format('drop function if exists %s', r.sig);
  end loop;
end $$;

-- 3. Tablas que solo usaban esas RPC ---------------------------------------------------
-- cascade quita también la vista v_user_store, las FK que apuntan a npcs
-- (tasks.npc_id y resources.npc_id quedan como columnas sueltas) y sus triggers.
drop view if exists public.v_user_store;
drop table if exists public.user_market_selection cascade;
drop table if exists public.purchases cascade;
drop table if exists public.market_items cascade;
drop table if exists public.black_market_redemptions cascade;
drop table if exists public.black_market_items cascade;
drop table if exists public.recovery_passes cascade;
drop table if exists public.vision_boards cascade;
drop table if exists public.user_inventory cascade;
drop table if exists public.inventory_items cascade;
drop table if exists public.npcs cascade;
drop function if exists public.enforce_npc_limit();

commit;
