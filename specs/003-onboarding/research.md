# Research: Onboarding de 5 pasos

## R1 · Guardar al final, de una vez

- **Decision:** una sola RPC `complete_onboarding` al terminar o saltar guarda identidad, skill, dificultad y la marca en una transacción. Los pasos intermedios no escriben nada.
- **Rationale:** si se guardara paso a paso, cerrar la app tras el paso 3 dejaría una skill creada y, por FR-008 («quien tiene identidad o skill no ve el Onboarding»), el jugador no volvería a verlo y se perdería la dificultad. Guardar de una vez evita ese choque y cumple «nada queda a medias».
- **Alternatives considered:** guardar por paso con la marca aparte (choca con FR-008); guardar en el dispositivo y subir al final (más código, mismo resultado).

## R2 · Cuándo está pendiente

- **Decision:** `pending = onboarded_at is null and identity_statement is null and no tiene skills`, calculado en `onboarding_overview()`.
- **Rationale:** cubre FR-008 para los jugadores anteriores a la función sin un backfill; un jugador antiguo con perfil vacío es, a efectos prácticos, nuevo.
- **Alternatives considered:** backfill de `onboarded_at` en la migración (solo cubre a los existentes en ese momento y es otro paso que probar).

## R3 · Marca fija

- **Decision:** trigger `before update of onboarded_at` en `profiles`: si ya tenía valor, rechaza cualquier cambio (`onboarding_locked`); si pasa de null a algo, lo fuerza a `now()`. El `insert` lo deja en null.
- **Rationale:** `profiles` tiene `grant update` amplio (003); no se puede revocar una sola columna con la tabla concedida. El trigger cierra también la escritura directa desde el cliente (FR-007a).
- **Alternatives considered:** RPC `security definer` y revocar el update de `profiles` (rompe Perfil, que edita la identidad directo).

## R4 · RPC `security invoker`

- **Decision:** `complete_onboarding` y `onboarding_overview` son `security invoker`.
- **Rationale:** escriben solo lo que el jugador ya puede escribir; así siguen aplicando el RLS, los grants de columna de `game_master_settings` (003), los checks de longitud (002) y `enforce_skill_limit`.

## R5 · Multiplicadores leídos del servidor

- **Decision:** `onboarding_overview()` devuelve `difficulties` desde `difficulty_levels` (`level`, `xp_multiplier`, `hp_penalty_multiplier`, `coin_multiplier`), en orden easy, normal, hard.
- **Rationale:** Assumptions de la spec: no escribir los valores a mano en la pantalla.

## R6 · Gate en el router

- **Decision:** `OnboardingBloc` global en `App` (como `AppearanceBloc`). `App` le pide el estado cuando `AuthBloc` emite `AuthSuccess`. El `redirect` lleva a `/onboarding` a un jugador con sesión mientras el estado no sea «no pendiente» (cargando muestra un indicador) y lo saca de ahí cuando lo es. Si la consulta falla, el jugador entra a Inicio (nunca queda atrapado).
- **Rationale:** el `redirect` de go_router es síncrono; un bloc con `refreshListenable` es el patrón ya usado con `AuthBloc`.
- **Alternatives considered:** comprobarlo dentro de Inicio (muestra Inicio antes del Onboarding, contra el escenario 1 de US1).

## R7 · Duplicado y límite de skills

- **Decision:** la RPC compara nombres sin distinguir mayúsculas (`skill_exists`) por defensa, aunque un jugador pendiente no tiene skills; el límite lo aplica `enforce_skill_limit`.
- **Rationale:** el Onboarding solo llega a jugadores sin skills, así que el caso solo aparece si dos dispositivos lo terminan a la vez; la segunda llamada falla con `onboarding_done` antes (ver R3).
