# Implementation Plan: Actualización del Perfil (vitalidad, Tesoro, títulos y accesos)

**Branch**: `jhon_cambios` | **Date**: 2026-10-24 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/004-profile-update/spec.md`

## Summary

El Perfil pasa a mostrar la regla vigente de debilitado (vida < 30 → −25 % de XP, Monedas iguales), el Tesoro del reino, el título activo y la elección de título entre los ganados, y sus accesos se alinean con la navegación del diseño (Diario, Estadísticas, Vision Board, Inventario y logros, Marketplace, Configuración). Apariencia se muda a Configuración.

- **Servidor:** migración nueva `supabase/migrations/009_profile_titles.sql` (001–008 ya aplicadas, no se editan) que redefine `profile_overview()` añadiendo `treasury`, `active_title` y `titles`, y crea la RPC `set_active_title(p_title_id uuid)`; el trigger `check_active_title` de 004 sigue siendo quien rechaza un título no ganado (`title_not_earned`).
- **Flutter:** se amplía `lib/features/profile` por sus tres capas (entity → model `toEntity` → datasource → repository → usecase `SetActiveTitle` → `ProfileBloc`), y se tocan los widgets existentes (`CharacterCard`, `HeroStatusCard`, `ProfileQuickLink`, `profile_sheets.dart`). La ruta de Apariencia pasa a colgar de `/settings`.
- Sin dependencias nuevas y sin rediseño: `core/widgets` y `context.lq`.

## Technical Context

**Language/Version**: Dart 3 / Flutter (estable del proyecto); SQL / PL/pgSQL para PostgreSQL 15+ (Supabase); pruebas SQL en Node.js (ESM)

**Primary Dependencies**: las ya instaladas: `flutter_bloc`, `bloc_concurrency`, `get_it`, `go_router`, `fpdart`, `equatable`, `supabase_flutter`; tests con `mocktail` y `bloc_test`; SQL con `@electric-sql/pglite` 0.2.17

**Storage**: PostgreSQL (Supabase). Tablas existentes de 004: `titles` (catálogo global, solo lectura), `user_titles` (RLS lectura propia), `profiles.active_title_id`, `character_stats.treasury`. Sin tablas ni columnas nuevas

**Testing**: `flutter test` (model, usecases, repositorio, bloc, screen) y `supabase/tests` (`npm test`, nuevo `009_profile_titles.test.mjs`)

**Target Platform**: Android / iOS (Flutter) + Supabase

**Project Type**: app móvil + BaaS

**Performance Goals**: una sola llamada (`profile_overview`) carga todo el Perfil, igual que hoy (SC-005)

**Constraints**: no editar 001–008; 009 idempotente; feature `profile` sin importar otras features (la navegación entra por callbacks desde `app/`); sin colores, fuentes ni componentes nuevos; WCAG 2.1 AA

**Scale/Scope**: 1 migración (2 funciones), 1 archivo de pruebas SQL; ~10 archivos Dart tocados y 1 usecase nuevo; tests ampliados en 6 archivos

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] I. Arquitectura: el cambio recorre domain → data → presentation de `profile`; `domain` sigue puro; los accesos a Diario, Marketplace y Configuración llegan como `VoidCallback` desde `app_router.dart` (sin imports entre features); `SetActiveTitle` se registra en `injection_container.dart`.
- [x] II. Economía: no se mueve XP ni Monedas; el Tesoro solo se **lee**. Los títulos no se compran: no hay ruta de compra ni RPC que los otorgue.
- [x] III. Datos: sin tablas nuevas; `profile_overview` sigue `security invoker` (RLS de `user_titles`); `set_active_title` también es `security invoker` y el trigger de 004 valida; ningún estado nuevo.
- [x] IV. Pruebas: SQL contra PGlite (datos del Perfil, título no ganado, quitar título, aislamiento entre dos jugadores, título retirado del catálogo); Flutter: model, usecase, repositorio, bloc y screen.
- [x] V. Ética: el aviso de vitalidad explica cómo recuperarse; sin compra de títulos; el estado vacío explica cómo se ganan.
- [x] VI. Autonomía: el jugador elige qué título lucir, o ninguno.
- [x] VII. Accesibilidad: aviso de vitalidad con icono + texto (no solo color); filas de título con `Semantics` de seleccionado; zonas táctiles ≥ 48 px; título largo con elipsis.
- [x] VIII. Idioma: textos en español, identificadores en inglés.

**Re-check post-diseño**: todas en verde. Ver Complexity Tracking por la nota de RF-034.

## Project Structure

### Documentation (this feature)

```text
specs/004-profile-update/
├── plan.md              # Este archivo
├── research.md          # Fase 0
├── data-model.md        # Fase 1
├── quickstart.md        # Fase 1
├── contracts/
│   ├── rpc.md           # profile_overview ampliada y set_active_title
│   └── ui.md            # Accesos, textos y estados de la pantalla
└── tasks.md             # Fase 2 (/speckit-tasks)
```

### Source Code (repository root)

```text
supabase/
├── migrations/009_profile_titles.sql          # NUEVO
└── tests/
    ├── 009_profile_titles.test.mjs            # NUEVO
    └── package.json                           # + node 009_profile_titles.test.mjs

lib/
├── app/config/
│   ├── route_paths.dart                       # appearance → /settings/appearance
│   └── app_router.dart                        # Apariencia bajo /settings; callbacks de Perfil
├── features/profile/
│   ├── domain/
│   │   ├── entities/character_profile.dart    # + PrestigeTitle, treasury, activeTitle, earnedTitles
│   │   ├── repositories/profile_repository.dart  # + setActiveTitle
│   │   └── usecases/set_active_title.dart     # NUEVO
│   ├── data/
│   │   ├── models/character_profile_model.dart   # lee treasury, active_title, titles
│   │   ├── datasources/profile_remote_datasource.dart  # + rpc set_active_title
│   │   └── repositories/profile_repository_impl.dart   # + setActiveTitle y mensaje title_not_earned
│   └── presentation/
│       ├── blocs/profile_bloc.dart, profile_event.dart  # + ProfileActiveTitleChanged
│       ├── screens/profile_screen.dart        # 6 accesos, sin fila Apariencia, entrada de título
│       └── widgets/
│           ├── character_card.dart            # título activo bajo el nombre + «Elegir título»
│           ├── hero_status_card.dart          # aviso −25 % XP y fila Tesoro del reino
│           └── profile_sheets.dart            # hoja de elección de título (y estado vacío)
├── features/settings/presentation/
│   ├── screens/settings_screen.dart           # + onOpenAppearance
│   └── widgets/game_master_card.dart          # + SettingLink «Apariencia»
└── injection_container.dart                   # + SetActiveTitle

test/features/profile/
├── profile_fixtures.dart                      # + títulos y Tesoro
├── data/models/character_profile_model_test.dart
├── data/repositories/profile_repository_impl_test.dart
├── domain/usecases/profile_usecases_test.dart
├── presentation/blocs/profile_bloc_test.dart
└── presentation/screens/profile_screen_test.dart
test/helpers/mocks.dart                        # + MockSetActiveTitle
```

**Structure Decision**: móvil + BaaS. Se amplía la feature `profile` existente; ninguna feature nueva.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| El aviso usa la regla de §13 (vida < 30, −25 % XP) aunque RF-034 todavía dice ≤ 20 % / −10 % | El servidor ya aplica la regla nueva desde 004/005 (`is_weakened` generado como `hp_current < 30`, `weakened_xp_factor = 0,75`); la app hoy muestra una regla que el servidor no cumple | Mantener el texto de RF-034 mentiría al jugador sobre una penalización real. RF-034 está en la lista de deuda (CLAUDE.md §12) y se actualiza en `Requerimientos_Funcionales.md` (Project de claude.ai) junto con esta entrega |

## Riesgos y notas

- **Inicio** tiene el mismo aviso antiguo («10 % menos»): fuera de esta spec (Assumptions).
- El catálogo `titles` está vacío en producción: la elección mostrará el estado vacío hasta que se siembren títulos (decisión abierta en CLAUDE.md §11).
- `profiles` sigue con `grant update` amplio para el cliente: un `update profiles set active_title_id` directo también lo frena el trigger de 004, así que no hace falta revocar nada; la app usa solo la RPC.
- Tras aplicar 009 hay que reflejar en `Esquema_Base_de_Datos.md` (Project de claude.ai) la nueva forma de `profile_overview` y `set_active_title`.
