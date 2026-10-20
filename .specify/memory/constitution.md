<!--
Sync Impact Report
- Version: plantilla sin versión → 1.0.0 (primera ratificación)
- Principios definidos (antes eran marcadores de la plantilla):
  I. Arquitectura Flutter limpia por feature (NO NEGOCIABLE)
  II. Economía autoritativa del servidor (anti-trampa) (NO NEGOCIABLE)
  III. Datos aislados con RLS y esquema como fuente de verdad
  IV. SQL y comportamiento probados
  V. Diseño ético: sin dark patterns y el HP nunca mata
  VI. Autonomía del usuario
  VII. Accesibilidad WCAG 2.1 AA
  VIII. Español en textos, inglés en identificadores
- Secciones añadidas: Restricciones de stack y alcance; Flujo de desarrollo y puertas de calidad;
  Governance
- Secciones eliminadas: ninguna
- Plantillas:
  ✅ .specify/templates/plan-template.md (Constitution Check con las 8 puertas)
  ✅ .specify/templates/tasks-template.md (tests obligatorios según el principio IV)
  ✅ .specify/templates/spec-template.md (sin cambios necesarios)
  ✅ .specify/templates/checklist-template.md (sin cambios necesarios)
  ⚠ .specify/templates/commands/*.md no existe en este proyecto (nada que revisar)
- TODO diferidos: ninguno
-->

# LifeQuest Constitution

## Core Principles

### I. Arquitectura Flutter limpia por feature (NO NEGOCIABLE)

Todo código Flutter MUST seguir Feature-Driven Clean Architecture con Bloc, get_it, go_router,
fpdart (`Either`) y equatable, con la estructura `lib/app`, `lib/core` y
`lib/features/<feature>/{data,domain,presentation}` descrita en CLAUDE.md §8.

- `domain` es Dart puro: solo importa `equatable` y `fpdart`.
- `presentation` solo conoce `domain` (usecases y entities), nunca models ni datasources.
- `data` implementa los contratos de `domain`; los models convierten con `toEntity()`.
- Los datasources lanzan `ServerException`/`NetworkException`; los repositorios devuelven
  `Left(Failure)` con el mensaje en español.
- Un usecase tiene una sola responsabilidad y expone `call()`.
- Una feature no importa otra: lo compartido va en `core/` y la composición en `app/`.
- Toda dependencia se registra en `injection_container.dart` y se inyecta por constructor.
- Ninguna lógica de negocio vive en widgets ni screens.
- Una feature nueva se construye de adentro hacia afuera: domain → data → presentation →
  registro en get_it y ruta en `app_router.dart` → tests.

**Por qué:** capas aisladas permiten probar la lógica sin Flutter ni Supabase y migrar las
pantallas que hoy guardan datos de ejemplo sin reescribirlas.

### II. Economía autoritativa del servidor (anti-trampa) (NO NEGOCIABLE)

El cliente MUST NOT escribir XP, Monedas, HP, rachas, niveles de skill, compras ni filas de
`quest_log_entries`. Toda recompensa o penalización pasa por una función Postgres
`SECURITY DEFINER` llamada por RPC (o una Edge Function) que, en una sola transacción:

1. valida la propiedad y el estado de la entidad,
2. aplica el multiplicador de dificultad y la reducción por estado debilitado,
3. actualiza `character_stats` y la `skill`,
4. escribe la fila en `quest_log_entries`.

Todo pago pasa por `_award` y sus números viven en `game_rules`. No se inventan valores de la
economía: se toman de `docs/ideas-proyecto-productividad-gamificada.md` («Economía estable») o
se marcan como configuración provisional.

**Por qué:** como en un juego en línea, el jugador ve su oro, pero solo el servidor puede
cambiarlo.

### III. Datos aislados con RLS y esquema como fuente de verdad

- `schema.sql` es la verdad del modelo de datos; cada cambio lleva su comentario de RF
  (ej. `-- RF-032`) y se refleja en `Esquema_Base_de_Datos.md`.
- Toda tabla con `user_id` MUST tener RLS con la política `auth.uid() = user_id`.
- Los catálogos globales son de solo lectura para usuarios autenticados y se administran con la
  `service_role`.
- Las vistas se crean con `with (security_invoker = true)`.
- PK `uuid default gen_random_uuid()`, timestamps `timestamptz default now()`, estados cerrados
  con enums de Postgres, nunca `text` libre.
- Lo derivable no se guarda a mano: columnas generadas o vistas.
- Las referencias polimórficas sin FK física se validan en la función que inserta.
- Un rótulo visual (Éxito, Fracaso, «¡Hazlo ahora!») MUST NOT convertirse en un estado nuevo
  en BD; es un mapeo en la UI sobre `objective_status`.

**Por qué:** un solo usuario por cuenta y datos personales sensibles; el RLS es la última línea
de defensa aunque el cliente falle.

### IV. SQL y comportamiento probados

- Todo cambio de SQL MUST probarse contra un Postgres real (`supabase/tests`, o un stub de
  `auth.users`, `auth.uid()` y `auth.role()` si no es Supabase).
- Las pruebas cubren comportamiento, no solo sintaxis: límites, unicidad, triggers, rechazo de
  escrituras del cliente en tablas económicas y aislamiento RLS entre dos usuarios.
- Toda feature Flutter MUST traer tests de usecases, repositorio y bloc (mocktail + bloc_test),
  con mocks en `test/helpers/mocks.dart`.

**Por qué:** la economía y el RLS fallan en silencio; solo una prueba que ejecuta la regla
demuestra que se cumple.

### V. Diseño ético: sin dark patterns y el HP nunca mata

- Ninguna mecánica existe solo para que el usuario abra más la app; cada una MUST reforzar un
  comportamiento productivo real. Los dark patterns están prohibidos.
- El HP nunca mata al personaje ni borra progreso. El estado debilitado reduce ganancias pero
  nunca bloquea acciones. Las penalizaciones son graduales.
- Las recompensas aleatorias son cosméticas, nunca apuestas.
- Gastar Monedas nunca se siente como perder avance; el XP nunca se gasta.
- Notificaciones y textos usan tono de invitación, nunca de amenaza ni culpa; un mismo evento
  nunca se notifica dos veces (`event_key` único).

**Por qué:** la app ataca la fatiga y el pensamiento todo-o-nada; castigar o manipular
reproduce el problema que quiere resolver.

### VI. Autonomía del usuario

El usuario define sus skills (máx. 6 por defecto), qué ítems del catálogo cerrado ve en su
Tienda, su dificultad y sus notificaciones (límite diario, ventana de silencio). Ninguna
funcionalidad MUST imponer estas elecciones ni ocultar cómo cambiarlas.

**Por qué:** Autodeterminación (Deci y Ryan): la motivación se sostiene cuando el usuario elige.

### VII. Accesibilidad WCAG 2.1 AA

Toda UI MUST cumplir WCAG 2.1 AA: contraste 4,5:1 (3:1 texto grande), zonas táctiles amplias,
`Semantics` en botones de icono y el color nunca como único portador de información (símbolo +
texto). La Mazmorra es siempre oscura y respeta la reducción de movimiento del sistema. Mientras
no existan `DESIGN.md` y `PRODUCT.md`, no se inventan colores, fuentes ni componentes: se usa
`LifeQuestColors` / `context.lq`.

**Por qué:** una app de productividad que excluye a parte de sus usuarios incumple su propósito.

### VIII. Español en textos, inglés en identificadores

Documentación, comentarios de dominio, textos de UI y mensajes de `Failure` van en español.
Identificadores de código y de base de datos (tablas, columnas, enums, funciones) van en inglés;
en SQL, en `snake_case`. Archivos Dart en `snake_case` e imports como `package:proyecto_movil/...`.

**Por qué:** el usuario y el equipo hablan español; el código sigue la convención del
ecosistema.

## Restricciones de stack y alcance

- Stack: PostgreSQL 15+ y Supabase (Auth, PostgREST, RLS, Storage, Edge Functions, `pg_cron`);
  Flutter/Dart en el móvil. Sin Dio ni `core/network`: el SDK de Supabase es el cliente HTTP.
- Fuera de alcance, sin tablas ni pantallas: Financial Vault, personalización visual completa
  (avatar, ropa, cosméticos), modo cooperativo/gremios/rankings y autorecompensas de texto libre.
- No se crean tablas para Áreas, P.A.R.A., NpcMission, Historia, Diagnosis Tools ni el carrito.
- Las decisiones abiertas de CLAUDE.md §11 no se cierran sin consultar al equipo.

## Flujo de desarrollo y puertas de calidad

- Jerarquía de fuentes: `schema.sql` > `Requerimientos_Funcionales.md` > `Casos_de_Uso.md` >
  `Esquema_Base_de_Datos.md` > `docs/ideas-proyecto-productividad-gamificada.md`.
- Toda spec y todo cambio citan el RF que los justifica. Si una decisión altera un RF o un UC, se
  actualizan ambos documentos manteniendo la trazabilidad RF ↔ UC.
- Una decisión del cierre del diseño (CLAUDE.md §13) que choque con un RF o con el esquema
  MUST NOT implementarse hasta actualizar el RF, el UC y `schema.sql`.
- Las migraciones de `supabase/migrations/` se aplican en orden.
- Cada plan pasa el Constitution Check (principios I–VIII) antes de investigar y después del
  diseño; toda violación se justifica en la tabla de Complexity Tracking.

## Governance

Esta constitución prevalece sobre otras prácticas del proyecto; CLAUDE.md es la guía operativa
detallada y MUST mantenerse coherente con ella.

- **Enmiendas:** se proponen por escrito con su motivo, se aprueban por el equipo y se registran
  en el Sync Impact Report del encabezado, actualizando las plantillas de `.specify/templates/`.
- **Versionado semántico:** MAJOR al eliminar o redefinir un principio; MINOR al añadir un
  principio o sección o ampliar su guía; PATCH en aclaraciones y redacción.
- **Cumplimiento:** toda revisión de código y todo plan verifican los principios I–VIII; una
  excepción se documenta con su justificación y la alternativa más simple descartada.

**Version**: 1.0.0 | **Ratified**: 2026-10-18 | **Last Amended**: 2026-10-18
