# Implementation Plan: Onboarding de 5 pasos

**Branch**: `jhon_cambios` | **Date**: 2026-10-26 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/003-onboarding/spec.md`

## Summary

Tras iniciar sesión, un jugador sin Onboarding visto pasa por 5 pasos (bienvenida, identidad, primera skill, dificultad, listo) antes de Inicio. Lo elegido se guarda **de una vez** al terminar o saltar, con una sola RPC atómica que también fija la marca `profiles.onboarded_at`.

- **Servidor:** migración nueva `supabase/migrations/015_onboarding.sql` (001–014 ya aplicadas, no se editan): columna `profiles.onboarded_at`, trigger que solo deja ponerla en `now()` y nunca borrarla, RPC `onboarding_overview()` (¿pendiente? + multiplicadores vigentes de `difficulty_levels`) y RPC `complete_onboarding(p_identity, p_skill, p_difficulty)`.
- **Flutter:** feature nueva `lib/features/onboarding` en sus tres capas, con un `OnboardingBloc` global que el router usa en `redirect` (composición en `app/`, sin importar `auth`).
- Sin dependencias nuevas, sin colores, fuentes ni componentes nuevos: `core/widgets` y `context.lq`.

## Technical Context

**Language/Version**: Dart 3 / Flutter (estable del proyecto); SQL / PL/pgSQL para PostgreSQL 15+ (Supabase); pruebas SQL en Node.js (ESM)

**Primary Dependencies**: las ya instaladas: `flutter_bloc`, `get_it`, `go_router`, `fpdart`, `equatable`, `supabase_flutter`; tests con `mocktail` y `bloc_test`; SQL con `@electric-sql/pglite` 0.2.17

**Storage**: PostgreSQL (Supabase). Columna nueva `profiles.onboarded_at timestamptz` (null = pendiente). Se escriben `profiles.identity_statement`, `skills` y `game_master_settings.difficulty` con sus reglas actuales (checks de 002, `enforce_skill_limit`, grants de 003)

**Testing**: `flutter test` (usecases, repositorio, model, bloc, screen) y `supabase/tests` (`npm test`, nuevo `015_onboarding.test.mjs`)

**Target Platform**: Android / iOS (Flutter) + Supabase

**Project Type**: app móvil + BaaS

**Performance Goals**: una llamada para saber si toca el Onboarding y otra para guardarlo

**Constraints**: no editar 001–014; 015 idempotente; feature `onboarding` sin importar otras features; FR-012 (sin XP ni Monedas); WCAG 2.1 AA

**Scale/Scope**: 1 migración (1 columna, 1 trigger, 2 RPC), 1 archivo de pruebas SQL; ~14 archivos Dart nuevos, 4 tocados (`app.dart`, `app_router.dart`, `route_paths.dart`, `injection_container.dart`)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] I. Arquitectura: feature `onboarding` domain → data → presentation; `domain` puro; el router y `App` (en `app/`) unen `AuthBloc` y `OnboardingBloc`; todo se registra en `injection_container.dart`. La lógica (límites, qué dificultad guardar al saltar) vive en el bloc y el usecase, no en la screen.
- [x] II. Economía: no se mueve XP, Monedas ni HP. La RPC es `security invoker`: el cliente no gana ningún permiso nuevo.
- [x] III. Datos: sin tablas nuevas; una columna con su trigger guardián; `onboarding_overview` lee `difficulty_levels` (catálogo de solo lectura); sin estados nuevos.
- [x] IV. Pruebas: SQL contra PGlite (guardado completo, saltar, marca solo `now()` e imborrable, límites, aislamiento entre dos jugadores, jugador previo con identidad o skill no pendiente). Flutter: usecases, repositorio, model, bloc y screen.
- [x] V. Ética: saltar siempre a un toque; ningún paso obligatorio; errores con tono de invitación.
- [x] VI. Autonomía: identidad y skill opcionales; la dificultad se elige con la información delante y se cambia luego en Configuración.
- [x] VII. Accesibilidad: zonas táctiles ≥ 48 px, `Semantics` de seleccionado en las opciones de dificultad y en las sugerencias, contador de caracteres, progreso «Paso n de 5» como texto.
- [x] VIII. Idioma: textos en español, identificadores en inglés.

**Re-check post-diseño**: todas en verde.

## Project Structure

### Documentation (this feature)

```text
specs/003-onboarding/
├── plan.md              # Este archivo
├── research.md          # Fase 0
├── data-model.md        # Fase 1
├── quickstart.md        # Fase 1
├── contracts/
│   ├── rpc.md           # onboarding_overview y complete_onboarding
│   └── ui.md            # Pasos, textos y estados
└── tasks.md             # Fase 2 (/speckit-tasks)
```

### Source Code (repository root)

```text
supabase/
├── migrations/015_onboarding.sql              # NUEVO
└── tests/
    ├── 015_onboarding.test.mjs                # NUEVO
    └── package.json                           # + node 015_onboarding.test.mjs

lib/
├── app/
│   ├── app.dart                               # provee OnboardingBloc; lo pide al haber sesión
│   └── config/
│       ├── route_paths.dart                   # + onboarding
│       └── app_router.dart                    # redirect a /onboarding y ruta
├── features/onboarding/
│   ├── domain/
│   │   ├── entities/onboarding_status.dart    # OnboardingStatus + DifficultyOption
│   │   ├── entities/onboarding_choices.dart   # identidad, skill, dificultad
│   │   ├── repositories/onboarding_repository.dart
│   │   └── usecases/{get_onboarding_status,complete_onboarding}.dart
│   ├── data/
│   │   ├── models/onboarding_status_model.dart
│   │   ├── datasources/onboarding_remote_datasource.dart
│   │   └── repositories/onboarding_repository_impl.dart
│   └── presentation/
│       ├── blocs/onboarding_{bloc,event,state}.dart
│       ├── screens/onboarding_screen.dart
│       └── widgets/                           # un widget por paso
└── injection_container.dart                   # + onboarding

test/features/onboarding/                      # usecases, model, repositorio, bloc, screen
test/helpers/mocks.dart                        # + mocks de onboarding
```

**Structure Decision**: móvil + BaaS. Feature nueva `onboarding`; el resto solo se toca en `app/`.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Columna nueva en `profiles` aunque el pedido decía «solo tablas existentes» | Ninguna tabla guarda si el Onboarding se vio (spec, Assumptions) | Guardarlo en el dispositivo rompe SC-004 (reinstalar o cambiar de teléfono) |

## Riesgos y notas

- Tras aplicar 015 hay que reflejar `profiles.onboarded_at` y las 2 RPC en `Esquema_Base_de_Datos.md` (Project de claude.ai) y en `supabase/schema.sql`.
- La pantalla de Configuración todavía guarda la dificultad solo en pantalla (deuda de `settings`, CLAUDE.md §8); FR-009 se cumple en el servidor (grant de 003), no en esa UI.
- Textos de bienvenida provisionales hasta `PRODUCT.md`.
