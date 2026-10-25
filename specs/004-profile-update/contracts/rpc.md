# Contrato: RPC del Perfil (009)

## `profile_overview() → jsonb` (ampliada)

`security invoker`, `stable`. Firma y claves de 002 sin cambios; se añaden tres claves:

```jsonc
{
  // … claves de 002: display_name, character_class, identity_statement, level,
  // current_xp, xp_to_next_level, coins, hp_current, hp_max, is_weakened,
  // quests_completed, quests_failed, skill_limit, skills
  "treasury": 12500,                       // int, 0 si no hay fila de character_stats
  "active_title": {                        // null si no hay título activo
    "id": "uuid", "name": "Guardián del Huerto", "description": "…" // description puede ser null
  },
  "titles": [                              // [] si no ganó ninguno; orden earned_at asc
    { "id": "uuid", "name": "…", "description": "…", "earned_at": "2026-10-20T…Z" }
  ]
}
```

- Solo los títulos del propio jugador (RLS de `user_titles`).
- `null` si el jugador no tiene fila en `profiles` (igual que hoy).
- Permisos: `execute` para `authenticated`; nada para `public`/`anon`.

## `set_active_title(p_title_id uuid) → void` (nueva)

`plpgsql`, `security invoker`, `set search_path = ''`. Actualiza `profiles.active_title_id` de `auth.uid()`.

| Entrada | Resultado |
|---|---|
| id de un título ganado | pasa a ser el activo |
| `null` | sin título activo |
| id no ganado o inexistente | ❌ `title_not_earned` (42501), sin cambios |
| sin sesión | ❌ `not_authenticated` (28000) |

Permisos: `execute` para `authenticated`; revocada a `public, anon`.

Llamada desde Flutter: `client.rpc('set_active_title', params: {'p_title_id': titleId})`.

## Errores → mensaje en la app

| Código | Mensaje (`ProfileRepositoryImpl`) |
|---|---|
| `title_not_earned` | «Ese título todavía no es tuyo. Los títulos se ganan con logros, nivel y Tesoro.» |
| red | «No hay conexión con el servidor. Revisa tu internet y reintenta.» (existente) |
| otro | «Algo salió mal. Inténtalo de nuevo en un momento.» (existente) |
