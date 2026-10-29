-- 018 · Inicio de sesión con Google y Apple
-- El registro con correo guarda el nombre en `username`; Google y Apple lo
-- traen en `full_name` o `name`. Sin esto, el perfil de esas cuentas nace
-- sin nombre visible. Igual que en 002, el nombre se recorta a 40 caracteres
-- para que el alta nunca falle por su longitud.

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
    nullif(left(trim(coalesce(
      nullif(trim(new.raw_user_meta_data ->> 'username'), ''),
      nullif(trim(new.raw_user_meta_data ->> 'full_name'), ''),
      new.raw_user_meta_data ->> 'name'
    )), 40), '')
  )
  on conflict (id) do nothing;
  insert into public.character_stats (user_id) values (new.id)
  on conflict (user_id) do nothing;
  insert into public.game_master_settings (user_id) values (new.id)
  on conflict (user_id) do nothing;
  return new;
end $$;
