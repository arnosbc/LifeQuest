# Data Model: Actualización del Perfil

Sin tablas, columnas ni enums nuevos. Se leen estructuras creadas en 004.

## Base de datos (existente)

| Tabla / columna | Origen | Uso aquí |
|---|---|---|
| `character_stats.treasury` int, default 0 | 004 | Tesoro del reino (solo lectura) |
| `character_stats.is_weakened` generada `hp_current < 30` | 004 | Aviso de vitalidad (FR-002) |
| `titles (id, code, name, description)` | 004 | Catálogo global; RLS lectura para autenticados; el cliente no escribe |
| `user_titles (user_id, title_id, earned_at)` PK `(user_id, title_id)` | 004 | Títulos ganados; RLS lectura propia; el cliente no escribe |
| `profiles.active_title_id` → `titles.id` `on delete set null` | 004 | Título activo |
| trigger `trg_check_active_title` | 004 | Rechaza `title_not_earned` (42501) si el título no está en `user_titles` del jugador |

### Reglas

- Título activo ∈ títulos ganados del jugador, o `null`.
- Borrar un título del catálogo → `active_title_id = null` y desaparece de `user_titles` (cascade).
- Nadie gana ni compra títulos desde esta feature.

## Dominio (Dart, `lib/features/profile/domain/entities/character_profile.dart`)

### `PrestigeTitle` (nuevo)

| Campo | Tipo | Notas |
|---|---|---|
| `id` | `String` | uuid |
| `name` | `String` | Se muestra bajo el nombre (elipsis si es largo) |
| `description` | `String?` | Detalle en la hoja de elección |

### `CharacterProfile` (ampliado)

| Campo nuevo | Tipo | Default si falta en el JSON |
|---|---|---|
| `treasury` | `int` | 0 |
| `activeTitle` | `PrestigeTitle?` | null |
| `earnedTitles` | `List<PrestigeTitle>` | `[]` |

Derivado: `bool get hasTitles => earnedTitles.isNotEmpty`. Todos los campos nuevos entran en `props`.

`isWeakened` no cambia: viene del servidor y la app no calcula el umbral.

## Estado de la pantalla (`ProfileBloc`)

Sin estados nuevos. `ProfileActiveTitleChanged(titleId)` usa el flujo `_save`:

```
ProfileSuccess(p) → ProfileSuccess(p, saving: true)
  ├─ éxito  → relee → ProfileSuccess(p', message: «Ahora luces «X».» | «Ya no muestras ningún título.»)
  └─ fallo  → ProfileSuccess(p, message: failure.message)   # el título anterior se conserva
```
