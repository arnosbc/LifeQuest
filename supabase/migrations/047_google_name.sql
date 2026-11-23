-- Migración 047 · Acceso con Google: el perfil toma su nombre visible.
-- Requiere 001–046. Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- Google no envía `username` (lo pone el registro con correo); envía
-- `full_name` y `name`. Se usa el primero que tenga texto, recortado a 40.

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    left(coalesce(
      nullif(trim(new.raw_user_meta_data ->> 'username'), ''),
      nullif(trim(new.raw_user_meta_data ->> 'full_name'), ''),
      nullif(trim(new.raw_user_meta_data ->> 'name'), '')
    ), 40)
  )
  on conflict (id) do nothing;
  insert into public.character_stats (user_id) values (new.id)
  on conflict (user_id) do nothing;
  insert into public.game_master_settings (user_id) values (new.id)
  on conflict (user_id) do nothing;
  return new;
end $$;
