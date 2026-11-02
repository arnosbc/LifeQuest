-- Migración 046 · Taller de documentos (requiere 001–045).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- Documentos que el usuario redacta en la app (RF-117…RF-122, specs/006):
--   · El contenido es Markdown. El móvil guarda primero en el dispositivo y
--     sincroniza aquí: el id lo genera el cliente y gana el updated_at más nuevo.
--   · Borrar deja deleted_at (una marca) para que el borrado llegue a los demás
--     dispositivos; nunca se borra la fila desde el cliente.
--   · task_id vincula el documento a una tarea (ON DELETE SET NULL).
-- No toca la economía: el cliente escribe directo en la tabla, protegida por RLS.

begin;

create table if not exists public.documents (
  id uuid primary key,
  user_id uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  task_id uuid references public.tasks (id) on delete set null,
  title text not null default 'Sin título',
  content text not null default '',
  template text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  constraint documents_title_length check (char_length(title) between 1 and 120),
  -- ~1 MB de texto: de sobra para un trabajo, y evita filas enormes.
  constraint documents_content_length check (char_length(content) <= 1000000)
);

create index if not exists documents_user_updated_idx
  on public.documents (user_id, updated_at desc);

alter table public.documents enable row level security;

drop policy if exists "documents: leer lo propio" on public.documents;
create policy "documents: leer lo propio" on public.documents
  for select to authenticated using (user_id = auth.uid());

drop policy if exists "documents: crear lo propio" on public.documents;
create policy "documents: crear lo propio" on public.documents
  for insert to authenticated with check (user_id = auth.uid());

drop policy if exists "documents: editar lo propio" on public.documents;
create policy "documents: editar lo propio" on public.documents
  for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Sin política de DELETE: el borrado es la marca deleted_at.
revoke delete on public.documents from authenticated, anon;
grant select, insert, update on public.documents to authenticated;

commit;
