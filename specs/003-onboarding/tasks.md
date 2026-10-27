# Tasks: Onboarding de 5 pasos

**Input**: `specs/003-onboarding/` (plan.md, spec.md, research.md, data-model.md, contracts/)

**Tests**: obligatorios por la constitución (principio IV): SQL contra PGlite y usecases, repositorio, bloc y screen en Flutter.

## Phase 1: Setup

- [x] T001 Añadir `node 015_onboarding.test.mjs` al script `test` de supabase/tests/package.json
- [x] T002 [P] Añadir `RoutePaths.onboarding = '/onboarding'` en lib/app/config/route_paths.dart

## Phase 2: Foundational (servidor y dominio, bloquea todas las historias)

- [x] T003 Crear supabase/migrations/015_onboarding.sql: columna `profiles.onboarded_at`, trigger `guard_onboarded_at`, RPC `onboarding_overview()` y `complete_onboarding(text, text, difficulty_level)` según contracts/rpc.md; idempotente; permisos solo `authenticated`
- [x] T004 Crear supabase/tests/015_onboarding.test.mjs: guardado completo, saltar (vacíos + normal), marca forzada a `now()` e imborrable también por update directo, `onboarding_done` al repetir, longitud > 280/40 deshace todo, jugador con identidad o skill no pendiente, multiplicadores, aislamiento entre U1 y U2
- [x] T005 [P] Crear entidades lib/features/onboarding/domain/entities/onboarding_status.dart (`GameDifficulty`, `DifficultyOption`, `OnboardingStatus`) y onboarding_choices.dart
- [x] T006 [P] Crear lib/features/onboarding/domain/repositories/onboarding_repository.dart (`getStatus`, `complete`)
- [x] T007 Crear usecases lib/features/onboarding/domain/usecases/get_onboarding_status.dart y complete_onboarding.dart
- [x] T008 Crear lib/features/onboarding/data/models/onboarding_status_model.dart con `fromJson` y `toEntity()`
- [x] T009 Crear lib/features/onboarding/data/datasources/onboarding_remote_datasource.dart (RPC, `_guard` como en profile)
- [x] T010 Crear lib/features/onboarding/data/repositories/onboarding_repository_impl.dart con los mensajes de contracts/ui.md (`onboarding_done` → éxito)
- [x] T011 Registrar datasource, repositorio, usecases y `OnboardingBloc` (singleton) en lib/injection_container.dart

## Phase 3: User Story 1 — Completar el Onboarding (P1) 🎯 MVP

**Independent Test**: cuenta nueva → 5 pasos con datos → Perfil muestra identidad y skill; dificultad guardada; vuelve a Inicio y no reaparece.

- [x] T012 [US1] Crear lib/features/onboarding/presentation/blocs/onboarding_{event,state,bloc}.dart: `OnboardingRequested`, `OnboardingSubmitted(choices)`; estados Initial, Loading, Pending(status, saving, error), NotNeeded
- [x] T013 [US1] Crear lib/features/onboarding/presentation/screens/onboarding_screen.dart y widgets de paso en presentation/widgets/ (progreso «Paso n de 5», Atrás conservando lo escrito, chips de sugerencias, límites 280/40)
- [x] T014 [US1] Proveer `OnboardingBloc` en lib/app/app.dart y pedirlo al pasar `AuthBloc` a `AuthSuccess`
- [x] T015 [US1] En lib/app/config/app_router.dart: escuchar también `OnboardingBloc`, redirigir a `/onboarding` mientras no sea `NotNeeded` y sacar de ahí cuando lo sea; ruta `/onboarding` en `_themedPaths`-equivalente (sigue el tema)
- [x] T016 [P] [US1] Tests de usecases, model y repositorio en test/features/onboarding/ (+ mocks en test/helpers/mocks.dart)
- [x] T017 [P] [US1] Test del bloc en test/features/onboarding/presentation/blocs/onboarding_bloc_test.dart
- [x] T018 [US1] Test de la screen (recorrer 5 pasos, Atrás conserva texto, chip rellena campo) en test/features/onboarding/presentation/screens/onboarding_screen_test.dart

## Phase 4: User Story 2 — Saltar sin perder nada (P1)

**Independent Test**: escribir identidad y saltar → Inicio, identidad guardada, dificultad Normal, no reaparece.

- [x] T019 [US2] Botón «Saltar» en todos los pasos de onboarding_screen.dart: envía lo escrito y la dificultad marcada solo si llegó al paso 4 (si no, `normal`)
- [x] T020 [US2] Error al guardar: SnackBar con «Reintentar», «Saltar» sigue disponible; el error de la consulta inicial deja entrar a Inicio (bloc)
- [x] T021 [US2] Ampliar los tests de bloc y screen con saltar antes y después del paso 4 y con error

## Phase 5: User Story 3 — Elegir con información (P2)

**Independent Test**: el paso 4 muestra XP y vida perdida de cada nivel desde el servidor, Normal preseleccionada y el aviso de Configuración.

- [x] T022 [US3] Paso 4 en presentation/widgets/: opciones con multiplicadores formateados con coma decimal, nota de Monedas, aviso de Configuración, `Semantics(selected)` y check visible
- [x] T023 [US3] Test de screen del paso 4 (valores del servidor, Normal preseleccionada)

## Phase 6: Polish

- [x] T024 [P] ~~Reflejar en supabase/schema.sql~~ Omitida: schema.sql es el volcado v2 y no recoge ninguna migración 004–014; queda para `Esquema_Base_de_Datos.md` (Project de claude.ai)
- [x] T025 [P] Actualizar CLAUDE.md §8 (deuda de arquitectura) con la feature `onboarding` y la migración 015
- [x] T026 `flutter analyze`, `flutter test` y `npm test` en supabase/tests en verde

## Dependencies

Setup → Foundational (T003 → T004; T005–T006 → T007 → T008–T010 → T011) → US1 → US2 (mismo screen y bloc) → US3 → Polish.

## Parallel Example

T005 y T006 juntos; T016 y T017 juntos; T024 y T025 juntos.

## Implementation Strategy

MVP = Phase 1–3. US2 es P1 también y comparte archivos, así que se entrega en el mismo corte.
