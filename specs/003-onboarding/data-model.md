# Data Model: Onboarding

## Servidor

### `profiles.onboarded_at` (nueva)

| Campo | Tipo | Regla |
|---|---|---|
| `onboarded_at` | `timestamptz` null | null = no visto. Solo pasa de null a `now()` (lo fuerza el trigger `guard_onboarded_at`); una vez puesta no cambia ni se borra (`onboarding_locked`, 42501) |

Escritas por `complete_onboarding` con sus reglas actuales:

| Tabla.columna | Regla vigente |
|---|---|
| `profiles.identity_statement` | ≤ 280 caracteres (002); vacía o solo espacios → no se toca |
| `skills.name` | 1–40 caracteres tras `trim` (002); máx. por `enforce_skill_limit`; vacía → no se crea |
| `game_master_settings.difficulty` | enum `difficulty_level` (`easy`, `normal`, `hard`) |

### Estado pendiente (derivado, no se guarda)

`pending = onboarded_at is null and identity_statement is null and not exists (skills del jugador)`

## Flutter (`features/onboarding/domain`)

```dart
enum GameDifficulty { easy, normal, hard }

class DifficultyOption {        // de difficulty_levels
  GameDifficulty level; double xpMultiplier; double hpPenaltyMultiplier; double coinMultiplier;
}

class OnboardingStatus {        // onboarding_overview()
  bool pending; List<DifficultyOption> difficulties;
}

class OnboardingChoices {       // lo que se envía al terminar o saltar
  String identity; String skill; GameDifficulty difficulty;
}
```

### Estados del bloc

```
OnboardingInitial → OnboardingLoading → OnboardingPending(status, saving, error?)
                                      ↘ OnboardingNotNeeded   (no pendiente o la consulta falló)
OnboardingPending --Submitted--> saving=true --ok--> OnboardingNotNeeded
                                             --error--> OnboardingPending(error)
```

Al saltar, la dificultad que se envía es la marcada si el jugador llegó al paso 4; si no, `normal` (FR-005).
