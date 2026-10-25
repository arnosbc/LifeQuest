# Research: Actualización del Perfil

No quedaban `NEEDS CLARIFICATION` (las dos dudas de la spec se cerraron el 2026-10-20). Estas son las decisiones técnicas.

## R1. Datos nuevos en la misma carga

- **Decision**: `009_profile_titles.sql` redefine `profile_overview()` con `create or replace`, copiando el cuerpo de 002 y añadiendo `treasury`, `active_title` (objeto o `null`) y `titles` (lista de ganados, `[]` si ninguno).
- **Rationale**: FR-007 y SC-005 piden una sola carga; la función ya es `security invoker`, así que `user_titles` se lee con su RLS «read own rows» y `titles` con «read all» para autenticados. `create or replace` es idempotente y no toca 002.
- **Alternatives considered**: una RPC aparte `profile_titles()` (dos peticiones, rompe SC-005); una vista (el Perfil ya consume JSON de la RPC).

## R2. Elegir el título activo

- **Decision**: RPC `set_active_title(p_title_id uuid) returns void`, `plpgsql`, `security invoker`, `set search_path = ''`: si `auth.uid()` es null → `not_authenticated`; si no, `update public.profiles set active_title_id = p_title_id where id = auth.uid()`. `null` quita el título. El trigger `trg_check_active_title` (004) rechaza un título no ganado con `title_not_earned` (`42501`).
- **Rationale**: la validación ya vive en un solo sitio (el trigger) y cubre también un `update` directo por PostgREST. Un título inexistente tampoco está en `user_titles`, así que da el mismo `title_not_earned` antes del error de FK. `security invoker` basta porque el cliente ya puede actualizar su fila de `profiles` (RLS «own rows»).
- **Alternatives considered**: `security definer` con validación propia (duplica el trigger); actualizar `profiles` directo desde la app como hace `updateIdentity` (el usuario pidió RPC y deja un contrato estable si luego se revoca el grant).

## R3. Título retirado del catálogo

- **Decision**: nada nuevo. `profiles.active_title_id` y `user_titles.title_id` ya tienen `on delete set null` / `on delete cascade` (004): al borrar un título, el jugador queda sin título activo y desaparece de sus ganados.
- **Rationale**: cumple el edge case sin código; se cubre con una prueba SQL.

## R4. Forma del JSON y del dominio

- **Decision**: `active_title: {id, name, description}`, `titles: [{id, name, description, earned_at}]` ordenada por `earned_at`. En Dart, entidad `PrestigeTitle(id, name, description?)` en `character_profile.dart` (como `Skill`) y en `CharacterProfile`: `treasury`, `activeTitle` (`PrestigeTitle?`) y `earnedTitles` (`List<PrestigeTitle>`). `earned_at` no se expone en el dominio (nadie lo muestra).
- **Rationale**: misma convención que `skills` en el JSON y en el model (`_int`, `_text`, valores por defecto si falta la clave, para no romper con un servidor sin 009).
- **Alternatives considered**: devolver solo `active_title_id` y buscarlo en la lista (más lógica en el cliente).

## R5. Cambio de título en el Bloc

- **Decision**: usecase `SetActiveTitle implements UseCase<Unit, String?>` y evento `ProfileActiveTitleChanged(String? titleId)` manejado con el `_save` existente (`droppable`, relee el perfil). Mensajes: «Ahora luces «X».» / «Ya no muestras ningún título.». En error, se conserva el perfil anterior con el mensaje del repositorio.
- **Rationale**: reutiliza el patrón de identidad y skills; el título anterior queda intacto en `ProfileSuccess` si falla (edge case de red).

## R6. Mensaje de `title_not_earned`

- **Decision**: en `ProfileRepositoryImpl._messageFor`: `('title_not_earned', _)` → «Ese título todavía no es tuyo. Los títulos se ganan con logros, nivel y Tesoro.»
- **Rationale**: tono de invitación y misma tabla de mensajes que el resto del Perfil.

## R7. Accesos sin importar otras features

- **Decision**: `ProfileScreen` recibe `onOpenJournal`, `onOpenMarketplace` y `onOpenSettings` (ya existe); se quita `onOpenAppearance`. `app_router.dart` los conecta con `context.push(RoutePaths.journal / marketplace / settings)`. Estadísticas, Vision Board e Inventario y logros usan el `soon(...)` actual. Los 6 accesos van en dos filas de 3 `ProfileQuickLink` (`Expanded`), para caber en teléfono sin desplazamiento horizontal.
- **Rationale**: regla 6 de la arquitectura (la composición vive en `app/`); `ProfileQuickLink` ya existe.
- **Alternatives considered**: una fila de 6 (etiquetas ilegibles a 360 px); `Wrap` (anchos desiguales).

## R8. Apariencia en Configuración

- **Decision**: `RoutePaths.appearance` pasa a `/settings/appearance` y el `GoRoute` de Apariencia se mueve como hijo de `/settings` (sigue en `_themedPaths`, con `context.lq`). `SettingsScreen` recibe `onOpenAppearance` y `GameMasterCard` añade un `SettingLink` «Apariencia» con el estilo de sus filas. El valor del modo no se muestra en la fila (leerlo exigiría que `settings` importe `AppearanceBloc` de `profile`).
- **Rationale**: Apariencia deja de estar en la rama de Perfil del shell; abrirla desde Configuración no cambia de pestaña. `AppearanceBloc` y `shared_preferences` no cambian (FR-014).
- **Alternatives considered**: hacer `push('/profile/appearance')` desde `/settings` (salta a la pestaña Perfil y apila raro); pasar la etiqueta del modo desde el router (más cableado para un dato secundario).

## R9. Pruebas SQL

- **Decision**: `supabase/tests/009_profile_titles.test.mjs`: `createFullDb()`, aplicar 003–008, luego 009 **dos veces**; sembrar `titles` y `user_titles` como superusuario. Se añade al script `test` de `package.json`.
- **Rationale**: mismo arranque que `008_fix_exploits.test.mjs`; `profile_overview` depende de `treasury` (004) y de las tablas de títulos.
