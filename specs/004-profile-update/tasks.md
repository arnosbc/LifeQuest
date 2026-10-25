---

description: "Lista de tareas: actualización del Perfil (vitalidad, Tesoro, títulos y accesos)"
---

# Tasks: Actualización del Perfil (vitalidad, Tesoro, títulos y accesos)

**Input**: Design documents from `specs/004-profile-update/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/rpc.md, contracts/ui.md, quickstart.md

**Tests**: obligatorios (constitución IV) y **primero**, en SQL y en Flutter: en cada historia la prueba se escribe y se ejecuta **antes** del código, y se confirma que **falla** por la razón esperada (la clave, el método o el texto todavía no existen). Después se implementa y la misma prueba pasa.

**Organization**: una fase por historia de la spec, en orden de prioridad (US1, US2 P1; US3, US4 P2).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: se puede hacer en paralelo (otro archivo, sin dependencias pendientes)
- **[Story]**: historia de la spec (US1…US4)

## Convenciones

- **SQL:** estilo de 002/008: `begin; … commit;`, `create or replace function`, `set search_path = ''`, nombres calificados `public.`, `revoke`/`grant` al final, comentario en español por bloque. 009 no edita 001–008.
- **Pruebas SQL:** arranque como `supabase/tests/008_fix_exploits.test.mjs` (`createFullDb()`, aplicar `003_security.sql`…`008_fix_exploits.sql`, luego 009 **dos veces**; `asUser`, `rejects`, `ok`, `one` de `bootstrap.mjs`). Títulos sembrados como superusuario en `titles` y `user_titles`. Ejecutar: `cd supabase/tests && node 009_profile_titles.test.mjs`. Un `assert` fallido corta el script: la sección nueva va siempre al final.
- **Flutter:** imports `package:proyecto_movil/...`; mocks en `test/helpers/mocks.dart` (mocktail + bloc_test); datos de prueba en `test/features/profile/profile_fixtures.dart`. Ejecutar: `flutter test test/features/profile`.
- Textos exactos en `contracts/ui.md` y `contracts/rpc.md`.

---

## Phase 1: Setup

**Purpose**: migración y script de pruebas vacíos, listos para ver fallar la primera regla.

- [X] T001 Crear `supabase/migrations/009_profile_titles.sql` solo con la cabecera de comentarios (qué hace, que requiere 001–008, que se puede volver a ejecutar; lista: 1. `profile_overview` con Tesoro y títulos, 2. RPC `set_active_title`) y `begin; commit;` vacío
- [X] T002 Crear `supabase/tests/009_profile_titles.test.mjs` con el arranque: `createFullDb()`, aplicar 003–008 en orden, aplicar `009_profile_titles.sql` dos veces, insertar `U1` (`{"username":"Ana"}`) y `U2` en `auth.users`, y `ok('009 se aplica dos veces sin error')`
- [X] T003 Añadir `&& node 009_profile_titles.test.mjs` al final del script `test` de `supabase/tests/package.json`
- [X] T004 Ejecutar `npm test` en `supabase/tests` y `flutter test test/features/profile`; confirmar que todo pasa antes de empezar

---

## Phase 2: Foundational

**Purpose**: ninguna. Las piezas compartidas (entidad y JSON ampliados) nacen en US2, que es la primera historia que las necesita; US1 no depende de ellas.

---

## Phase 3: User Story 1 - Entender la vitalidad baja (Priority: P1) 🎯 MVP

**Goal**: el aviso de vitalidad dice la regla vigente (−25 % de XP, Monedas iguales) y solo aparece con `is_weakened` del servidor (FR-001, FR-002).

**Independent Test**: Perfil con `isWeakened: true` muestra el aviso nuevo; con `false`, ninguno.

### Tests (escribir primero y ver fallar) ⚠️

- [X] T005 [US1] En `test/features/profile/presentation/screens/profile_screen_test.dart`, añadir `testWidgets('vitalidad baja explica la regla vigente', …)`: con un perfil copia de `profile` con `hpCurrent: 29, isWeakened: true`, espera el texto «Vitalidad baja: ganas un 25 % menos de XP hasta recuperarte. Tus Monedas no cambian.» y el icono `Icons.heart_broken_outlined`; con `profile` (`isWeakened: false`, `hpCurrent: 80`), `findsNothing` para «Vitalidad baja»
- [X] T006 [US1] Ejecutar `flutter test test/features/profile/presentation/screens/profile_screen_test.dart` y confirmar que **falla** (el texto sigue diciendo «10 % menos»)

### Implementation

- [X] T007 [US1] En `lib/features/profile/presentation/widgets/hero_status_card.dart`, cambiar el texto del aviso por el de T005 (sin tocar estilos ni la condición `p.isWeakened`)
- [X] T008 [US1] Ejecutar el test de T006 y confirmar que pasa

**Checkpoint**: el aviso ya no miente sobre la penalización.

---

## Phase 4: User Story 2 - Ver mi prestigio (Priority: P1)

**Goal**: `profile_overview` devuelve Tesoro, título activo y títulos ganados en la misma carga; el Perfil muestra el título bajo el nombre y la fila Tesoro del reino (FR-003, FR-004, FR-007).

**Independent Test**: un jugador con Tesoro y título activo los ve; otro sin nada no ve título y ve Tesoro 0.

### Tests SQL (escribir primero y ver fallar) ⚠️

- [X] T009 [US2] En `supabase/tests/009_profile_titles.test.mjs`, sección «US2»: como `U1` (sin títulos), `select profile_overview() r` → `r.treasury === 0`, `r.active_title === null`, `r.titles` es `[]`, y siguen las claves de 002 (`display_name === 'Ana'`, `skills` es lista); como superusuario poner `treasury = 12500` a `U1`, sembrar dos títulos en `titles` (`code` 'guardian'/'explorador') y en `user_titles` para `U1` con `earned_at` distintos, y fijar `profiles.active_title_id` al primero; releer: `treasury === 12500`, `active_title` `{id, name, description}` del primero, `titles` con los dos en orden de `earned_at` y cada uno con `id, name, description, earned_at`
- [X] T010 [US2] En la misma sección: como `U2`, `profile_overview` → `treasury === 0`, `titles` `[]`, `active_title === null` (no ve los de `U1`); como superusuario borrar el primer título de `titles` → como `U1`, `active_title === null` y `titles` con un elemento, sin error; `ok('009: profile_overview trae Tesoro y títulos, aislados por jugador')`
- [X] T011 [US2] Ejecutar `node 009_profile_titles.test.mjs` y confirmar que **falla** en T009 (`treasury` es `undefined`)

### Tests Flutter (escribir primero y ver fallar) ⚠️

- [X] T012 [P] [US2] En `test/features/profile/profile_fixtures.dart`: añadir a `profileJson` `'treasury': 12500`, `'active_title': {'id': 't1', 'name': 'Guardián del Huerto', 'description': 'Cuidaste tus hábitos 30 días.'}` y `'titles'` con `t1` y `t2` ('Explorador', `description: null`, con `earned_at`); constantes `guardianTitle` y `explorerTitle` (`PrestigeTitle`); a `profile` añadir `treasury: 12500, activeTitle: guardianTitle, earnedTitles: [guardianTitle, explorerTitle]` (`newProfile` sin cambios: usa los valores por defecto)
- [X] T013 [P] [US2] En `test/features/profile/data/models/character_profile_model_test.dart`: el test «convierte el JSON» ya cubre los campos nuevos vía `profile`; ampliar «un perfil sin datos usa los valores por defecto» para comprobar `treasury == 0`, `activeTitle == null`, `earnedTitles` vacío; añadir test: `active_title` con `name` en blanco o ausente → `activeTitle == null`
- [X] T014 [US2] En `test/features/profile/presentation/screens/profile_screen_test.dart`, añadir `testWidgets('muestra el título activo y el Tesoro', …)`: con `profile` → `find.text('Guardián del Huerto')`, `find.text('Tesoro del reino')`, `find.text('12.500')` y el texto «Lo que no cabe en tu bolsa. No se gasta: es tu prestigio.»; con `newProfile` → `findsNothing` para 'Guardián del Huerto', y el Tesoro muestra `'0'` con la misma explicación
- [X] T015 [US2] Ejecutar `flutter test test/features/profile` y confirmar que **no compila / falla** (`PrestigeTitle` y los campos nuevos no existen)

### Implementation

- [X] T016 [US2] En `supabase/migrations/009_profile_titles.sql`, bloque 1: `create or replace function public.profile_overview()` copiando el cuerpo de `002_profile.sql` (`language sql stable security invoker set search_path = ''`) y añadiendo `'treasury', coalesce(s.treasury, 0)`, `'active_title'` (`select jsonb_build_object('id', t.id, 'name', t.name, 'description', t.description) from public.titles t where t.id = p.active_title_id`, null si no hay) y `'titles'` (`coalesce(jsonb_agg(... 'earned_at', ut.earned_at ... order by ut.earned_at), '[]')` de `public.user_titles ut join public.titles t on t.id = ut.title_id where ut.user_id = p.id`); al final `revoke all … from public, anon` + `grant execute … to authenticated` (research R1)
- [X] T017 [US2] Ejecutar `node 009_profile_titles.test.mjs` y `npm test`; US2 pasa y 001–008 siguen en verde
- [X] T018 [US2] En `lib/features/profile/domain/entities/character_profile.dart`: clase `PrestigeTitle extends Equatable` (`id`, `name`, `description?`, doc en español «Título de prestigio: se gana, nunca se compra.»); en `CharacterProfile` añadir `treasury` (`required int`), `activeTitle` (`PrestigeTitle?`), `earnedTitles` (`List<PrestigeTitle>`, default `const []`), getter `hasTitles` y los tres campos en `props`
- [X] T019 [US2] En `lib/features/profile/data/models/character_profile_model.dart`: leer `treasury` con `_int`, `active_title` y `titles` con un `_title(Map?)` privado que devuelva `null` si falta `id` o el `name` está en blanco (usa `_text`); actualizar el doc de la clase para citar 009
- [X] T020 [US2] Actualizar las construcciones de `CharacterProfile` que ya no compilan (`treasury` requerido) en `lib/` y `test/` (buscar `CharacterProfile(`), sin cambiar su intención
- [X] T021 [US2] En `lib/features/profile/presentation/widgets/character_card.dart`: bajo el nombre, si `profile.activeTitle != null`, un `Text` con su nombre (`maxLines: 1`, `overflow: TextOverflow.ellipsis`, estilo de texto secundario ya usado en la tarjeta con `context.lq`); nada si es null
- [X] T022 [US2] En `lib/features/profile/presentation/widgets/hero_status_card.dart`: nueva `_StatusRow` «Tesoro del reino» tras Monedas, icono `Icons.account_balance_outlined`, `value: formatNumber(p.treasury)`, `detail: _detail(context, 'Lo que no cabe en tu bolsa. No se gasta: es tu prestigio.')`, con su `divider`; actualizar el doc de la clase
- [X] T023 [US2] Ejecutar `flutter test test/features/profile` y confirmar que pasan T013 y T014 y el resto de la feature

**Checkpoint**: el prestigio se ve con una sola carga.

---

## Phase 5: User Story 3 - Elegir mi título (Priority: P2)

**Goal**: elegir como activo un título ganado o ninguno, por RPC; rechazar los no ganados; estado vacío sin compra (FR-005, FR-005a, FR-006).

**Independent Test**: con dos títulos ganados, elegir uno, el otro y «Sin título»; un título ajeno se rechaza.

**Depends on**: US2 (`PrestigeTitle`, `earnedTitles` y los datos de `profile_overview`).

### Tests SQL (escribir primero y ver fallar) ⚠️

- [X] T024 [US3] En `supabase/tests/009_profile_titles.test.mjs`, sección «US3» al final: sembrar un título `t3` ganado solo por `U2`; como `U1`: `select set_active_title($1)` con su título restante → `profile_overview().active_title.id` es ese; `set_active_title(null)` → `active_title === null`; `set_active_title(t3)` → `rejects(…, /title_not_earned/)` y el activo no cambia; `set_active_title(gen_random_uuid())` → `/title_not_earned/`; `update profiles set active_title_id = '<t3>'` directo → `/title_not_earned/`
- [X] T025 [US3] En la misma sección: como `anon` (`set role anon`), `select set_active_title(null)` → `/permission denied/`; `ok('009: set_active_title solo activa títulos ganados')`
- [X] T026 [US3] Ejecutar `node 009_profile_titles.test.mjs` y confirmar que **falla** en T024 (`set_active_title` no existe)

### Tests Flutter (escribir primero y ver fallar) ⚠️

- [X] T027 [P] [US3] En `test/helpers/mocks.dart`: `class MockSetActiveTitle extends Mock implements SetActiveTitle {}` (con su import)
- [X] T028 [P] [US3] En `test/features/profile/domain/usecases/profile_usecases_test.dart`: `test('SetActiveTitle delega en el repositorio', …)` con `'t1'` y con `null`
- [X] T029 [P] [US3] En `test/features/profile/data/repositories/profile_repository_impl_test.dart`: `setActiveTitle('t1')` llama `remote.setActiveTitle('t1')` y devuelve `Right(unit)`; añadir a la tabla de errores `ServerException(code: 'title_not_earned', statusCode: '42501')` → «Ese título todavía no es tuyo. Los títulos se ganan con logros, nivel y Tesoro.»
- [X] T030 [US3] En `test/features/profile/presentation/blocs/profile_bloc_test.dart`: pasar `setActiveTitle: MockSetActiveTitle()` al constructor en `setUp`; `blocTest` éxito: semilla `ProfileSuccess(profile)`, evento `ProfileActiveTitleChanged('t2')` → `[saving, ProfileSuccess(reloaded, message: 'Ahora luces «Explorador».')]` (el mensaje usa el nombre del título en `earnedTitles`); con `null` → «Ya no muestras ningún título.»; fallo → `[saving, ProfileSuccess(profile, message: <mensaje del failure>)]` sin releer
- [X] T031 [US3] En `test/features/profile/presentation/screens/profile_screen_test.dart`: `testWidgets('elegir título envía el elegido', …)`: tocar «Elegir título» → la hoja lista «Sin título», «Guardián del Huerto» (marcado: `Icons.check` y `Semantics` seleccionado) y «Explorador»; tocar «Explorador» → `verify(() => bloc.add(const ProfileActiveTitleChanged('t2')))`; `testWidgets('sin títulos la hoja explica cómo se ganan', …)` con `newProfile`: «Elegir título» visible → hoja con «Aún no tienes títulos. Se ganan con logros, subiendo de nivel y llenando tu Tesoro del reino.» y `findsNothing` para `find.textContaining('Comprar')`
- [X] T032 [US3] Ejecutar `flutter test test/features/profile` y confirmar que **no compila / falla** (`SetActiveTitle`, `setActiveTitle` y el evento no existen)

### Implementation

- [X] T033 [US3] En `supabase/migrations/009_profile_titles.sql`, bloque 2: `create or replace function public.set_active_title(p_title_id uuid) returns void language plpgsql security invoker set search_path = ''`: `not_authenticated` (`28000`) si `auth.uid()` es null; `update public.profiles set active_title_id = p_title_id where id = auth.uid()`; comentario: el trigger `trg_check_active_title` de 004 rechaza lo no ganado (research R2); en permisos `revoke all … from public, anon` + `grant execute … to authenticated`
- [X] T034 [US3] Ejecutar `node 009_profile_titles.test.mjs` y `npm test`; todo en verde
- [X] T035 [US3] En `lib/features/profile/domain/repositories/profile_repository.dart`: `Future<Either<Failure, Unit>> setActiveTitle(String? titleId);` con doc («null quita el título»)
- [X] T036 [US3] Crear `lib/features/profile/domain/usecases/set_active_title.dart`: `class SetActiveTitle implements UseCase<Unit, String?>` con `call(titleId)` que delega (mismo estilo que `delete_skill.dart`)
- [X] T037 [US3] En `lib/features/profile/data/datasources/profile_remote_datasource.dart`: `Future<void> setActiveTitle(String? titleId)` en el contrato y en la impl: `_guard(() => _client.rpc<void>('set_active_title', params: {'p_title_id': titleId}))`
- [X] T038 [US3] En `lib/features/profile/data/repositories/profile_repository_impl.dart`: `setActiveTitle` con `_run` y el caso `('title_not_earned', _)` en `_messageFor` con el texto de T029
- [X] T039 [US3] En `lib/features/profile/presentation/blocs/profile_event.dart`: `class ProfileActiveTitleChanged extends ProfileEvent` (`final String? titleId`, `props`); en `profile_bloc.dart`: dependencia `required this._setActiveTitle`, handler con `_save(..., droppable())` y mensaje según research R5 (nombre buscado en `current.profile.earnedTitles`)
- [X] T040 [US3] En `lib/injection_container.dart`: `sl.registerLazySingleton(() => SetActiveTitle(sl()))` y `setActiveTitle: sl()` en la fábrica de `ProfileBloc`
- [X] T041 [US3] En `lib/features/profile/presentation/widgets/profile_sheets.dart`: función `showTitleSheet(BuildContext context, CharacterProfile profile)` que devuelve el elegido (`Future<TitleChoice?>`, con `TitleChoice(String? titleId)` para distinguir «Sin título» de cerrar sin elegir), siguiendo las hojas existentes del archivo; con títulos: «Sin título» + una fila por título (nombre, descripción si hay, `Icons.check` en el activo, `Semantics(selected: …)`, alto ≥ 48); sin títulos: el texto de estado vacío de `contracts/ui.md`, sin botones de compra
- [X] T042 [US3] En `lib/features/profile/presentation/widgets/character_card.dart`: parámetro `onChooseTitle` y botón de texto «Elegir título» siempre visible (alto ≥ 48, icono `Icons.workspace_premium_outlined` + texto); en `profile_screen.dart`: `chooseTitle()` abre `showTitleSheet` y, si hay elección, `bloc.add(ProfileActiveTitleChanged(choice.titleId))`
- [X] T043 [US3] Ejecutar `flutter test test/features/profile` y confirmar que todo pasa

**Checkpoint**: el jugador elige su título en 3 toques (Elegir título → título → listo), y nunca uno no ganado.

---

## Phase 6: User Story 4 - Ir a cada sección desde Perfil (Priority: P2)

**Goal**: 6 accesos en el orden del diseño; Apariencia sale de Perfil y entra en Configuración (FR-008, FR-009, FR-014).

**Independent Test**: tocar los 6 accesos; Configuración → Apariencia abre la pantalla actual.

### Tests (escribir primero y ver fallar) ⚠️

- [X] T044 [US4] En `test/features/profile/presentation/screens/profile_screen_test.dart`: pasar `onOpenJournal` y `onOpenMarketplace` (contadores) al construir `ProfileScreen` y quitar `onOpenAppearance`; `testWidgets('6 accesos en orden', …)`: las etiquetas «Diario», «Estadísticas», «Vision Board», «Inventario y logros», «Marketplace», «Configuración» existen y su `tester.getTopLeft` respeta ese orden (fila 1 izquierda→derecha, luego fila 2); `findsNothing` para «Historial», «Game Master» y «Apariencia»; tocar Diario / Marketplace / Configuración incrementa su callback; tocar Estadísticas muestra «Las Estadísticas llegará pronto.»; reemplazar el test 'Game Master abre la configuración' por esta versión
- [X] T045 [P] [US4] Crear `test/features/settings/presentation/screens/settings_screen_test.dart`: `SettingsScreen(userName: 'Ana', onBack: …, onSignOut: …, onOpenAppearance: …)` dentro de `MaterialApp` con el tema de la app; tocar «Apariencia» llama `onOpenAppearance` una vez
- [X] T046 [US4] Ejecutar `flutter test test/features/profile test/features/settings` y confirmar que **no compila / falla** (callbacks y etiquetas nuevos no existen)

### Implementation

- [X] T047 [US4] En `lib/features/profile/presentation/screens/profile_screen.dart`: añadir `onOpenJournal` y `onOpenMarketplace` (`VoidCallback`), quitar `onOpenAppearance` y la fila «Apariencia» de CUENTA (con su `BlocSelector` y el `Divider` sobrante; quitar imports que queden sin uso); ACCESOS RÁPIDOS en dos filas de 3 `ProfileQuickLink` (`Expanded`) según la tabla de `contracts/ui.md`, con iconos existentes de Material (`Icons.menu_book_outlined`, `Icons.insights_outlined`, `Icons.visibility_outlined`, `Icons.inventory_2_outlined`, `Icons.storefront_outlined`, `Icons.tune_rounded`)
- [X] T048 [US4] En `lib/features/settings/presentation/widgets/game_master_card.dart`: parámetro `onOpenAppearance` y un `SettingLink` «Apariencia» («Modo claro, oscuro o del sistema.», `Icons.palette_outlined`) con su rótulo de grupo como los demás; en `settings_screen.dart`: `required this.onOpenAppearance` y pasarlo a `GameMasterCard`
- [X] T049 [US4] En `lib/app/config/route_paths.dart`: `appearance = '/settings/appearance'` (moverlo bajo un comentario de subpáginas de Configuración); en `lib/app/config/app_router.dart`: quitar el `GoRoute` `appearance` de la rama de Perfil, añadirlo como `routes:` hijo del `GoRoute` de `/settings` (mismo builder `AppearanceScreen(onBack: () => context.pop())`, fuera de `lightOnly`), pasar a `SettingsScreen` `onOpenAppearance: () => context.push(RoutePaths.appearance)`, y a `ProfileScreen` `onOpenJournal: () => context.push(RoutePaths.journal)` y `onOpenMarketplace: () => context.push(RoutePaths.marketplace)`; `_themedPaths` conserva `RoutePaths.appearance`
- [X] T050 [US4] Ejecutar `flutter test` completo (incluye `test/app_test.dart`) y `flutter analyze`; corregir lo que rompa la ruta movida

**Checkpoint**: Perfil navega como el diseño y Apariencia vive en Configuración.

---

## Phase 7: Polish & Cross-Cutting

- [X] T051 [P] En `CLAUDE.md` §8 («Deuda de arquitectura»): `profile` lee `profile_overview` ampliada en `009_profile_titles.sql` y elige título con `set_active_title`; Apariencia se abre desde Configuración
- [X] T052 [P] En `docs/plan-cambios-esquema.md` §6: entrada de `009_profile_titles.sql` (Tesoro, título activo y ganados en `profile_overview`; `set_active_title`; se aplica después de 008; pruebas en `supabase/tests/009_profile_titles.test.mjs`)
- [X] T053 Revisar `supabase/migrations/009_profile_titles.sql` de punta a punta: cabecera alineada con los bloques, sin editar 001–008 (`git diff --stat supabase/migrations` solo muestra 009)
- [X] T054 Prueba de accesibilidad en `test/features/profile/presentation/screens/profile_screen_test.dart`: ampliar el test existente «con escala de texto 1,3 en 360 dp no desborda» con `profile` (título largo de 60 caracteres) para cubrir la tarjeta con título, la fila Tesoro y las dos filas de accesos
- [X] T055 Repasar `specs/004-profile-update/quickstart.md` contra las secciones reales del test SQL y ajustar la lista si algo cambió

---

## Dependencies & Execution Order

- **Setup (T001–T004)** → historias.
- **US1** no depende de nada (solo texto); se puede entregar sola.
- **US2** antes de **US3**: US3 usa `PrestigeTitle`, `earnedTitles` y el `profile_overview` ampliado.
- **US4** no depende de US2/US3 (solo `profile_screen.dart`, settings y router), pero toca `profile_screen.dart` y su test igual que US2/US3: hacerla después para no pisar cambios.
- **Polish (T051–T055)** al final; T051 y T052 en paralelo.

### Dentro de cada historia

prueba SQL → ver fallar → prueba Flutter → ver fallar → SQL → domain → data → presentation → DI → ejecutar y ver pasar.

## Parallel Examples

```text
# US2, tests Flutter (archivos distintos):
T012 test/features/profile/profile_fixtures.dart
T013 test/features/profile/data/models/character_profile_model_test.dart

# US3, tests Flutter:
T027 test/helpers/mocks.dart
T028 test/features/profile/domain/usecases/profile_usecases_test.dart
T029 test/features/profile/data/repositories/profile_repository_impl_test.dart

# US4:
T045 test/features/settings/presentation/screens/settings_screen_test.dart (mientras se escribe T044)

# Polish:
T051 CLAUDE.md
T052 docs/plan-cambios-esquema.md
```

El SQL (`009_profile_titles.sql` y su test) no se paraleliza: un solo archivo por lado.

## Implementation Strategy

### MVP (US1)

1. T001–T004.
2. T005–T008: el aviso ya dice la regla real. **Parar y validar.**

### Entrega incremental

US1 → US2 (Tesoro y título visibles; aplicar 009 con el bloque 1) → US3 (elegir título; 009 completa) → US4 (accesos y Apariencia). Cada historia deja `npm test` y `flutter test` en verde.

### Al terminar

Aplicar 009 en Supabase (SQL Editor), sembrar al menos un título de prueba para validar a mano (quickstart), reflejar `profile_overview` y `set_active_title` en `Esquema_Base_de_Datos.md` y actualizar RF-034 en `Requerimientos_Funcionales.md`.
