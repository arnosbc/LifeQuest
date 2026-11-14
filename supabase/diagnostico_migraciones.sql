-- Diagnóstico: ¿qué migraciones faltan en esta base de datos?
-- Pegar completo en Supabase → SQL Editor → Run. Solo lee; no cambia nada
-- (salvo pedirle a la API que recargue su lista de funciones).
--
-- Resultado: una fila por migración con una función que no existe.
-- Sin filas = están todas.

notify pgrst, 'reload schema';

select m.migracion, m.funcion
from (values
  ('009_profile_titles',  'profile_overview'),
  ('010_missions',        'missions_overview'),
  ('011_habits',          'habits_overview'),
  ('012_dungeon',         'dungeon_overview'),
  ('013_stage',           'stage_overview'),
  ('014_goals',           'create_goal'),
  ('015_onboarding',      'complete_onboarding'),
  ('016_settings',        'settings_overview'),
  ('018_marketplace',     'market_overview'),
  ('019_tavern',          'tavern_overview'),
  ('020_journal',         'journal_overview'),
  ('021_boss_fight',      'goals_overview'),
  ('022_rpgenie',         'current_mission'),
  ('023_brain_dump',      'brain_dump_overview'),
  ('024_vision_board',    'vision_overview'),
  ('025_stats',           'stats_overview'),
  ('026_inventory',       'inventory_overview'),
  ('027_daily_chest',     'daily_chest_status'),
  ('028_edit_delete',     'rename_task'),
  ('029_notifications',   'notifications_overview'),
  ('031_npc_mission_guide','attach_task_guide'),
  ('032_npc_documents',   'add_npc_document'),
  ('034_brain_dump_goal', 'convert_thought_to_goal'),
  ('035_resources',       'create_resource'),
  ('036_device_notifications','register_device'),
  ('039_task_steps',      'toggle_task_step'),
  ('048_daily_reminders', '_generate_reminders'),
  ('050_push_fcm',        'set_push_token'),
  ('052_challenges_league','challenges_overview')
) as m(migracion, funcion)
where not exists (
  select 1 from pg_proc
  where proname = m.funcion and pronamespace = 'public'::regnamespace
)
order by m.migracion;
