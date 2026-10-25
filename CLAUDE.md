# CLAUDE.md — LifeQuest

Instrucciones de contexto para trabajar en **LifeQuest**, una app móvil de productividad gamificada. Léelo completo antes de diseñar, codificar o modificar documentación del proyecto.

> **Idioma:** toda la documentación, los comentarios de dominio y los textos de la interfaz van en **español**. Los identificadores de código y de base de datos (tablas, columnas, enums, funciones) van en **inglés** y en `snake_case` para SQL.

---

## 1. Qué es LifeQuest

App móvil que convierte tareas, hábitos, proyectos y metas reales en misiones de un RPG: **el progreso real del usuario hace progresar a su personaje.**

- **Problema que resuelve:** la brecha entre intención y acción. Las tareas grandes no tienen punto de entrada, falta feedback inmediato, organizar pendientes produce fatiga de decisión y romper una racha dispara el pensamiento todo-o-nada.
- **Usuario:** una sola persona. No hay modo cooperativo, gremios ni ranking social en esta fase.
- **Nombres provisionales:** LifeQuest (nombre del proyecto), Questly, LevelUp.
- **Monetización prevista:** freemium. El premium futuro incluiría más de 6 skills, estadísticas avanzadas y RPGenie avanzado.

### Ciclo principal

```
Vision Board (propósito) → Brain Dump / Quick Add (captura) → Diagnóstico (G.T.D. o S.M.A.R.T.)
→ Meta → Proyecto → Tarea / Misión → Mazmorra (sesión de concentración)
→ Tarea completada → XP + Monedas → Nivel / Skill → Marketplace (gasto) → siguiente misión
```

**Regla mental del sistema:** casi toda acción del usuario termina en **una fila de `quest_log_entries`** y en **un cambio de `character_stats`** (XP, Monedas, HP) y del nivel de una **skill**. Ese es el motor del juego; el resto de tablas lo alimentan o son dónde se gasta lo ganado.

---

## 2. Fuentes de verdad y jerarquía

Los documentos viven en el Project de claude.ai "LifeQuest". Cuando dos fuentes se contradicen, manda la de mayor rango:

| Rango | Documento | Para qué sirve |
|---|---|---|
| 1 | `schema.sql` (v2, oct 2026) | Verdad del **modelo de datos**: tablas, enums, triggers, vistas y RLS. |
| 2 | `Requerimientos_Funcionales.md` | 116 RF verificables (RF-001…RF-116). Verdad del **comportamiento**. |
| 3 | `Casos_de_Uso.md` | 31 UC con trazabilidad a los RF. |
| 4 | `Esquema_Base_de_Datos.md` | Justificación del esquema y registro de cambios (C1–C8). |
| 5 | `docs/ideas-proyecto-productividad-gamificada.md` | Documento vivo de diseño: el "porqué". Su versión de **cierre del diseño (oct 2026)** trae decisiones más nuevas que los RF y el esquema (ver §13). |

**Al cambiar algo:**
- Cita siempre el RF que justifica el cambio (ej. `-- RF-032`).
- Si cambias `schema.sql`, actualiza también `Esquema_Base_de_Datos.md`.
- Si una decisión nueva altera un RF o un UC, actualiza ambos documentos y mantén la trazabilidad RF ↔ UC.
- No inventes valores de la economía: usa los de `docs/ideas-proyecto-productividad-gamificada.md` (sección «Economía estable») o déjalos como configuración marcada como provisional.
- Diseño visual y producto: `DESIGN.md` y `PRODUCT.md` **se están rehaciendo desde cero** (ver §14).
- **Decisiones de §13 que chocan con un RF o con el esquema:** antes de implementarlas, actualiza el RF, el UC y `schema.sql`. Hasta entonces mandan RF y esquema.

---

## 3. Stack tecnológico

| Capa | Tecnología | Estado |
|---|---|---|
| Base de datos | **PostgreSQL** | ✅ Decidido (el esquema ya está escrito para Postgres 15+; probado en 16) |
| Backend / BaaS | **Supabase**: Auth (`auth.users`), PostgREST, RLS, Storage, Edge Functions, `pg_cron` | ✅ Decidido por el esquema |
| Frontend móvil | **Flutter / Dart** | 🟡 Stack considerado, aún sin confirmación formal |
| Lógica de servidor | Funciones Postgres (`plpgsql`, `SECURITY DEFINER`, expuestas por RPC) y Edge Functions | ✅ Patrón recomendado (ver §8) |
| IA (RPGenie) | Por definir. Empieza como **reglas simples**; IA real solo en fase avanzada | 🟡 |

Alternativas evaluadas y descartadas de hecho al elegir Supabase: Node.js + Express propio, Firebase/Firestore.

**Extensiones de Postgres:** `pgcrypto` (para `gen_random_uuid()`) y `pg_cron` (para el job diario de rachas).

---

## 4. Glosario: término del juego → entidad

| Término en la app | Qué es | Dónde vive |
|---|---|---|
| Personaje / Perfil | Identidad, nivel, XP, Monedas, HP | `profiles`, `character_stats` |
| "¿Quién eres en este reino?" | Declaración de identidad que también usan los NPCs | `profiles.identity_statement` |
| Vision Board | Visión de largo plazo del usuario (1 por usuario) | `vision_boards`; vínculo con `goals/projects.linked_to_vision` |
| **Skill = Área** | Categoría creada 100 % por el usuario (máx. 6), con nivel propio sin tope. **Es** el Área de P.A.R.A. | `skills` (no existe tabla `areas`) |
| Brain Dump | Bandeja de captura sin clasificar | `brain_dump_entries` |
| Diagnosis Tool (G.T.D.) | Checklist cerrado Tarea / Proyecto / Meta | Lógica de app; el resultado queda en `tasks.source = 'gtd_diagnosis'` |
| S.M.A.R.T. Diagnosis Tool | Formulario de 5 categorías para crear Metas | Lógica de app; respuestas en `goals.smart_*` |
| Meta = **Boss** | Objetivo de meses. La misma fila es la Meta de P.A.R.A., el objetivo S.M.A.R.T. y el Boss | `goals` (`boss_max_hp`, `boss_current_hp`) |
| Proyecto | Resultado de semanas con lista de tareas y urgencia automática | `projects` |
| Tarea / Misión / Subtarea | Unidad accionable | `tasks` (`parent_task_id` para subtareas) |
| Misión de NPC | Una **tarea real**, no una entidad aparte | `tasks` con `source = 'npc'` y `npc_id` |
| Taverna / NPC | Personajes creados por el usuario que piden misiones | `npcs`, documento de contexto en `resources` |
| Hábito bueno / malo | Bueno da recompensa; malo resta HP por evento | `habits`, `habit_records` |
| Racha | Días seguidos cumpliendo un hábito bueno | `habits.current_streak`, `best_streak` |
| Deep Working | Contenedor de la sesión de concentración | `focus_sessions`, `focus_session_tasks` |
| Mazmorra | Cada ciclo Pomodoro dentro de la sesión | `dungeon_runs` |
| Historial de Misiones / Bitácora | Registro de todo lo cumplido o fallado | `quest_log_entries` |
| Diario del Héroe | Texto narrativo diario (caché). **Eliminado en el cierre del diseño** (§13) | `hero_journal_entries` |
| Marketplace / Tienda | Catálogo global cerrado: Descanso, Indulgencia, Experiencia | `market_items`, `user_market_selection`, `purchases` |
| Hotel | Compra de recuperación de HP | `hp_recovery_purchases` |
| Mercado negro | Ítems raros, p. ej. "Recuperar racha" | `black_market_items`, `black_market_redemptions` |
| Pase de Recuperación | Protege la racha de un hábito en un día fallido | `recovery_passes` |
| Game Master | Configuración: reglas que el propio usuario define | `game_master_settings` |
| Stage · P.A.R.A. | **Vista / dashboard**, no un sistema con datos propios | Lee `tasks`, `projects`, `goals`, `skills`, `resources`, `calendar_events` |
| RPGenie | Asistente que recomienda la "Misión actual" y diseña misiones de NPC | Sin tabla; lee datos existentes y escribe `tasks` |

---

## 5. Arquitectura funcional

### Menú principal (9 secciones, RF-114)

> **Superado por el diseño (§13):** la navegación es una barra inferior de 5 pestañas (Inicio · Stage · Hábitos · Mazmorra · Perfil), ver `docs/ideas-proyecto-productividad-gamificada.md` → Menú / Navegación principal. Esta lista se conserva como inventario de contenidos de RF-114 hasta actualizar el RF.

1. **Perfil del Personaje**: nivel, Monedas, HP, identidad, tasa de finalización, árbol de skills. Desde aquí se accede a **Inventario/Logros** y **Configuración (Game Master)**.
2. **RPGenie — Misión actual**.
3. **Stage · P.A.R.A. (G.T.D.)**: centro de mando. Aquí viven las misiones (ya no es ítem propio del menú).
4. **Diario**: solo la Bitácora filtrable, sin datos propios y sin Diario del Héroe (§13; RF-116 pendiente de actualizar). Se abre desde Perfil.
5. **Hábitos**: buenos y malos, con estadísticas de crecimiento y mapa de calor.
6. **Mazmorras / Deep Working**.
7. **Objetivos**: Goal → Boss Fight + Growth (S.M.A.R.T.).
8. **Taverna**: NPCs.
9. **Marketplace — Reward**: Tienda, carrito, My Purchases, Hotel, Mercado negro.

### Jerarquía de trabajo

```
Meta (Boss) ─┬─ Proyecto ── Tarea ── Subtarea
             └─ Tarea (vinculada directo a la Meta)
```

- **No existe el nivel "Historia"** (se eliminó para no mezclar Scrum con P.A.R.A.).
- Un Proyecto puede existir sin Meta (`goal_id` opcional).
- Completar un Proyecto **o** una Tarea vinculados a una Meta le resta vida al Boss. Solo las Metas son Bosses.

### Diagnosis Tool G.T.D. (vive en el MVP, reglas simples, sin IA)

1. ¿Es accionable? → **No**: se guarda como Referencia o "Algún día" en el Brain Dump y termina.
2. ¿Un paso o varios? → **Uno**: candidato a Tarea. **Varios**: sigue a 3b.
   - 3b. ¿Lista de tareas en semanas (**Proyecto**) o resultado amplio en meses (**Meta**)?
3. ¿Se hace en 2 minutos? → Sugerir completarla al instante.
4. ¿Soy la persona correcta? → **No**: Tarea con estado `delegated` y campo opcional "¿a quién?" (RF-011).
5. ¿Tiene tiempo específico? → **Sí**: fecha o Calendario. **No**: lista de próxima acción.

Se usa **la misma instancia** desde Brain Dump y desde Quick Add de P.A.R.A. (RF-014). En Quick Add, Task/Project pasan por G.T.D., Goal pasa por S.M.A.R.T. y Area/Resource/Event se crean directo.

---

## 6. Reglas de negocio clave

### Economía dual
- **XP**: mide progreso, **nunca se gasta**, sube el nivel del personaje y el de la skill asociada.
- **Monedas**: se ganan junto al XP y **sí se gastan**. Según el diseño (§13), son el 30 % de la XP e iguales en todas las dificultades.
- Gastar Monedas nunca debe sentirse como perder avance.
- La dificultad del usuario aplica multiplicadores (`difficulty_levels`, semilla provisional):

| Nivel | XP | Monedas | Penalización HP |
|---|---|---|---|
| `easy` | ×1.20 | ×1.20 | ×0.80 |
| `normal` | ×1.00 | ×1.00 | ×1.00 |
| `hard` | ×0.80 | ×0.80 | ×1.20 |

> **Superado por §13 (cerrado el 2026-10-18):** XP ×1,2 / ×1 / ×0,85; vida perdida ×0,75 / ×1 / ×1,25; Monedas iguales. Se elige en el Onboarding y solo se cambia en Configuración. La semilla de `difficulty_levels` ya la actualiza `004_structure.sql`.

### Recompensa sugerida (RF-022)
Se calcula a partir de `difficulty` y `estimated_minutes`, multiplicada por la dificultad del usuario. El usuario puede editarla. Anti-inflado: la recompensa no puede subir por editar repetidamente la descripción (RF-112).

> **Superado por §13:** las tareas ya no tienen tiempo estimado ni dificultad elegida por el usuario; RPGenie calcula la XP por reglas (10–40) y el usuario no la edita. Reglas en `docs/ideas-proyecto-productividad-gamificada.md` → Estimación automática de recompensa. Antes de implementarlo hay que actualizar RF-022 y quitar `tasks.difficulty` y `tasks.estimated_minutes` del esquema.

### Urgencia automática de Proyectos (RF-019/020)
```
ritmo_necesario = trabajo_restante / días_restantes
ritmo_actual    = trabajo_completado / días_transcurridos

si ritmo_necesario > ritmo_actual × 1.5 → high   🔴
si ritmo_necesario > ritmo_actual × 1.2 → medium 🟡
en otro caso                             → low    🟢
```
Todo cambio de nivel **se notifica siempre** (RF-021). La escala de 3 niveles (`urgency_level`) es la **única escala de urgencia de toda la app**.

### HP / Vitalidad
- Es un indicador **agregado** de constancia, no ligado a un solo hábito.
- **Resta HP** (valor fijo × multiplicador de dificultad):
  - Plazo incumplido de Tarea, Proyecto o Meta: mismo valor fijo para los tres (RF-030).
  - Cada registro de mal hábito (RF-032).
  - Sesión de Deep Working cerrada con tareas sin completar: valor inicial que **baja proporcionalmente** según las tareas completadas (RF-031).
- **Recupera HP**: actividad regular sostenida o compra en el Hotel.
- **Estado "debilitado"**: HP ≤ 20 % de `hp_max` → −10 % de XP/Monedas ganados mientras dure. **Nunca bloquea acciones y nunca hay "muerte"** ni pérdida de progreso (RF-034). En BD, `is_weakened` es una columna generada.

### Hábitos y rachas
- Hábito bueno: **un registro por día**, da XP + Monedas pequeños. Hábito malo: **un registro por evento** (varios por día), cada uno con su `hp_change`.
- Frecuencia: diaria o días específicos (`specific_days`, 0 = domingo … 6 = sábado).
- La racha sube con un trigger al registrar el hábito bueno. La función `break_missed_streaks(fecha)` corre **a diario** y pone en cero las rachas falladas, salvo que el día esté protegido por un Pase de Recuperación o un "Recuperar racha".

### Deep Working + Mazmorras
- El usuario define duración total, tareas asignadas y ciclo de **25, 30 o 45 min**.
- Los ciclos se encadenan solos: Mazmorra → XP + Monedas → descanso → siguiente ciclo.
- Descansos por defecto: **5 min** corto y **15 min** largo cada **4 ciclos**, sin importar la duración del ciclo; configurables en Game Master (RF-067).
- Se puede pausar, saltar un descanso o terminar antes **sin perder lo ganado**. Al cerrar se muestra un resumen.

### Estado único de objetivos (RF-084)
Un solo estado real: `objective_status` = `not_started | in_progress | completed | expired`. Cada pantalla le pone su propia "piel" **solo en la UI**:

| Estado real | Boss Fight / Growth | Calendario P.A.R.A. |
|---|---|---|
| `not_started` / `in_progress` | ¡Sigue así! | In progress / Do it now! |
| `completed` | Éxito | Completed |
| `expired` | Fracaso | EXPIRED |

**Nunca crees un estado nuevo en BD para un rótulo visual.**

### Daily Highlight (RF-089, vista `v_daily_highlight`)
Muestra las tareas abiertas (sin subtareas) en buckets derivados, en este orden: **urgent** (vence en menos de 24 h o ya venció) → **high** → **medium** → **low** → **pending** (tarea delegada).

### Skills
Máximo 6 por usuario (trigger `enforce_skill_limit`, ampliable con `game_master_settings.skill_limit`). Sin tope de nivel. Un NPC **debe** tener skill; en Metas, Proyectos, Tareas y Hábitos es opcional. Un Proyecto sin skill muestra la advertencia "No area assigned".

### Marketplace
Catálogo **global y cerrado**, sin texto libre del usuario (RF-043). El usuario solo elige qué ítems ve en su Tienda (`user_market_selection`, vista `v_user_store`, RF-048). El carrito es estado del cliente; al confirmar, cada ítem se vuelve una fila de `purchases`. El Pase de Recuperación y el Mercado negro tienen **cooldown y contador de usos**.

### RPGenie (versión 1, solo reglas)
Prioriza la "Misión actual" así: cualquier candidata en estado Crítico → urgencia 🔴 > 🟡 > 🟢 → fecha límite más próxima (RF-097). Diseña las misiones de los NPCs como `tasks` reales con el cooldown de `npcs.last_mission_at`.

---

## 7. Notificaciones (diseño anti-estrés)

| Nivel | Ejemplos | Entrega |
|---|---|---|
| `critical` | Racha a punto de romperse; proyecto pasa a 🔴 | Individual e inmediata. Salta la ventana de silencio **solo** si `critical_bypass_silence = true` |
| `motivational` | Cerca de subir de nivel, logro, hito S.M.A.R.T. | En el momento; **nunca se repite** si se ignora |
| `informational` | Recordatorio diario, resumen de hábitos, Diario listo | Agrupada en un **digest** (`digest_slot` mañana/noche, `digest_time`) |

**Reglas:**
- Sin límite diario por defecto (`notification_daily_limit` NULL) y sin ventana de silencio por defecto. Ambos se activan desde Game Master.
- Silencio automático de lo no crítico durante una sesión de Deep Working activa.
- **Nunca notificar dos veces el mismo evento**: `event_key` único por usuario, con formato `<categoría>:<entidad_id>:<fecha>`.
- Frecuencia decreciente: si una `category` se ignora **5 veces seguidas** (`ignore_threshold`), baja su frecuencia; el trigger mantiene `notification_category_state`.
- Las alertas de fin de ciclo o de descanso son **alertas de sesión**: quedan fuera del digest, del límite y de la ventana de silencio.
- **Tono de invitación, nunca de amenaza ni culpa.** ✅ "Tu racha de 12 días te está esperando 🔥". ❌ "¡Vas a perder tu racha!".

---

## 8. Instrucciones de codificación

### Base de datos (PostgreSQL / Supabase)
- `schema.sql` es la fuente de verdad. Todo cambio va con su comentario de RF y su reflejo en `Esquema_Base_de_Datos.md`.
- PK `uuid default gen_random_uuid()`. Timestamps `timestamptz default now()`.
- Estados cerrados con **enums de Postgres**, nunca `text` libre.
- **Toda tabla con `user_id` tiene RLS** con la política `auth.uid() = user_id`. Los catálogos globales (`achievements`, `inventory_items`, `market_items`, `black_market_items`, `difficulty_levels`) son de solo lectura para usuarios autenticados y se administran con la `service_role`.
- Las vistas se crean con `with (security_invoker = true)` para respetar el RLS.
- **Lo derivable no se guarda a mano:** usa columnas generadas (como `is_weakened`) o vistas (como `v_daily_highlight` y `v_user_store`).
- Las referencias polimórficas (`quest_log_entries.source_id`, `brain_dump_entries.converted_to_id`, `notifications.related_entity_id`) no tienen FK física: valídalas en la función que inserta.
- Las referencias opcionales a `skills` usan `ON DELETE SET NULL`; la de `npcs` usa `ON DELETE RESTRICT`.
- **No crees tablas para**: Áreas, P.A.R.A., NpcMission, Objetivo Personal, Historia, Diario (más allá del caché), Diagnosis Tools ni el carrito.

### Economía y anti-trampa (prioridad alta)
- **El cliente nunca escribe recompensas ni penalizaciones.** Completar una tarea, registrar un hábito, cerrar una Mazmorra, comprar, canjear un pase o aplicar HP se hace mediante **funciones `SECURITY DEFINER` llamadas por RPC** (o Edge Functions) que, en una sola transacción:
  1. validan la propiedad y el estado,
  2. aplican el multiplicador de dificultad y el −10 % si está debilitado,
  3. actualizan `character_stats` y la `skill`,
  4. escriben la fila en `quest_log_entries`.
- Analogía: como en un juego en línea, el jugador **ve** su oro, pero solo el servidor puede **cambiarlo**.
- Las migraciones `003_security.sql` a `008_fix_exploits.sql` (`supabase/migrations/`) cierran la escritura del cliente en las tablas económicas y dan las RPC del juego (`complete_task`, `complete_project`, `complete_habit`, `register_bad_habit`, `claim_daily_chest`, `purchase`, `buy_black_market`, `use_recovery_pass`, `upgrade_refuge`, `request_npc_mission`, `activate_elixir`, `complete_dungeon_cycle`). Todo pago pasa por `_award`; los números viven en `game_rules`. `audit_double_rewards()` (solo `service_role`) lista cobros repetidos sin corregirlos. Plan y estado: `docs/plan-cambios-esquema.md`. ⚠️ Aplicarlas en Supabase en orden.

### Frontend (Flutter)
- Antes de tocar UI, lee la sección **§14 Diseño**.
- Textos de UI en español, con el tono de invitación de §7.
- Las "pieles" de estado (Éxito/Fracaso, "¡Hazlo ahora!") son un mapeo en la UI sobre `objective_status`.
- Stage · P.A.R.A., el Diario y el Daily Highlight son **pantallas de lectura** sobre datos de otros módulos: no deben duplicar datos.
- El Brain Dump debe abrirse desde cualquier pantalla con la mínima fricción (Modelo de Fogg).
- Dentro de una sesión de Deep Working: sin navegación extra ni ruido.

### Arquitectura Flutter (obligatoria)
Feature-Driven Clean Architecture con **Bloc**, **get_it**, **go_router**, **fpdart** (`Either`) y **equatable**.

```
lib/
├── app/
│   ├── config/        # app_router (go_router), route_paths, app_shell, theme, constants
│   ├── observers/     # AppBlocObserver
│   └── app.dart       # MaterialApp.router + AuthBloc global
├── core/
│   ├── errors/        # exceptions.dart (data) y failures.dart (domain)
│   ├── usecases/      # UseCase<Result, Params> + NoParams
│   └── widgets/       # widgets compartidos entre features (excepción acordada)
├── features/<feature>/
│   ├── data/          # datasources/, models/ (toEntity), repositories/ (*_repository_impl)
│   ├── domain/        # entities/, repositories/ (abstract), usecases/ (uno por archivo, call())
│   └── presentation/  # blocs/ (_bloc, _event, _state), screens/ (*_screen), widgets/
├── injection_container.dart   # registro de todo con get_it (sl)
└── main.dart
test/                  # refleja lib/; mocks en test/helpers/mocks.dart (mocktail + bloc_test)
```

**Reglas no negociables:**
1. `domain` es Dart puro: solo `equatable` y `fpdart`. Ni Flutter, ni Supabase, ni data/presentation.
2. `presentation` solo conoce `domain` (usecases y entities), nunca models ni datasources.
3. `data` implementa los contratos de `domain`; los models convierten con `toEntity()`.
4. Los datasources lanzan `ServerException`/`NetworkException`; los repositorios devuelven `Left(Failure)` con el mensaje en español.
5. Cada usecase tiene una sola responsabilidad y expone `call()`.
6. Una feature no importa otra. Lo compartido va en `core/`; la composición (rutas, sesión, callbacks entre features) va en `app/`.
7. Toda dependencia se registra en `injection_container.dart` y se inyecta por constructor.
8. Nada de lógica de negocio en widgets ni screens.

**Convenciones:** archivos en `snake_case`; sufijos `Model`, `RepositoryImpl`, `RemoteDataSource`, `LocalDataSource`, `Bloc`, `Screen`; estados `Initial`, `Loading`, `Success`, `Failure(message)`; imports siempre `package:proyecto_movil/...`.

**Flujo para crear una feature (de adentro hacia afuera):** domain (entities → repositorio abstracto → usecases) → data (models → datasources → repository impl) → presentation (bloc → widgets → screens) → registro en `injection_container.dart` y ruta en `app/config/app_router.dart` → tests de usecases, repositorio y bloc.

**Desviaciones acordadas:** sin Dio ni `core/network` (el SDK de Supabase es el cliente HTTP); los widgets compartidos viven en `core/widgets/`.

**Deuda de arquitectura:** `auth`, `home` y la pantalla principal de `profile` cumplen las 3 capas. `home` lee la RPC `home_dashboard` (`supabase/migrations/001_home.sql`); `profile` lee `profile_overview` y edita identidad y skills (`002_profile.sql`); `009_profile_titles.sql` le añade el Tesoro, el título activo y los títulos ganados, y la RPC `set_active_title` para elegirlo. Siguen fijos: Accesos rápidos y Explora el reino del Home, y las subpáginas Notificaciones y Ayuda. Apariencia se abre desde Configuración (`/settings/appearance`) y guarda el tema (claro/oscuro/sistema) con `AppearanceBloc` global y `shared_preferences`. Las migraciones se prueban con `supabase/tests` (`npm install && npm test`). Misiones, hábitos, dungeon, ajustes, objetivos, diario, marketplace, stage, taverna y RPGenie tienen solo `presentation/` y guardan estado y datos de ejemplo en las screens (incumplen la regla 8). Cada una se migra con el flujo de arriba al conectarla a sus tablas. Las rutas de esas pantallas se fuerzan a tema claro (`LifeQuestTheme.lightOnly`) hasta que usen `context.lq`. Perfil y Apariencia ya usan `context.lq`; al migrar otra pestaña, añade su ruta a `_themedPaths` en `app_router.dart`.

### Calidad
- Prueba los cambios de SQL contra un Postgres real (con un stub de `auth.users`, `auth.uid()` y `auth.role()` si no es Supabase).
- Prueba el comportamiento, no solo la sintaxis: límites, unicidad, triggers y aislamiento de RLS entre dos usuarios.

---

## 9. Principios de diseño (no negociables)

- **Ético primero:** ninguna mecánica existe solo para que el usuario abra más la app; debe reforzar comportamiento productivo real. **Prohibidos los dark patterns.**
- El HP nunca mata al personaje ni borra progreso. Las penalizaciones son graduales, nunca punitivas de golpe.
- Las recompensas aleatorias son **cosméticas**, nunca apuestas.
- **Autonomía:** el usuario define sus skills, su Tienda (dentro del catálogo), su dificultad y sus notificaciones.
- **Marcos de referencia:** Autodeterminación (Deci y Ryan), Modelo de Fogg, Fijación de metas (Locke y Latham), Efecto Zeigarnik, Refuerzo variable (Skinner), Flow, Intenciones de implementación (Gollwitzer), Bucle del hábito (Duhigg), Aversión a la pérdida (Kahneman y Tversky), **Octalysis** (Yu-Kai Chou), **G.T.D.** (David Allen), **P.A.R.A.** y **S.M.A.R.T.**

---

## 10. Fuera de alcance (no implementar)

| Ítem | Motivo |
|---|---|
| Financial Vault (ingresos, gastos, presupuestos, wish list, cuentas) | Pausado; se conserva el diseño, sin tablas |
| Personalización visual completa (avatar, ropa, temas visuales completos como pixel art, marcos, cosméticos sorpresa) | Falta decidir el enfoque (arte propio o modelos generativos). **Sí entran** el modo claro/oscuro/automático y temas de color (los 4 del paquete se quitaron; pendientes de rediseño, §13) |
| Modo cooperativo, gremios y rankings | Foco en un solo usuario |
| Autorecompensas de texto libre en la Tienda | Eliminadas; reemplazadas por el catálogo cerrado |
| Planificación de MVP y fases | Retirada hasta cerrar las especificaciones |

---

## 11. Decisiones abiertas (no las cierres sin consultar)

- **Propuesta del cierre del diseño por confirmar:** orden de prioridad de la Misión actual (§13). *(Cerrados el 2026-10-18: debilitado < 30 de vida y −25 % de XP, 48 h para salvar una racha y multiplicadores de dificultad con Monedas iguales; ver `docs/plan-cambios-esquema.md` §7.)*
- **Economía:** los valores (§13) ya están en las migraciones 004–007 (`game_rules`, semillas de `difficulty_levels`, `market_items` y `black_market_items`, Refugio, Tesoro, tope diario); falta validarlos con usuarios reales el primer mes.
- **Daily Highlight, "Pending":** definido como "tarea delegada"; otra propuesta del equipo era "sin fecha".
- **Diagnosis G.T.D., pregunta 4:** se mantiene RF-011 (estado `delegated` con «¿a quién?»); el «Evento con contacto» del cierre del diseño queda descartado por ahora (2026-10-18).
- **Tipo de misión** diaria / semanal / épica (RF-050): ¿basta `repeat_rule` o se agrega un enum `mission_type`?
- **Renombrar enums de dificultad:** `difficulty_scale` → `task_difficulty`, `difficulty_level` → `game_difficulty` (propuesto). `004_structure.sql` ya borra `difficulty_scale`.
- **Bitácora:** ¿notas propias del usuario? ¿filtro por skill/Área?
- **RPGenie avanzado:** fórmula de "ritmo necesario" con el ritmo histórico del usuario, y el modelo de IA.
- Decisiones abiertas del esquema (recompensa de NPC, precio del Refugio, catálogos de títulos, cofre y logros, RF-031): ver `docs/plan-cambios-esquema.md` §7.

---

## 12. Deuda documental conocida

- `docs/ideas-proyecto-productividad-gamificada.md` (copia del paquete de diseño, oct 2026) ya cerró la mayoría de pendientes, pero conserva la sección de MVP y fases (retirada, ver §10), menciona `NpcMission` y entidades del Vault en Arquitectura, mantiene Node.js/Firebase como stack posible y marca como pendiente la duración de los descansos, que RF-067 ya fijó.
- **RF, UC, `schema.sql` y `Esquema_Base_de_Datos.md` no reflejan todavía las decisiones de §13** (Diario del Héroe, recompensa por reglas, dificultad, economía, navegación, temas de color). Las migraciones 003–007 sí las aplican; faltan RF-022, RF-030, RF-034, RF-043, RF-048, RF-112 y RF-116 (ver `docs/plan-cambios-esquema.md` §7).
- `Casos_de_Uso.md` tiene referencias cruzadas rotas: UC-08 apunta a UC-12 (debe ser UC-10) y a UC-17 (debe ser UC-15); UC-09 apunta a UC-13 (debe ser UC-11).
- RF-048 conviene reescribirlo como "elegir qué ítems del catálogo aparecen en su Tienda".
- El código implementa el sistema visual anterior («El Jardín del Héroe»: Roboto, `LifeQuestColors` / `context.lq`, navegación Inicio · Misiones · Dungeon · Hábitos · Perfil). El nuevo sistema visual se definirá en `DESIGN.md` (pendiente).
- El documento explicativo del esquema hecho en otro chat describe la **v1** (31 tablas). La v2 tiene **33 tablas, 18 enums y 2 vistas**.

---

## 13. Decisiones del cierre del diseño (oct 2026)

Vienen de `docs/ideas-proyecto-productividad-gamificada.md` (versión del paquete de diseño), tras diseñar 60 tableros en el lienzo "Questly — Diseño de la app" (sistema de diseño «Bosque vivo»). Son más nuevas que los RF y el esquema; la columna **Choca con** dice qué hay que actualizar antes de implementarlas (§2).

| Tema | Decisión | Choca con |
|---|---|---|
| Diario | **Se elimina el Diario del Héroe.** El Diario es solo la Bitácora (`quest_log_entries`) con un resumen semanal arriba y enlace a Estadísticas. Filtros: Todo, Tareas, Hábitos, Mazmorras, Metas | RF-116, `hero_journal_entries` |
| Recompensa de tareas | Sin tiempo estimado ni dificultad elegidos por el usuario. XP por reglas, **10–40 por tarea**: base 10; +10 si el título tiene ≥ 5 palabras; +10 prioridad alta / +5 media; +10 si va vinculada a una Meta / +5 a un Proyecto. Monedas = 30 % de la XP. El usuario no la edita y editar la tarea no la recalcula (cierra RF-112) | RF-022, `tasks.difficulty`, `tasks.estimated_minutes` |
| Dificultad | Solo se cambia en Configuración (y se elige en el Onboarding). XP ×1,2 / ×1 / ×0,85; vida perdida ×0,75 / ×1 / ×1,25; **Monedas iguales** en las tres | Semilla de `difficulty_levels` (§6) |
| Niveles | XP para subir: 100 × nivel^1,5 | — |
| HP (propuesta) | Mal hábito −3 / −5 / −8 según la gravedad que elige el usuario; plazo incumplido −5; día sin jugar −5; +4 por día con al menos un hábito bueno (+1 por nivel del Huerto). **Debilitado:** por debajo de 30 de vida, −25 % de XP y nunca menos Monedas | RF-034 (≤ 20 %, −10 % de XP y Monedas) |
| Rachas | Al romperse hay **48 h** para usar un Pase o "Recuperar racha"; el récord se guarda | — |
| Economía estable y catálogo | Monedas = 30 % de la XP, tope suave diario (75 máx.), bolsa con límite y Tesoro del reino, precios fijos, Refugio creciente, anti-trampa, entradas, catálogo (Hotel, Mercado, Mercado negro, Refugio) y ajuste post-lanzamiento. **Valores en `docs/ideas-proyecto-productividad-gamificada.md` → Economía estable** | Esquema (faltan tablas); `market_items`, `black_market_items` sin semilla |
| Navegación | Barra inferior de 5 pestañas: **Inicio · Stage · Hábitos · Mazmorra · Perfil**. Desde Inicio: Taverna, Brain Dump, Misión actual, Boss Fight y Avisos. Desde Perfil: Diario, Estadísticas, Vision Board, Inventario y logros, Marketplace y Configuración. Onboarding de 5 pasos | Código actual (Inicio, Misiones, Dungeon, Hábitos, Perfil); RF-114 |
| Apariencia | Modo claro / oscuro / automático en Configuración (Game Master), aplicado a toda la app. Hoy el modo está implementado en Perfil → Apariencia (`AppearanceBloc`). **Temas de color: los 4 del paquete (Bosque, Río, Brasa, Oro) se quitaron el 2026-10-18; pendientes de rediseño** | `game_master_settings` (sin columnas de apariencia) |
| Mazmorra | **Mochila de misiones:** hoja con buscador y filtros (Sugeridas, Hoy, Urgentes, Todas), máx. **5 tareas** por sesión, mapa de ruta de mazmorras y descansos. Duración del bloque en pasos de 30 min | — |
| Taverna | "Pedir misión al momento": gratis cada 3 h, si no cuesta 15 Monedas. Máx. 3 NPCs (+1 por nivel de Estandarte). Asistente "Crear NPC" en 4 pasos | — |
| Boss Fight | Arena con vida y fecha, ataques disponibles (cada tarea o proyecto vinculado con su daño), golpes recientes y ficha S.M.A.R.T. Victoria: +300 XP, +90 Monedas y un título. Si vence la fecha: "El jefe escapó… por ahora", se conserva la XP, sin castigo extra, y se ofrece replantear o archivar | — |
| RPGenie (propuesta) | Prioriza: vence antes → más daño a jefes activos → lo más ligero si el usuario dice estar cansado o con poco tiempo. "Ahora no" (cansado / poco tiempo / no es prioridad / ya no quiero) cambia la misión sin castigo | RF-097 |
| Inventario | Vive en el Perfil (pestañas Logros y Objetos). Los **títulos de prestigio** se ganan (logros, nivel, Tesoro), no se compran | — |
| Estadísticas | Pantalla nueva desde Perfil y Diario: XP, misiones, tiempo en Mazmorra y racha comparados con el periodo anterior; XP por día y por Área; hábitos más constantes; 3 observaciones de RPGenie | — |
| Notificaciones (UI) | Centro de avisos con pestañas Todos / Importantes. En pantalla: **▲ Crítico · ● Importante · ○ Informativo** ("Importante" agrupa lo motivacional), siempre símbolo + texto | — |
| Entidades nuevas sin tabla | Mejoras del Refugio, Tesoro del reino, control del tope diario de Monedas, consumibles (Elixir, Cofre) y títulos | Esquema |

---

## 14. Diseño

> **Reinicio (2026-10-18):** `DESIGN.md`, `PRODUCT.md` y el paquete de pantallas se borraron para empezar de cero. Se rehacen tomando como punto de partida `docs/ideas-proyecto-productividad-gamificada.md`.

Mientras no existan:
- No inventes colores, fuentes, tamaños ni componentes nuevos: no toques la UI salvo que se pida.
- El código sigue con `LifeQuestColors` / `context.lq` y el modo claro/oscuro de `AppearanceBloc`.
- **Accesibilidad WCAG 2.1 AA** sigue siendo obligatoria: contraste 4,5:1 (3:1 texto grande), zonas táctiles amplias, `Semantics` en botones de icono y el color nunca va solo.
- La Mazmorra (Deep Working) es siempre oscura y respeta la reducción de movimiento del sistema.

Cuando existan, esta sección se reescribe para apuntar a ellos.

<!-- SPECKIT START -->
For additional context about technologies to be used, project structure,
shell commands, and other important information, read the current plan:
`specs/004-profile-update/plan.md`
<!-- SPECKIT END -->
