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
| 5 | `ideas-proyecto-productividad-gamificada.md` | Documento vivo de diseño: el "porqué". **Está desactualizado** respecto a los RF (ver §12). |

**Al cambiar algo:**
- Cita siempre el RF que justifica el cambio (ej. `-- RF-032`).
- Si cambias `schema.sql`, actualiza también `Esquema_Base_de_Datos.md`.
- Si una decisión nueva altera un RF o un UC, actualiza ambos documentos y mantén la trazabilidad RF ↔ UC.
- No inventes valores de la economía (ver §11): déjalos como configuración o semilla marcada como provisional.

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
| Diario del Héroe | Texto narrativo diario (caché) | `hero_journal_entries` |
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

1. **Perfil del Personaje**: nivel, Monedas, HP, identidad, tasa de finalización, árbol de skills. Desde aquí se accede a **Inventario/Logros** y **Configuración (Game Master)**.
2. **RPGenie — Misión actual**.
3. **Stage · P.A.R.A. (G.T.D.)**: centro de mando. Aquí viven las misiones (ya no es ítem propio del menú).
4. **Diario**: el texto del Diario del Héroe seguido del Historial filtrable, sin datos propios (RF-116).
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
- **Monedas**: se ganan junto al XP (proporcionales a la dificultad) y **sí se gastan**.
- Gastar Monedas nunca debe sentirse como perder avance.
- La dificultad del usuario aplica multiplicadores (`difficulty_levels`, semilla provisional):

| Nivel | XP | Monedas | Penalización HP |
|---|---|---|---|
| `easy` | ×1.20 | ×1.20 | ×0.80 |
| `normal` | ×1.00 | ×1.00 | ×1.00 |
| `hard` | ×0.80 | ×0.80 | ×1.20 |

### Recompensa sugerida (RF-022)
Se calcula a partir de `difficulty` y `estimated_minutes`, multiplicada por la dificultad del usuario. El usuario puede editarla. Anti-inflado: la recompensa no puede subir por editar repetidamente la descripción (RF-112).

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
- ⚠️ El `schema.sql` v2 **todavía** concede escritura `ALL` al dueño en tablas económicas (`character_stats`, `quest_log_entries`, `user_achievements`, `recovery_passes`, `black_market_redemptions`, `dungeon_runs`, `hp_recovery_purchases`, `purchases`). Al tocar estas tablas, migra a: **cliente solo `SELECT`** + funciones RPC.

### Frontend (Flutter)
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

**Deuda de arquitectura:** solo `auth` cumple las 3 capas. Home, misiones, hábitos, dungeon, perfil, ajustes, objetivos, diario, marketplace, stage, taverna y RPGenie tienen solo `presentation/` y guardan estado y datos de ejemplo en las screens (incumplen la regla 8). Cada una se migra con el flujo de arriba al conectarla a sus tablas. Las rutas de esas pantallas se fuerzan a tema claro (`LifeQuestTheme.lightOnly`) hasta que usen `context.lq`.

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
| Personalización visual completa (avatar, ropa, temas, marcos) | Falta decidir el enfoque (arte propio o modelos generativos) |
| Modo cooperativo, gremios y rankings | Foco en un solo usuario |
| Autorecompensas de texto libre en la Tienda | Eliminadas; reemplazadas por el catálogo cerrado |
| Planificación de MVP y fases | Retirada hasta cerrar las especificaciones |

---

## 11. Decisiones abiertas (no las cierres sin consultar)

- **Economía numérica:** valor fijo de HP por penalización, multiplicadores definitivos, precios y cooldowns del Hotel y del Mercado negro, catálogo concreto de la Tienda. `black_market_items` no tiene semilla todavía.
- **Daily Highlight, "Pending":** definido como "tarea delegada"; otra propuesta del equipo era "sin fecha".
- **Tipo de misión** diaria / semanal / épica (RF-050): ¿basta `repeat_rule` o se agrega un enum `mission_type`?
- **Anti-inflado (RF-112):** propuesta de guardar `suggested_xp` y `suggested_coins` en `tasks`.
- **Renombrar enums de dificultad:** `difficulty_scale` → `task_difficulty`, `difficulty_level` → `game_difficulty` (propuesto).
- **Goal → Boss Fight:** el usuario hará ajustes al final del diseño, como el cálculo del daño al Boss.
- **Inventario/Logros:** ¿dentro de Perfil (como dicen los RF) o también en el Diario?
- **RPGenie avanzado:** fórmula de "ritmo necesario" con el ritmo histórico del usuario, y el modelo de IA.
- Job diario de rachas: `pg_cron` o Edge Function programada.

---

## 12. Deuda documental conocida

- `ideas-proyecto-productividad-gamificada.md` aún marca como pendientes decisiones que los RF ya cerraron (estado debilitado, reemplazo de autorecompensas, Diagnosis P4, descansos, priorización de RPGenie, fórmula de urgencia, alcance del Diario). También conserva la sección de MVP y fases y menciona el Vault y `NpcMission` en Arquitectura.
- `Casos_de_Uso.md` tiene referencias cruzadas rotas: UC-08 apunta a UC-12 (debe ser UC-10) y a UC-17 (debe ser UC-15); UC-09 apunta a UC-13 (debe ser UC-11).
- RF-048 conviene reescribirlo como "elegir qué ítems del catálogo aparecen en su Tienda".
- El documento explicativo del esquema hecho en otro chat describe la **v1** (31 tablas). La v2 tiene **33 tablas, 18 enums y 2 vistas**.
