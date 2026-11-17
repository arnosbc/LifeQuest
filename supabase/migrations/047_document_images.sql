-- Migración 047 · Imágenes de los documentos del Taller (requiere 046).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- Bucket privado `documents` (máx. 10 MB por imagen). Ruta de cada archivo:
--   <user_id>/<document_id>/<archivo>
-- Cada usuario solo lee, sube, reemplaza y borra dentro de su carpeta. El
-- documento guarda la imagen como ![texto](img/<archivo>); el móvil la busca
-- primero en el teléfono y, si falta, la descarga de aquí.

begin;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('documents', 'documents', false, 10485760,
        array['image/jpeg', 'image/png', 'image/webp', 'image/gif'])
on conflict (id) do update
  set public = false,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "documents: leer lo propio" on storage.objects;
create policy "documents: leer lo propio" on storage.objects
  for select to authenticated
  using (bucket_id = 'documents' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "documents: subir a lo propio" on storage.objects;
create policy "documents: subir a lo propio" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'documents' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "documents: reemplazar lo propio" on storage.objects;
create policy "documents: reemplazar lo propio" on storage.objects
  for update to authenticated
  using (bucket_id = 'documents' and (storage.foldername(name))[1] = auth.uid()::text)
  with check (bucket_id = 'documents' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "documents: borrar lo propio" on storage.objects;
create policy "documents: borrar lo propio" on storage.objects
  for delete to authenticated
  using (bucket_id = 'documents' and (storage.foldername(name))[1] = auth.uid()::text);

commit;
