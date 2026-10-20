# Plan de cambios del esquema

> **Qué es:** la comparación entre la idea del proyecto (`docs/ideas-proyecto-productividad-gamificada.md`, cierre de octubre de 2026) y la base de datos **desplegada en Supabase**. Dice qué sobra, qué falta, qué es inseguro y en qué orden cambiarlo. **Aquí no hay SQL**: cada paso se convierte después en una migración (`supabase/migrations/00N_*.sql`) con sus pruebas en `supabase/tests`.
>
> **Fecha:** 2026-10-18.

## 1. Punto de partida

La fuente es la exportación del panel de Supabase del 2026-10-18 (tablas, enums y políticas RLS), junto con `supabase/migrations/001_home.sql` y `002_profile.sql`.

- **31 tablas y 16 enums.** Es la **v1** con las migraciones 001 y 002 ya aplicadas (`habits.current_streak` y `best_streak`, `is_weakened` generada, solo lectura en `character_stats`, `quest_log_entries` y `habit_records`).
- **No hay v2 desplegada.** Faltan `user_market_selection`, `notification_category_state`, `v_daily_highlight` y `v_user_store`, que `CLAUDE.md` atribuye a la v2.
- `supabase/schema.sql` y `schema_deployed.sql` coinciden con lo desplegado, pero no traen enums ni RLS. Conviene sustituirlos por esta exportación.

**Veredicto:** el núcleo de la idea está bien modelado: personaje, skills = Áreas, Brain Dump, Metas = jefes, Proyectos, Tareas, Hábitos con racha, Mazmorra, Bitácora y Game Master. Fallan tres cosas:
1. **Seguridad de la economía:** el cliente todavía puede escribir recompensas y compras en ocho tablas (§3).
2. **Lo que sobra** de decisiones ya descartadas (§4).
3. **Lo que falta** del cierre del diseño: economía estable, catálogo nuevo, consumibles, títulos, archivo y rachas con 48 h (§5).

## 2. Lo que ya está bien

| Idea | Dónde vive |
|---|---|
| Personaje: nivel, XP, Monedas, vida e identidad | `profiles` (`identity_statement`) y `character_stats` (solo lectura para el cliente) |
| Debilitado derivado, no escrito a mano | `character_stats.is_weakened`, columna generada (vida ≤ 20 %) |
| Vision Board | `vision_boards` |
| Skill = Área (máx. 6, sin tope de nivel) | `skills` + `enforce_skill_limit`; el cliente solo escribe `name` |
| Brain Dump y G.T.D., pregunta 1 | `brain_dump_entries`, con `brain_dump_status` = `pending · reference · someday · converted` |
| Meta S.M.A.R.T. = jefe | `goals` (`smart_*`, `boss_max_hp`, `boss_current_hp`) |
| Estado único de objetivos | `objective_status` = `not_started · in_progress · completed · expired` |
| Única escala de urgencia | `urgency_level` = `low · medium · high` |
| Proyecto con Meta opcional | `projects.goal_id` |
| Tarea con Proyecto o Meta, subtareas, NPC y origen | `tasks` (`project_id`, `goal_id`, `parent_task_id`, `npc_id`, `source`) |
| G.T.D., pregunta 4 (versión RF-011) | `task_status.delegated` + `tasks.delegated_to` |
| Evento con contacto | `calendar_events.contact` |
| Hábitos buenos/malos, días concretos y rachas | `habits` (`habit_type`, `habit_frequency`, `specific_days`, rachas) |
| Registrar hábito sin trampa | `habit_records` solo lectura + RPC `complete_habit` |
| Deep Working → Mazmorras | `focus_sessions` (`session_status` con `paused`), `focus_session_tasks` y `dungeon_runs` |
| Bitácora (el Diario) | `quest_log_entries` (solo lectura para el cliente) |
| Descansos configurables | `game_master_settings` |
| Tres niveles de aviso | `notification_type` = `critical · motivational · informational` |
| Catálogos globales de solo lectura | `achievements`, `inventory_items`, `black_market_items` y `difficulty_levels` |

## 3. Seguridad de la economía (lo más urgente)

`CLAUDE.md` §8: *el cliente nunca escribe recompensas ni penalizaciones.* Hoy estas políticas lo permiten:

| Tabla | Política actual | Qué puede hacer un usuario | Debe quedar |
|---|---|---|---|
| `tasks` | `own rows` ALL | Crear o editar una tarea con `xp_reward` y `coin_reward` altos | El cliente no escribe `xp_reward`, `coin_reward`, `status = completed` ni `completed_at`; los fija una RPC |
| `habits` | `own rows` ALL; la 001 limita `UPDATE` por columnas, pero deja `xp_reward` y `coin_reward` | Crear o editar un hábito con la recompensa que quiera | Recompensas fijadas por el servidor (2–4 Monedas en el bueno; gravedad −3/−5/−8 en el malo) |
| `dungeon_runs` | `own rows` ALL | Escribir `xp_awarded` y `coin_awarded` | Solo lectura + RPC para cerrar un ciclo |
| `purchases` | `own rows` ALL | Registrar compras sin pagar, o borrarlas | Solo lectura + RPC `purchase` |
| `hp_recovery_purchases` | `own rows` ALL | Igual que `purchases` | Solo lectura + RPC (o se elimina, §5.2) |
| `black_market_redemptions` | `own rows` ALL | Saltarse el cooldown borrando filas | Solo lectura + RPC |
| `recovery_passes` | `own rows` ALL | Darse pases o borrar su cooldown | Solo lectura + RPC |
| `user_achievements` | `own rows` ALL | Desbloquearse logros | Solo lectura; los da el servidor |
| `user_inventory` | `own rows` ALL | Darse objetos | Solo lectura; los da una compra o un logro |
| `market_items` | INSERT, UPDATE y DELETE propios | Crearse artículos (autorecompensas, ya eliminadas) | Solo lectura global, sin `user_id` |

Otros puntos:
- `goals.boss_current_hp` se puede editar desde el cliente (`goals` ALL). El daño al jefe debe aplicarlo la RPC de completar.
- `npcs.last_mission_at` se puede editar desde el cliente, y es el cooldown de «Pedir misión al momento» (gratis cada 3 h). Debe escribirlo el servidor.
- `game_master_settings.skill_limit` se puede editar desde el cliente (ALL), y es el límite de 6 skills (premium en el futuro). Debe ser de solo lectura para el cliente.

## 4. Lo que sobra

| Qué | Por qué sobra | Qué hacer |
|---|---|---|
| `hero_journal_entries` (y su política) | Se eliminó el Diario del Héroe; el Diario es solo la Bitácora. | Borrar la tabla. |
| `tasks.estimated_minutes`, `tasks.difficulty` y el enum `difficulty_scale` | Las tareas ya no tienen tiempo estimado ni dificultad: la XP sale de reglas. | Borrar las columnas y el enum (nada más usa `difficulty_scale`). |
| `market_items.user_id` y sus 3 políticas de escritura | Se eliminaron las autorecompensas; el catálogo es global y cerrado. | Borrar la columna y las políticas; dejar solo `SELECT`. |
| Enum `market_category` (`descanso · indulgencia · experiencia`) | El catálogo nuevo es Hotel, Mercado, Mercado negro y Refugio. | Cambiar los valores (§5.2). |
| `tasks.category` (texto libre) | La categoría es la skill/Área (`skill_id`). | ⚠️ Por confirmar; si nada lo usa, borrarla. |
| `difficulty_levels.coin_multiplier` | Las Monedas son iguales en las tres dificultades. | Dejarla en 1 en la semilla, o borrarla. ⚠️ Por confirmar. `complete_habit` la usa hoy. |

## 5. Lo que falta o no encaja

### 5.1 Recompensas de tareas
- **XP por reglas (10–40) y Monedas = 30 %.** Hace falta una RPC `create_task` que la calcule al crear la tarea (o un trigger que ignore lo que mande el cliente).
- **Falta una RPC `complete_task`.** Debe validar al dueño, aplicar el anti-trampa (menos de 2 min desde `created_at` da el mínimo y 0 Monedas; máximo 15 tareas con Monedas al día), dañar al jefe si la tarea va a una Meta y escribir la Bitácora.
- **`quest_source`** = `task · project · habit · npc · goal`. Falta `dungeon`: el Diario filtra por Mazmorras y el ciclo de Mazmorra da Monedas. ⚠️ Por confirmar si también hacen falta `purchase`, `achievement` o `chest`.
- **XP por Área.** `quest_log_entries` no guarda la skill. Falta `skill_id` para las estadísticas por Área.

### 5.2 Economía estable y catálogo
- **Tope suave diario** (50 completas + 50 a la mitad, máx. 75). Se deriva de `quest_log_entries.coin_awarded` del día; lo aplica una función común a todas las RPC que pagan.
- **Bolsa con límite** (400 + 25 por nivel, máx. 1.000). Se deriva del nivel; la misma función recorta el sobrante.
- **Tesoro del reino:** no existe. Falta un contador que no se gasta (por ejemplo `character_stats.treasury`).
- **Refugio** (Huerto, Biblioteca de RPGenie, Estandarte; 4 niveles; precio 120 × 1,35ⁿ): no existe. Falta el nivel de cada mejora por usuario.
- **`market_category`** con valores nuevos, por ejemplo `hotel · mercado`. El Mercado negro ya tiene su tabla y el Refugio va aparte.
- **Semillas:** `market_items` con Siesta 30, Posada 70, Banquete 150, Elixir 40 y Cofre 60. `black_market_items` con Recuperar racha 150 y Pase 90. Las tres tablas están hoy sin semilla.
- **Límites que no caben:** `black_market_items` solo tiene `cooldown_hours` y `max_uses_per_user`. No expresa «1 al mes», «se repone el día 1» ni «máx. 2 Pases guardados». Para el Elixir (1 activo) y el Cofre (1 al día) tampoco hay sitio.
- **`hp_recovery_purchases`** duplica al Hotel si este se compra como `market_items`. ⚠️ Por confirmar: unificar o mantener.

### 5.3 Consumibles, inventario, logros y títulos
- **`user_inventory`** tiene clave `(user_id, item_id)`: un objeto una sola vez. No hay cantidad ni estado (guardado / activo / usado).
- **Elixir de enfoque** (×1,5 XP en la próxima Mazmorra): falta enlazarlo con la sesión donde se usa.
- **Títulos de prestigio** (por logros, nivel o Tesoro; se muestran bajo el nombre): no existen. Faltan el catálogo, los títulos ganados y el título elegido en `profiles`.
- **Logros con progreso y recompensa (50–200):** `achievements` no tiene recompensa ni meta de progreso.

### 5.4 Vida (HP) y debilitado
- **Umbral:** `is_weakened` usa vida ≤ 20 % (RF-034). La idea propone menos de 30 de vida y −25 % de XP. ⚠️ Por confirmar (propuesta abierta).
- **Gravedad del mal hábito** (−3 / −5 / −8): cabe en `habits.hp_penalty` con un `check` de esos tres valores.
- **Falta `habit_records.hp_change`.** Además, falta permitir varios registros al día en los hábitos malos (uno por evento) y uno solo en los buenos. ⚠️ Por confirmar: la exportación no muestra si hay un `unique (habit_id, completed_on)`.
- **Día sin jugar −5 y +4 por día con un hábito bueno** (+1 por nivel del Huerto): falta el job diario y una forma de saber el último día activo.
- **Falta la RPC para registrar un mal hábito.** Hoy `complete_habit` cubre el bueno.

### 5.5 Rachas y Pase de Recuperación
- **48 h para salvar una racha rota** (propuesta): falta guardar cuándo se rompió y el valor que tenía.
- **`recovery_passes`** solo guarda `used_at` y `cooldown_until`. No dice qué hábito ni qué día protege, ni cuántos pases tiene guardados el usuario (máx. 2).
- **Falta el job diario de rachas** (`break_missed_streaks`). ⚠️ Por confirmar: `pg_cron` o Edge Function.

### 5.6 Brain Dump, Taverna, Mazmorra y Metas
- **`entity_type`** = `task · project · goal`. Si la pregunta 4 del G.T.D. pasa a ser «Evento con contacto» (propuesta), falta `event`. Lo mismo si Quick Add convierte en evento o recurso.
- **Máximo 3 NPCs** (+1 por nivel del Estandarte): falta un trigger como `enforce_skill_limit`.
- **Máximo 5 tareas por sesión** y bloque en pasos de 30 min: falta el `check` o el trigger.
- **Archivo** de P.A.R.A. y «archivar» la Meta cuando el jefe escapa: no hay forma de archivar. ⚠️ Por confirmar: valor nuevo en `objective_status` o columna `archived_at`.
- **Recursos:** `resources.file_url` es obligatorio. ⚠️ Por confirmar si un recurso puede ser una nota o un enlace sin archivo.
- **Vínculo con el Vision Board** (`linked_to_vision` en Metas y Proyectos): no está.

### 5.7 Notificaciones y vistas
- **Anti-estrés:** faltan `event_key` (único por usuario), `category` y `digest_slot` en `notifications`, y la tabla `notification_category_state`.
- **Vistas:** faltan `v_daily_highlight` y `v_user_store` (con `user_market_selection`).

### 5.8 Apariencia
- **Modo claro/oscuro/automático:** hoy se guarda en el dispositivo (`AppearanceBloc` + `shared_preferences`). ⚠️ Por confirmar: dejarlo local o pasarlo a `game_master_settings` para que viaje entre dispositivos.

## 6. Migraciones escritas (2026-10-18)

Las 10 etapas del plan quedaron en 5 archivos. Se aplican **en este orden** en Supabase → SQL Editor, cada uno una sola vez (se pueden repetir sin romper nada). Las pruebas están en `supabase/tests/003_007.test.mjs` y corren sobre el esquema desplegado completo (`tests/deployed_v1.sql` + 001 + 002): `cd supabase/tests && npm install && npm test`.

| Archivo | Etapas del plan | Qué hace |
|---|---|---|
| `003_security.sql` | 1 | Solo lectura en compras, canjes, pases, logros, inventario y Mazmorra; catálogo de solo lectura; el cliente no escribe recompensas, vida del jefe, cooldown de NPC ni `skill_limit`; completar o vencer solo lo hace el servidor. |
| `004_structure.sql` | 2, 4 (estructura), 7, 8 | Borra lo descartado; catálogo `hotel · mercado` con semilla; Mercado negro con semilla; `game_rules`; dificultad del diseño; Tesoro, último día activo y debilitado < 30; `skill_id` y fuentes nuevas en la Bitácora; rachas rotas y días recuperados; pases guardados; Refugio, consumibles y títulos; archivo y `linked_to_vision`. |
| `005_rewards.sql` | 3, 4 (economía) | `_award` (dificultad, −25 % XP debilitado, tope 75/día, bolsa y Tesoro, curva 100 × n^1,5, skill y Bitácora); XP de tareas por reglas; `complete_task`, `complete_project`, daño y victoria del jefe; `complete_habit` con recompensa del servidor; `register_bad_habit`; `claim_daily_chest`. |
| `006_store.sql` | 4 (tienda), 5, 6, 9 | `purchase` (Hotel, Elixir, Cofre); `buy_black_market` y `use_recovery_pass` con ventana de 48 h; `upgrade_refuge`; límite de NPC y `request_npc_mission`; Mazmorra (bloques de 30, máx. 5 tareas, `activate_elixir`, `complete_dungeon_cycle`). |
| `007_daily.sql` | 5 (job), 8 (vistas), 10 | `daily_maintenance` con pg_cron (plazos −5, rachas rotas, +4 / −5 de vida diaria); notificaciones (`event_key`, categoría, digest, frecuencia decreciente); `v_daily_highlight`, `user_market_selection` y `v_user_store`. |

**Antes de subirlas:**
1. Activa **pg_cron** en Supabase → Database → Extensions (si no, 007 crea todo menos la programación y lo avisa).
2. `004` se detiene si `hero_journal_entries` o `hp_recovery_purchases` tienen filas: respáldalas y vacíalas primero.
3. Las filas de `market_items` creadas por usuarios quedan inactivas (su historial de compras se conserva).
4. Las tareas abiertas recalculan su recompensa con las reglas (las anteriores las pudo fijar el cliente).

**La app actual no se rompe:** solo usa `profiles`, `skills`, `home_dashboard`, `profile_overview` y `complete_habit`, que conservan su forma.

## 7. Decisiones

**Cerradas el 2026-10-18:**
- Debilitado: menos de 30 de vida, −25 % de XP y Monedas iguales (cambia RF-034).
- Rachas: 48 h para salvarlas con un Pase o «Recuperar racha».
- Dificultad: XP ×1,2 / ×1 / ×0,85; vida ×0,75 / ×1 / ×1,25; Monedas ×1.
- Archivo: columna `archived_at`.
- Hotel: dentro de `market_items`; `hp_recovery_purchases` se borra.
- `tasks.category`: se borra.
- G.T.D., pregunta 4: sigue como tarea `delegated` (RF-011).
- Job diario: pg_cron.

**Valores provisionales** (marcados `provisional = true` en `game_rules`, se ajustan sin migración): XP de hábito bueno (10 → 3 Monedas), XP del ciclo de Mazmorra (10 → 3 Monedas), XP de proyecto (120 → 36 Monedas), daño al jefe por proyecto (30), valores de vida diaria y de plazo, 48 h.

**Siguen abiertas:**
1. **Apariencia:** se dejó en el dispositivo (sin cambios en la BD).
2. **Recompensa de misión de NPC** (5–24 Monedas en el diseño): hoy usa la regla de tareas (3–12).
3. **Precio del Refugio:** n = nivel actual de cada mejora.
4. **Completar un proyecto:** se exige ≥ 1 tarea hecha y ninguna abierta.
5. **Pendiente de catálogo:** qué títulos existen, qué sale del Cofre misterioso y qué logros hay (las tablas ya están).
6. **RF-031:** penalización de vida al cerrar una sesión con tareas sin completar (no implementada).
7. **«Hoy»** es el día UTC del servidor para el tope diario, las 15 tareas y el cofre.
8. Los ajustes diarios de vida no se escriben en la Bitácora.

Según `CLAUDE.md` §2, hay que actualizar los RF y UC afectados (RF-022, RF-030, RF-034, RF-043, RF-048, RF-112, RF-116) y `Esquema_Base_de_Datos.md` en el Project de claude.ai.
