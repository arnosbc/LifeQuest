# Contrato: RPC del Onboarding (015)

## `onboarding_overview() → jsonb`

`sql`, `stable`, `security invoker`, `set search_path = ''`.

```jsonc
{
  "pending": true,                 // false si ya lo terminó/saltó, o tiene identidad o alguna skill
  "difficulties": [                // orden easy, normal, hard (difficulty_levels)
    { "level": "easy",   "xp_multiplier": 1.2,  "hp_penalty_multiplier": 0.75, "coin_multiplier": 1 },
    { "level": "normal", "xp_multiplier": 1,    "hp_penalty_multiplier": 1,    "coin_multiplier": 1 },
    { "level": "hard",   "xp_multiplier": 0.85, "hp_penalty_multiplier": 1.25, "coin_multiplier": 1 }
  ]
}
```

`null` si el jugador no tiene fila en `profiles`.

## `complete_onboarding(p_identity text, p_skill text, p_difficulty public.difficulty_level) → void`

`plpgsql`, `security invoker`, `set search_path = ''`. Una transacción:

1. Sin sesión → ❌ `not_authenticated` (28000).
2. `onboarded_at` ya puesto → ❌ `onboarding_done` (42501), sin cambios.
3. `trim(p_identity)` no vacía → `profiles.identity_statement` (> 280 → ❌ check `profiles_identity_length`, 23514).
4. `trim(p_skill)` no vacía → inserta la skill (> 40 → ❌ `skills_name_length`; ya existe sin distinguir mayúsculas → ❌ `skill_exists` (23505); límite → ❌ `skill_limit_reached` de 002).
5. `game_master_settings.difficulty = coalesce(p_difficulty, 'normal')`.
6. `profiles.onboarded_at = now()`.

Cualquier error deshace todo. No da XP ni Monedas (FR-012).

Permisos de ambas: `execute` para `authenticated`; revocada a `public, anon`.

Llamada desde Flutter:

```dart
client.rpc('complete_onboarding', params: {
  'p_identity': identity, 'p_skill': skill, 'p_difficulty': 'hard',
});
```

## Trigger `guard_onboarded_at` (before update of `onboarded_at` on `profiles`)

| Antes | Después pedido | Resultado |
|---|---|---|
| null | cualquier valor | se guarda `now()` |
| null | null | sin cambios |
| valor | otro valor o null | ❌ `onboarding_locked` (42501) |
