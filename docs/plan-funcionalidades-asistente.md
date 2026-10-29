# Plan de funcionalidades — De lista de texto a asistente que acompaña

> Propuesta del 2026-10-29 (v2). Todavía no cambia RF, UC ni `schema.sql`: cada bloque dice qué
> necesita y qué toca. Una funcionalidad por vez y con aprobación (CLAUDE.md §8).
>
> **v2:** se añaden las **tareas guiadas que enseñan** (§6) y la **identidad comercial sin
> fantasía** (§3). El documento ya usa los nombres nuevos; la tabla de §3 da la equivalencia con
> los antiguos y con el código.
>
> **v3 (2026-10-29), decisiones cerradas:** se mantiene la gamificación (XP, niveles, Monedas,
> rachas); se aprueban los nombres de la columna «Ahora» de §3.1; la XP de una tarea guiada **se
> reparte entre sus pasos** (§6.1). El nombre de la app sigue abierto.

---

## 1. Diagnóstico: por qué hoy se siente «solo texto»

| Síntoma | Causa en el código |
|---|---|
| Completo una tarea y solo veo un mensaje abajo | Toda recompensa termina en `showLifeQuestMessage` (SnackBar). `_award` (005) ya devuelve `xp`, `coins`, `level`, `level_up`, pero **ninguna pantalla lee `level_up`**. |
| Las tareas de la IA son un bloque de texto | Gemini devuelve JSON con `objective`, `steps`, `hints` y `search` (`npc-mission`), pero `formatGuide` lo **aplana en `tasks.description`** (031). Los pasos no se marcan, las pistas se ven todas de golpe y no queda rastro de cómo avancé. |
| El progreso hay que imaginarlo | No hay barras que se llenen, ni subida de nivel, ni avance visible de la meta, ni animación de la racha. El área sube de nivel en silencio. |
| El Asistente no asiste, solo elige | `current_mission` (022) es un `ORDER BY`: devuelve una tarea y un `reason`. No pregunta nada, no planifica, no ayuda a empezar ni a replantear. |
| La app espera a que yo haga todo | No hay ritual de inicio ni de cierre del día, ni revisión semanal. Los avisos no traen botón de acción. |
| El tono es de juego de fantasía | Taverna, NPC, Mazmorra, jefe, Elixir, Cofre, Hotel, «reino»… (≈ 500 apariciones en `lib/` y ≈ 200 en `supabase/`). |
| Hay más mecánicas que funciones útiles | La tienda tiene 6 mecánicas (Hotel, Mercado, Mercado negro, Refugio, Tesoro, Elixir y Cofre), y crear algo tiene 4 entradas distintas. No hay tareas que se repitan (`tasks.repeat_rule` existe, pero nadie lo usa) ni recordatorios con hora. |

**Idea central:** que cada acción real tenga **(1) una respuesta visible inmediata**, **(2) un
siguiente paso propuesto** y **(3) un lugar donde se acumule y se vea crecer**. En las tareas
guiadas eso se cumple **paso a paso**, no solo al final.

---

## 2. Reglas que respeta todo el plan

- **Anti-trampa (CLAUDE.md §8):** la IA y la animación solo *muestran* y *sugieren*. XP, Monedas y
  Constancia siguen saliendo de las RPC `SECURITY DEFINER`, y las animaciones leen la respuesta del servidor.
  La IA **nunca decide recompensas**, ni por la cantidad de pasos ni por las respuestas.
- **Ético (CLAUDE.md §9):** nada existe solo para que se abra más la app. Sin presión con cuentas regresivas
  y sin premios aleatorios con valor económico.
- **Tono (§7):** invitación y nunca culpa. Lo vencido se **replantea**.
- **IA (PLAN-REDISENO §13):** Gemini capa gratis, una llamada por acción del usuario, sin datos
  personales, siempre con confirmación y con un **camino por reglas si la IA falla**.
- **Accesibilidad:** toda animación respeta `context.motion()`. El color nunca va solo y la
  vibración es opcional.
- **Arquitectura:** lo compartido (momento de recompensa, vista de pasos, conversación del Asistente)
  va en `core/`. La composición entre features va en `app/`.

---

## 3. Nueva identidad: comercial, sin fantasía

**Decisión del usuario (2026-10-29):** se quita todo el vocabulario de fantasía y se reemplaza por
nombres actuales y sobrios. **Se quita la fantasía, no la gamificación:** XP, niveles, rachas,
Monedas y recompensas siguen existiendo, con el lenguaje común de apps como Duolingo o Strava
*(confirmado el 2026-10-29)*.

### 3.1 Vocabulario (aprobado el 2026-10-29: columna «Ahora»)

| Antes (UI) | Ahora | Alternativa (descartada) | En el código (no cambia) |
|---|---|---|---|
| LifeQuest / Questly | **Decisión abierta** (ver §11) | — | `proyecto_movil` |
| Personaje · Perfil del personaje | Perfil | — | `profiles`, `character_stats` |
| «¿Quién eres en este reino?» | «¿En quién te quieres convertir?» | «Tu propósito» | `identity_statement` |
| Skill | Área | — | `skills` |
| Misión | Tarea | — | `tasks` |
| Misión actual | **Siguiente paso** | Foco ahora | `current_mission` |
| RPGenie | **Asistente** | nombre propio a decidir | — |
| Taverna | **Mentores** | Tutores | `npcs`, feature `tavern` |
| NPC | Mentor | Tutor | `npcs` |
| Misión de NPC | **Tarea guiada** | Reto | `tasks.source = 'npc'` |
| Noble misión del NPC | Propósito del mentor | Objetivo | `npcs.noble_mission` |
| Mazmorra · Deep Working | **Modo Foco** | Sesión de foco | `focus_sessions`, feature `dungeon` |
| Ciclo de mazmorra | Bloque de foco | Pomodoro | `dungeon_runs` |
| Mochila de misiones | Tareas de la sesión | — | `focus_session_tasks` |
| Boss · Boss Fight | Meta · Avance de la meta | — | `goals`, feature `goals` |
| Vida del jefe (baja) | **Avance de la meta (sube de 0 a 100 %)** | — | `100 − boss_current_hp` (solo en la UI) |
| Ataque / daño al jefe | Aporte a la meta («+12 %») | — | igual |
| Victoria · «El jefe escapó» | Meta cumplida · «La fecha pasó. ¿La replanteamos?» | — | `objective_status` |
| HP · Vida · Vitalidad | **Constancia** | Bienestar | `hp`, `hp_max` |
| Debilitado | Constancia baja | — | `is_weakened` |
| Hotel | Recuperar constancia | — | `hp_recovery_purchases` |
| Diario · Bitácora · Historial de misiones | **Actividad** | Historial | `quest_log_entries`, feature `journal` |
| Stage · P.A.R.A. | **Planificador** | Organizar | feature `stage` |
| Brain Dump | **Bandeja de ideas** | Captura | `brain_dump_entries` |
| Vision Board | Visión | — | `vision_boards` |
| Marketplace · Tienda | **Recompensas** | — | `market_items` |
| Mercado negro | **Se quita** (sus 2 artículos pasan a Protector de racha, S3) | — | `black_market_items` |
| Refugio (Huerto, Estandarte…) | Mejoras (Bienestar, Más mentores…) | — | Refugio (006) |
| Tesoro del reino | **Se quita** (S3) | — | `character_stats.treasury` |
| Elixir · Cofre misterioso | **Se quitan** (S3) | — | `activate_elixir`, `user_consumables` |
| Cofre del día | Recompensa diaria | — | `claim_daily_chest` |
| Pase de Recuperación · Recuperar racha | Protector de racha · Reparar racha | — | `recovery_passes` |
| Inventario y logros | Logros | — | feature `inventory` |
| Títulos de prestigio | Insignias | — | títulos (009) |
| Game Master | Ajustes | — | `game_master_settings` |
| Explora el reino | Más herramientas | — | — |
| Temas del reino | Temas de color | — | `ThemeRealm` |
| Dificultad Fácil / Normal / Difícil | Ritmo: Relajado / Equilibrado / Intenso | dejar Fácil / Normal / Difícil | `difficulty_level` |
| Rangos por nivel | Inicial · En marcha · Constante · Avanzado · Experto | — | `game_rules` |
| XP · Monedas · Nivel · Racha | **Se mantienen** | — | igual |

### 3.2 Alcance del cambio

| Qué | Dónde | Cómo |
|---|---|---|
| Textos de la UI y mensajes de error | `lib/**` (pantallas, widgets y repositorios con mensajes en español) | Reemplazo guiado por la tabla, pantalla por pantalla |
| Textos que genera la base | Avisos (`029`, `036`), nombres sembrados en `market_items`, `black_market_items`, títulos y mejoras | Migración `037_commercial_copy.sql` que actualiza nombres y mensajes, con prueba SQL |
| Tono de la IA | Prompts de `npc-mission` y `npc-context` («jugador», «misión», «noble misión») | Tono profesional de mentor; pruebas de `index.test.ts` |
| Iconos | `QIcons` (espada, cofre, poción, castillo, escudo…) | Cambiar por iconos neutros (rayo, regalo, objetivo, calendario) |
| Documentación | `CLAUDE.md` §4 (glosario con la columna «Nombre en la UI»), §5–§7 y §13; `docs/diseño/*`; `docs/ideas-…md` | Al confirmar la tabla |

**No cambia:** tablas, columnas, enums y RPC (`npcs`, `dungeon_runs`, `boss_current_hp`…).
Renombrarlos exige migraciones, cambios de RLS y pruebas, y el usuario no lo vería. Las carpetas de
features y las rutas (`tavern`, `/tavern`) se pueden renombrar después en una refactorización
mecánica aparte (ver §11).

**Cuándo:** **junto con el rediseño visual en curso** (PLAN-REDISENO), para tocar cada pantalla una
sola vez. Es el paso 0 de §10.

---

## 4. Mapa del plan

```
Paso 0 · Identidad comercial     → vocabulario, textos de la base, prompts e iconos (§3)
Fase S · Simplificar             → S1 Un solo «Agregar» · S2 Inicio = Hoy · S3 Recompensas simples
                                   S5 Funciones que aparecen al necesitarlas
Fase R · Rutas listas            → R1 Plantillas que crean meta, proyecto, tareas guiadas y hábito
Fase U · Uso diario              → U1 Tareas que se repiten · U2 Recordatorio con hora
Fase A · Sentir el progreso      → A1 Momento de recompensa · A2 Subida de nivel · A3 Barras vivas
                                   A4 Aporte a la meta · A5 Racha viva
Fase B · Tareas guiadas          → B1 Guía con pasos reales · B2 Paso a paso · B3 «Me atasqué»
         que enseñan               B4 Comprobar y reflexionar · B5 Ruta del mentor
                                   B6 Cómo avanzó la tarea · B7 «Guíame» en cualquier tarea
Fase C · Un asistente que habla  → C1 Check-in de tiempo y ánimo · C2 Plan del día · C3 Cierre del día
                                   C4 Replantear lo vencido · C5 Revisión semanal
Fase D · Actuar sin fricción     → D1 Avisos con acción · D2 Widget de inicio · D3 Captura por voz
                                   D4 Modo Foco en la notificación
Fase E · Ver el camino recorrido → E1 Logros con progreso · E2 Áreas en detalle · E3 Estadísticas
                                   de mes · E4 Calendario
Fase F · IA que entiende texto   → F1 Entender lo que escribes (mejora S1) · F2 Ordenar la Bandeja
                                   F3 Dividir proyecto · F4 Revisar S.M.A.R.T. · F5 Consejos
Pendientes (sin fecha)           → S4 Visión y Metas juntas · R2 Tu primera semana · R3 Repaso de 5 min
                                   R4 Resumen de lo aprendido · R5 «¿Por qué?» la primera vez
                                   U3 Deshacer al completar · U4 Hábitos que se registran solos
                                   U5 Búsqueda global
```

---

## 5. Fase A — Sentir el progreso (sin SQL o casi)

### A1 · Momento de recompensa
- **Qué ve el usuario:** al completar una tarea, un hábito o un bloque de foco aparece una tarjeta
  breve con «+25 XP · +8 Monedas», la XP sube a la barra de nivel y el área muestra su propio «+25».
  Con constancia baja se ve «−25 % por constancia baja · cómo recuperarla». Se cierra sola en unos 2 s
  o con un toque.
- **Necesita:** que los datasources de `missions`, `habits`, `dungeon`, `goals`, `home` y `tavern`
  devuelvan el `jsonb` de `_award` en lugar de descartarlo; la entidad `RewardOutcome` en
  `core/entities` y `showRewardMoment()` en `core/widgets/questly/`. Sin migración, salvo las RPC que
  no devuelvan el resultado de `_award`.

### A2 · Subida de nivel (perfil y área)
- Pantalla «¡Nivel 7!» con lo que cambia: XP para el siguiente, rango («En marcha → Constante») y lo
  que se desbloquea (por ejemplo, un mentor más). Para un área: «Programación sube a nivel 4».
- **Necesita:** leer `level_up` (ya existe) y que `_award` devuelva `skill_level_up` y `skill_level`
  (migración pequeña). Los rangos van en `game_rules`.

### A3 · Barras vivas
- XP, Constancia y áreas se **animan** desde el último valor visto. La hoja «¿Cómo funciona?» explica
  XP y Constancia. Solo UI.

### A4 · Aporte a la meta
- Al completar algo vinculado a una Meta: «+12 % a *Aprobar Cálculo*» y la barra de avance sube.
  Al llegar a 100 %, pantalla «Meta cumplida» (+300 XP, insignia). Si vence la fecha: «La fecha pasó.
  ¿La replanteamos?», con **Nueva fecha** o **Archivar**.
- **Necesita:** que `complete_task` / `complete_project` devuelvan `boss_damage` y `boss_hp`. La UI
  muestra `100 − vida` como avance.

### A5 · Racha viva
- «Día 13 · tu récord es 21». En los días 7, 30 y 100 aparece un hito una sola vez.
- **Necesita:** que `complete_habit` devuelva `current_streak` y `best_streak` (verificar en 011).

**Aceptación de la fase A:** ninguna acción que dé o quite XP, Monedas o Constancia termina solo en un SnackBar.

---

## 6. Fase B — Tareas guiadas que enseñan

**Problema:** una guía en texto («1. Lee… 2. Resuelve…») no motiva ni deja huella. Hay que
**hacerla**, ver cómo avanza y saber si se aprendió. La tarea pasa de *texto para leer* a
*recorrido que se completa*.

### B1 · Guía con pasos reales
- **Qué ve el usuario:** la tarea guiada abre con su **objetivo** («Al terminar sabrás resolver
  sistemas 2×2 por sustitución») y una lista de **pasos que se marcan**, cada uno con su «¿Para qué?»
  y un tiempo orientativo («≈ 10 min»). Arriba se ve «Paso 2 de 4» y una barra de avance.
- **Necesita:**
  - Que `npc-mission` deje de aplanar la guía y devuelva el JSON. El esquema de Gemini suma `why` y
    `minutes` por paso, `topic` (tema del temario) y `check` (preguntas de B4).
  - Una columna `tasks.guide jsonb` (`objective`, `topic`, `search[]`, `check[]`) y una tabla `task_steps`
    (`task_id` con *on delete cascade*, `user_id`, `position`, `title`, `why`, `minutes`, `hint`,
    `hint_revealed_at`, `done_at`, `paid_at`) con RLS `auth.uid() = user_id`.
  - Las RPC `toggle_task_step(step_id)` y `reveal_step_hint(step_id)`. `accept_npc_mission` recibe
    los pasos y los inserta.
  - **La XP de la tarea se reparte entre sus pasos** (detalle en §6.1). Cada paso muestra lo que
    paga («+8 XP») y A1 lo celebra en pequeño.
  - Las tareas guiadas viejas conservan su `description` como texto (sin migrar datos).

### 6.1 · Reparto de la XP entre los pasos (diseño de la economía)

**Regla:** el total de la tarea no cambia. Sigue siendo 10–40 XP por reglas (§13) y Monedas = 30 %.
Los pasos solo reparten ese total en partes, así que **la IA no puede inflar la economía**: diez
pasos pagan lo mismo que dos.

**Cómo se calcula** (en el servidor, dentro de `toggle_task_step` y `complete_task`):

```
pendiente_xp    = tasks.xp_reward  − xp ya pagada por sus pasos
pasos_sin_pagar = pasos de la tarea con paid_at null
pago_del_paso   = floor(pendiente_xp / pasos_sin_pagar)   -- el último paso se lleva el resto
```

- Se calcula **al momento de pagar** y no al crear la tarea. Si un paso se divide en dos (B3,
  «Me atasqué»), el total sigue igual: el reparto se ajusta solo.
- **Se paga una sola vez por paso:** la columna `task_steps.paid_at` se llena al pagar y no se borra
  nunca. Desmarcar y volver a marcar un paso cambia `done_at`, pero no vuelve a pagar.
- **Completar la tarea paga lo que falte** (`pendiente_xp`). Si el usuario la completa sin marcar los
  pasos, cobra lo mismo de una vez, así que nadie pierde ni gana por usar los pasos.
- Cada pago pasa por `_award` (multiplicador de dificultad, −25 % con constancia baja y tope diario
  de Monedas) y deja **una fila en `quest_log_entries`** por paso (`source = 'task_step'`). La
  Actividad las agrupa bajo su tarea para que no se llene de filas sueltas.
- Las Monedas siguen la misma fórmula sobre `tasks.coin_reward`.
- **No se crean ni borran pasos de una tarea completada**, y un paso pagado no se puede borrar. Así
  se cierra la trampa de borrar pasos para reordenar el reparto.
- Las tareas sin pasos funcionan igual que hoy.

**Ejemplo:** una tarea de 30 XP con 4 pasos paga 7 · 7 · 8 · 8 (cada pago divide lo pendiente entre
los pasos que quedan: 30/4 → 7, 23/3 → 7, 16/2 → 8, último → 8). Si el paso 3 se divide en dos, quedan
16 XP entre 3 pasos: 5 · 5 · 6.

**Pruebas SQL obligatorias:** el total pagado es igual a `xp_reward` con y sin pasos; marcar,
desmarcar y volver a marcar paga una sola vez; dividir un paso no cambia el total; completar sin
pasos paga todo; no se puede tocar un paso de otro usuario (RLS); el tope diario aplica a cada paso.

### B2 · Modo paso a paso
- **Qué ve el usuario:** un botón «Empezar» abre la tarea **un paso a la vez**, a pantalla completa:
  instrucción, ejercicio con sus datos y botones **«Listo, siguiente»**, **«Necesito una pista»** y
  **«Me atasqué»**. Las pistas se revelan de a una (concepto → cómo empezar → error común). Desde ahí
  también se puede **«Hacerlo en Modo Foco»**, y la tarea entra a la sesión con los pasos visibles.
- **Por qué:** se ve un solo paso a la vez, así que la tarea no abruma (punto de entrada claro).
  Las pistas por partes dejan pensar antes de dar la respuesta.
- **Necesita:** solo UI sobre B1. El estado lo guarda el servidor, así que se puede retomar en otro momento.

### B3 · «Me atasqué»
- **Qué ve el usuario:** el usuario elige qué le pasa (no entiendo el concepto / no sé cómo empezar /
  me sale un error) y, si quiere, escribe una frase. El Asistente responde con **otra explicación más
  simple o un ejemplo resuelto parecido** (no el suyo) y ofrece **dividir el paso** en dos más chicos.
- **Necesita:** Edge Function `assistant` con la acción `unstuck` (solo se envían el paso, el tema y
  la frase del usuario). Si la IA falla, se muestran las pistas guardadas y el término de búsqueda.

### B4 · Comprobar y reflexionar
- **Qué ve el usuario:** al marcar el último paso aparecen **2 o 3 preguntas rápidas** de opción
  múltiple, con su explicación al responder. Le sigue «¿Qué te llevas de esta tarea?» (una frase,
  opcional). El resultado se ve como **«Lo dominas» / «Conviene repasar»**, nunca como nota ni como fracaso.
- **Por qué:** recordar lo aprendido lo fija (práctica de recuperación) y da una sensación real de progreso.
- **Necesita:** las preguntas vienen en `guide.check` (generadas con la tarea, sin llamada extra).
  RPC `save_task_reflection(task_id, answers, note)` y las columnas `tasks.self_check jsonb` y
  `tasks.reflection text`. **Las respuestas no cambian la recompensa** (no se puede hacer trampa
  respondiendo al azar ni hace falta responder para cobrar).

### B5 · Ruta del mentor
- **Qué ve el usuario:** cada mentor tiene una **ruta**: los temas de su documento de contexto
  (p. ej. Unidad 1 ✔ · Unidad 2 en curso · Unidad 3…) con el porcentaje del temario cubierto. La
  siguiente tarea guiada **sigue la ruta**, y los temas marcados «Conviene repasar» vuelven como
  **tarea de repaso** unos días después.
- **Necesita:** los documentos de contexto (PLAN-REDISENO §13, prioridad 1), con el resumen de la IA
  en formato estructurado (`resources.ai_summary jsonb` con `units[]`), y la RPC `mentor_path(npc_id)`,
  que **deriva** el estado de cada tema de las tareas con `guide.topic` (sin tabla nueva). `npc-mission`
  recibe en su prompt los temas cubiertos y los que hay que repasar.

### B6 · Cómo avanzó la tarea
- **Qué ve el usuario:** en el detalle de la tarea, una **línea de tiempo**: creada → guía lista →
  paso 1 hecho (lun 18:40) → pista usada en el paso 2 → «Me atasqué» resuelto → completada → «Lo
  dominas» + su reflexión. En Actividad, las tareas guiadas muestran su reflexión.
- **Necesita:** RPC `task_detail(task_id)` que la **deriva** de `created_at`, `task_steps.done_at`,
  `hint_revealed_at`, `completed_at` y `self_check`, sin tabla de eventos.

### B7 · «Guíame» en cualquier tarea
- **Qué ve el usuario:** no solo las de mentor: cualquier tarea propia tiene un botón **«Guíame»** que
  genera la misma guía (objetivo, pasos, pistas y preguntas) a partir del título, la descripción y el
  área. El usuario la revisa y la acepta o la descarta.
- **Necesita:** acción `guide` en la Edge Function `assistant` (reutiliza el formato de B1) y la RPC
  `attach_task_guide(task_id, guide)`. Sin IA, ofrece «Escribe tú el primer paso de 2 minutos» (subtarea manual).

**Aceptación de la fase B:** una tarea guiada se puede completar paso a paso, retomar al otro día,
pedir ayuda dentro de ella y ver al final qué se aprendió y cómo se avanzó.

---

## 7. Fase C — Un asistente que conversa (con reglas, sin IA)

El Asistente pasa de tarjeta a **conversación con botones**, con el mismo patrón que el diagnóstico
G.T.D. de PLAN-REDISENO §12.

- **C1 · Check-in de tiempo y ánimo:** en «Siguiente paso», preguntas como «¿Cuánto tiempo tienes?» (15 min / 30 / 1 h /
  más) y «¿Cómo estás?» (con ganas / normal / cansado). El Asistente propone la tarea que encaja y explica por qué
  («vence mañana y suma 12 % a tu meta»), con una cola de 2 siguientes y los motivos de «Ahora no».
  Con B1, «lo más ligero» se calcula con los minutos de los pasos pendientes.
  → `current_mission(p_skip, p_mood, p_minutes)`. RF-097. **Decisión abierta:** orden de prioridad.
- **C2 · Plan del día:** por la mañana, «¿Armamos tu día?»: 3 tareas propuestas que el usuario
  ajusta. En el Inicio queda «Plan de hoy · 2 de 3». Si se ignora, no vuelve ese día.
  → tabla `daily_plans` + `suggest_daily_plan()` / `save_daily_plan()`.
- **C3 · Cierre del día:** «¿Cómo te fue?»: lo hecho hoy y, por cada pendiente del plan, **Mover a
  mañana · Dividir · Soltar**, sin castigo extra. → `close_daily_plan(moves)`.
- **C4 · Replantear lo vencido:** «Esto se pasó de fecha. ¿Qué hacemos?» → **Nueva fecha · Dividir
  · Archivar · Delegar**. → `reschedule_item(type, id, date)`.
- **C5 · Revisión semanal:** 4 pasos: vaciar la Bandeja, proyectos en 🔴/🟡, avance de las metas y
  elegir **un foco de la semana** que el Asistente prioriza. → `weekly_review_day`, `weekly_focus_id`
  en `game_master_settings`, `weekly_review_overview()`.

---

## 8. Fases D, E y F (resumen)

| # | Funcionalidad | Necesita |
|---|---|---|
| D1 | Avisos con botón (Registrar · Ver siguiente paso · Replantear) | `entity_type` y `entity_id` en `notifications_overview` / `device_notifications`, acciones de `flutter_local_notifications` y deep links |
| D2 | Widget de pantalla de inicio (Android): siguiente paso, hábitos de hoy y XP | `home_widget`. iOS queda fuera por ahora |
| D3 | Captura por voz en la Bandeja | `speech_to_text` + `capture_thought` |
| D4 | Modo Foco en la notificación (pausar, saltar descanso) | Notificación en curso. El cronómetro debe sobrevivir en segundo plano |
| E1 | Logros con progreso, bloqueados y secretos (hoy el catálogo está vacío) | Semilla de `achievements` y `check_achievements()` dentro de `_award` |
| E2 | Detalle de área: XP semanal y tareas, proyectos y metas que la alimentan | `skill_detail(id)` |
| E3 | Estadísticas de 7 / 30 / 90 días | `stats_overview(p_days)` |
| E4 | Calendario con eventos («Asistí, +10 XP») | `calendar_range()` y RPC de `calendar_events` |
| F1 | Entender lo que escribes en S1 cuando las reglas no alcanzan (tipo, área, meta) | Acción `parse_task` en la Edge Function `assistant` |
| F2 | Ordenar la Bandeja con IA | Acción `sort`; se confirma con el G.T.D. |
| F3 | Dividir proyecto en tareas | Acción `split` |
| F4 | Revisar S.M.A.R.T. letra por letra | Acción `smart_review` |
| F5 | Consejos con contexto (por qué esta tarea, 3 observaciones de la semana, cómo avanzar la meta) | Acción `advice`; si la IA falla, los textos por reglas |

**Infraestructura de IA (una vez, antes de B3):** una Edge Function `assistant` con `action`
(`guide`, `unstuck`, `parse_task`, `split`, `sort`, `smart_review`, `advice`), un límite de llamadas por
usuario y día (tabla `ai_usage`), los mismos secrets de Gemini y el aviso de privacidad en la UI.
`npc-mission` puede migrar a ella más adelante.

---

## 9. Simplificar, guiar y servir a diario (fases S, R y U)

Aprobadas el 2026-10-29: S1, S2, S3, S5, R1, U1 y U2. Las demás quedan como pendientes en §4.

### S1 · Un solo «Agregar»
- **Qué ve el usuario:** el botón flotante abre **una sola hoja**: un campo «¿Qué tienes en mente?»
  (con micrófono, D3) y, mientras escribe, una **vista previa**: «Tarea · jueves 17:00 · Estudio».
  Unas fichas permiten cambiar el tipo (Tarea / Proyecto / Meta / Idea / Recurso). Hay dos botones:
  **«Crear»** y **«No estoy seguro»** (abre el diagnóstico G.T.D. de PLAN-REDISENO §12). Con «Guardar
  como idea» va a la Bandeja sin decidir nada.
- **Reemplaza:** `stage/…/quick_add_sheets.dart`, la entrada de `missions/…/create_mission_sheet.dart`
  y la captura de la Bandeja. Los formularios completos siguen existiendo, pero se abren ya rellenos
  desde «Más detalles».
- **Cómo entiende el texto, primero por reglas (sin IA):** un analizador puro en
  `core/quick_add/quick_add_parser.dart` detecta fechas y horas en español («hoy», «mañana», «pasado
  mañana», «el jueves», «el 15», «a las 5», «17:30», «en 2 semanas»), la prioridad («urgente»,
  «importante») y el área si su nombre aparece en el texto. Sin una fecha y con un verbo de acción
  queda como Tarea; frases como «aprender…» o «lograr…» con un plazo de meses quedan como Meta.
  F1 (IA) solo entra si el usuario pide «Entender mejor».
- **Necesita:** sin SQL (usa `create_task`, `create_project`, `create_goal`, `create_resource` y
  `capture_thought`). Una prueba por cada patrón del analizador.
  `shortcut:` frases ambiguas como «el 5» a fin de mes; se mejoran con F1 si hacen falta.

### S2 · Inicio = Hoy
- **Qué ve el usuario:** de arriba abajo:
  1. Una franja con nivel, XP y Constancia.
  2. **Siguiente paso** (una tarjeta, con «Empezar»).
  3. **Hoy**: tareas que vencen hoy, vencidas y de prioridad alta, marcables ahí mismo (cuando exista
     C2, se reemplaza por el Plan de hoy).
  4. **Hábitos de hoy**, marcables con un toque.
  5. La Recompensa diaria.

  «Más herramientas» pasa a una fila al final.
- **Por qué:** al abrir la app se sabe qué hacer y se puede hacer sin navegar.
- **Necesita:** que `home_dashboard` (001) devuelva `today_tasks`, leído de `v_daily_highlight` sin
  duplicar datos, y los hábitos de hoy. Al marcar se usan `complete_task` y `complete_habit` con el
  momento A1.

### S3 · Recompensas simples (quitar mecánicas)

Quedan **3 categorías** en una sola pantalla:

| Categoría | Contenido | Viene de |
|---|---|---|
| **Descanso** | Recuperar constancia: +10 · +25 · completa | Hotel (`market_items` `siesta`, `posada`, `banquete`) |
| **Protector de racha** | Protector (1 al mes, máx. 2 guardados) y Reparar racha (1 al mes, 48 h) | Mercado negro (`black_market_items`); su RPC `buy_black_market` y `use_recovery_pass` siguen igual |
| **Mejoras** | Bienestar, Más mentores… | Refugio (`upgrade_refuge`) |

**Se quitan:**

| Qué | Por qué | Qué pasa con lo que ya tienen los usuarios |
|---|---|---|
| **Mercado negro** (como sección) | Sus 2 artículos pasan a Protector de racha. El catálogo rotativo de 6 meses ya no hace falta | Nada se pierde: mismas tablas y RPC |
| **Elixir** (×1,5 XP en el Modo Foco) | Una regla más de XP que hay que aprender y vigilar | Los Elixires guardados o activos se **devuelven en Monedas** (40 c/u) |
| **Cofre misterioso** (60 Monedas, premio al azar) | Comprar al azar con Monedas se parece a una caja de premios y choca con CLAUDE.md §9 («las recompensas aleatorias nunca son apuestas») | Los Cofres guardados se **devuelven** (60 c/u) |
| **Tesoro + límite de la bolsa** | Hoy, al llenar la bolsa (400 + 25 por nivel, máx. 1.000), las Monedas que sobran van al Tesoro, que no se gasta. Es confuso y se siente como perder lo ganado | Se quita el límite de la bolsa y el **Tesoro existente pasa a Monedas**. La inflación la sigue frenando el tope diario (75) |

**Se mantiene** la Recompensa diaria del Inicio (`claim_daily_chest`): es gratis y de monto fijo.

**Migración `038_simple_rewards.sql`** (con aprobación, en este orden y en una transacción):
1. Devolver Elixires y Cofres guardados: sumar a `coins` y escribir una fila en `quest_log_entries`
   por usuario («Devolución: artículo retirado»). Necesita un valor nuevo en el enum de origen
   (p. ej. `refund`).
2. Pasar `treasury` a `coins` con su fila en `quest_log_entries`.
3. `_award` sin bolsa: `v_wallet := v_coins`, sin `treasury` y sin las reglas `purse_*`.
   `_award` ya no devuelve `treasury`.
4. Desactivar `market_items` `elixir` y `cofre` (no se borran, para no romper las compras históricas
   de `purchases`); `purchase()` los rechaza.
5. Borrar `activate_elixir()` y quitar el factor de Elixir de `complete_dungeon_cycle` y la regla
   `elixir_xp_factor`.
6. `market_overview`, `inventory_overview` y `profile_overview` dejan de devolver Elixir, Cofre y Tesoro.
7. Quitar la columna `treasury` y las filas de `user_consumables` ya devueltas (o dejar la tabla si
   E1 la usará para objetos de logros; ver §11).

**Flutter (se borra código):** el usecase `activate_elixir.dart` y su evento en `MarketplaceBloc`, el
Tesoro de `hero_status_card.dart` y `character_profile`, Elixir y Cofre de `inventory`,
`market_board` y `dungeon_models`, sus registros en `injection_container.dart` y sus pruebas. La
pantalla de Recompensas pasa a las 3 categorías.

**Pruebas SQL:** la devolución ocurre una sola vez (la migración se puede volver a ejecutar sin pagar
de nuevo); el total de Monedas por usuario antes y después es igual a Monedas + Tesoro + devoluciones;
`_award` ya no tiene límite de bolsa, pero sí respeta el tope diario; `purchase('elixir')` falla.

### S5 · Funciones que aparecen cuando hacen falta
- **Qué ve el usuario:** la primera semana se ven **Hoy, Planificador (tareas), Hábitos y Modo Foco**.
  El resto aparece al usarse, con una tarjeta «Nuevo: Metas · Ya completaste 3 tareas; una meta las
  une hacia algo más grande» que se muestra una sola vez:

  | Se desbloquea | Cuando |
  |---|---|
  | Metas y Visión | 3 tareas completadas |
  | Recompensas | Al tener 30 Monedas (lo que cuesta lo más barato) |
  | Mentores | Nivel 2 |
  | Actividad y Estadísticas | 3 días con actividad |

- **Autonomía (CLAUDE.md §9):** en Ajustes, «Mostrar todas las funciones» desbloquea todo de una vez. Los usuarios
  que ya existen ven desbloqueado lo que ya usaron.
- **Necesita:** que `home_dashboard` devuelva `unlocked` **calculado** a partir de lo que ya hay
  (conteos de tareas, nivel, Monedas, días en `quest_log_entries`) y del ajuste
  `game_master_settings.show_all_features`. Sin tabla nueva. Que la tarjeta ya se vio se guarda en
  `shared_preferences`.
  `shortcut:` por dispositivo; en otro teléfono la tarjeta se vuelve a ver una vez.
- **Ojo:** las rutas de go_router siguen existiendo; S5 solo oculta las entradas. Un aviso o deep link
  a una función oculta la abre igual.

### R1 · Rutas listas (plantillas)
- **Qué ve el usuario:** en «Agregar» y en Metas, **«Empezar una ruta»**: «Preparar un examen»,
  «Aprender a programar», «Hacer ejercicio 3 veces por semana», «Leer 12 libros al año», «Armar mi
  portafolio», «Dormir mejor». Elige una, responde 2 o 3 preguntas (¿para cuándo? ¿qué materia? ¿qué
  área?) y la app crea **todo conectado**: la meta S.M.A.R.T., el proyecto, las tareas guiadas con
  pasos (B1) y el hábito de apoyo. Ve un resumen («Se crearon 1 meta, 6 tareas y 1 hábito») antes de
  confirmar.
- **Por qué:** es la forma más rápida de entender cómo funcionan juntos la meta, las tareas y los
  hábitos, y quita la página en blanco.
- **Necesita:**
  - Un catálogo global `route_templates` (`code`, `name`, `description`, `questions jsonb`,
    `blueprint jsonb`): solo lectura para usuarios autenticados y administrado con `service_role`,
    igual que `market_items`.
  - La RPC `start_route(p_code, p_answers)`, que crea todo en **una transacción** con las RPC internas
    de siempre. La XP de cada tarea sale por reglas (§13), no del catálogo.
  - **Una ruta activa por plantilla** (para que no se pueda repetir y cobrar en bucle).
  - Las fechas de las tareas se reparten hasta la fecha de la meta.
  - Más adelante, «Adaptar a mi caso» usa B7 (IA) para ajustar los pasos.
- **Contenido:** el texto de las 6 rutas lo escribe el equipo (§11). No lo genera la IA.

### U1 · Tareas que se repiten
- **Qué ve el usuario:** en la tarea, «Repetir: cada día / días de la semana / cada mes el día N».
  Al completarla aparece la siguiente con su fecha. Una línea explica la diferencia: **hábito** = algo
  que haces (con racha); **tarea que se repite** = algo que entregas con fecha (pagar una cuenta,
  el informe del lunes).
- **Necesita:**
  - Usar `tasks.repeat_rule` (ya existe, `text`) con un formato cerrado y validado por un `check`:
    `daily`, `weekly:1,3,5` (0 = domingo, como `specific_days`) o `monthly:15`.
  - `complete_task` crea la siguiente en la misma transacción (copia título, área, proyecto, meta y
    pasos sin marcar).
  - **Anti-trampa:** la siguiente no se puede completar antes de que empiece su periodo (el día anterior
    a su fecha en `daily`, la semana en `weekly` y el mes en `monthly`). `complete_task` lo rechaza y
    `missions_overview` la muestra como «Disponible el …».
  - Si se vence, se replantea con C4 como cualquier tarea.
  - Cierra la decisión abierta de RF-050 (CLAUDE.md §11): **basta `repeat_rule`**, sin enum `mission_type`.
- **Pruebas SQL:** completar crea una sola siguiente (también si dos llamadas llegan a la vez:
  bloquear la fila con `for update`); no se puede completar antes de tiempo; `monthly:31` en un mes de
  30 días cae el último día.

### U2 · Recordatorio con hora
- **Qué ve el usuario:** en una tarea, «Recordarme» a una hora (o «1 h antes», si tiene fecha); en un
  hábito, «Recordarme cada día a las 20:00». La notificación llega **a la hora exacta** y trae un botón
  (D1).
- **Necesita:**
  - Las columnas `tasks.remind_at timestamptz` y `habits.remind_time time`, guardadas desde
    `create_task` / `create_habit` y desde sus RPC de edición.
  - Programar en el dispositivo con `flutter_local_notifications` (`zonedSchedule`, paquete `timezone`),
    no con la revisión de cada 15 min de `workmanager`, que no es puntual.
  - Al cargar Hoy se reprograman los próximos 7 días. Al registrar un hábito se cancela el aviso de hoy.
  - **§7:** un recordatorio lo pidió el usuario, así que no cuenta para el límite diario, pero sí
    respeta la ventana de silencio y el Modo Foco (se entrega al terminar la sesión).
  - `shortcut:` si el hábito se registra desde otro dispositivo, el aviso de hoy igual llega en este;
    se corrige con push de servidor (FCM), hoy fuera de alcance.

---

## 10. Orden de construcción propuesto

| Paso | Bloque | Por qué en este orden | SQL |
|---|---|---|---|
| 0 | Identidad comercial (§3) + **S3** | Va con el rediseño en curso. Quitar antes de revestir deja menos pantallas que rediseñar | `037_commercial_copy`, `038_simple_rewards` |
| 1 | A1 + A2 + A3 | El mayor cambio de sensación con el menor costo | Mínimo |
| 2 | **S1 + S2** | Crear y usar todo desde dos lugares. Va con el rediseño de Inicio y Crear | `home_dashboard` |
| 3 | B1 + B2 + B6 | La IA ya entrega la guía estructurada: falta guardarla y recorrerla | `tasks.guide`, `task_steps` |
| 4 | **U1 + U2** | Sin tareas que se repiten ni recordatorios, la app no sirve para el día a día | `repeat_rule`, `remind_at` |
| 5 | A4 + A5 | Completan el progreso visible en metas y hábitos | Pequeño |
| 6 | **R1** | Necesita las tareas con pasos (B1) para que las rutas enseñen | `route_templates` |
| 7 | **S5** | Cuando ya están todas las secciones que se van a ocultar o mostrar | `unlocked` calculado |
| 8 | Infra de IA + B3 + B4 + B7 | Ayuda dentro de la tarea y cierre con aprendizaje | `ai_usage`, reflexión |
| 9 | Documentos del mentor + B5 | La ruta y el repaso necesitan el temario | Storage, `ai_summary` |
| 10 | C1 | El Asistente pregunta. Necesita cerrar el orden de prioridad | `current_mission` v2 |
| 11 | C2 + C3 | Acompaña el día de principio a fin | `daily_plans` |
| 12 | C4 + D1 | Lo vencido y los avisos se vuelven accionables | `reschedule_item` |
| 13 | E1 + E3 | Logros y estadísticas que se llenan con lo anterior | Semilla + funciones |
| 14 | C5, F1–F5, D2–D4, E2, E4 y los pendientes de §4 | Valor alto, pero más costo o decisiones abiertas | Variable |

Cada paso sigue CLAUDE.md §8: RF/UC primero, migración con pruebas SQL (incluido el aislamiento RLS entre
dos usuarios), domain → data → presentation, `flutter analyze` y `flutter test`, y parar hasta la revisión.

---

## 11. Decisiones que necesito del equipo

**Cerradas el 2026-10-29:** se mantiene la gamificación; nombres de §3.1 aprobados; XP repartida entre
los pasos (§6.1); S3 aprobado (se quitan Mercado negro como sección, Elixir, Cofre misterioso y Tesoro);
S1, S2, S5, R1, U1 y U2 entran al plan. **Propuesta para cerrar:** RF-050 se resuelve con `repeat_rule` (U1).

1. **Nombre de la app:** «LifeQuest» y «Questly» siguen sonando a juego. Lo decide el usuario más
   adelante; mientras tanto el plan sigue con el nombre actual.
2. **Nombre propio del Asistente:** ¿solo «Asistente» o un nombre de marca?
3. **Carpetas y rutas:** ¿se renombran también las carpetas de features y las rutas (`tavern` →
   `mentors`) o solo la UI?
4. **Orden de prioridad del Siguiente paso** (C1; CLAUDE.md §11).
5. **Bono por completar el Plan de hoy** (C2): ¿existe? ¿cuánto? (dentro del tope diario).
6. **Límite diario de llamadas a la IA** por usuario (capa gratis de Gemini).
7. **Sonido y vibración** en los momentos de recompensa: ¿activados por defecto?
8. **Contenido de las rutas** (R1): ¿quién escribe las 6 rutas (metas, tareas con pasos y hábito)?
   Puedo proponer un borrador para revisar.
9. **Umbrales de S5:** ¿sirven los de la tabla (3 tareas, 30 Monedas, nivel 2, 3 días)?
10. **`user_consumables`** (S3): ¿se borra o se guarda para objetos que den los logros (E1)?

---

## 12. Documentos que habrá que actualizar

- `CLAUDE.md`: §4 glosario con la columna «Nombre en la UI», §5–§7 y §13 con los nombres nuevos, y §8
  (deuda de arquitectura) al cerrar cada paso.
- `docs/diseño/*` (PRODUCT, DESIGN, HANDOFF) y `docs/ideas-proyecto-productividad-gamificada.md`: identidad sin fantasía.
- `Requerimientos_Funcionales.md`: RF nuevos (momento de recompensa, subida de nivel, tarea guiada con
  pasos, ayuda «Me atasqué», comprobación y reflexión, ruta del mentor, plan y cierre del día, revisión
  semanal, replantear vencidas, logros con progreso, crear con lenguaje natural, un solo «Agregar»,
  Inicio = Hoy, funciones que se desbloquean, rutas listas, recordatorios) y actualizar RF-097, RF-114
  (nombres del menú), RF-050 (`repeat_rule`) y RF-043/RF-048 (Recompensas en 3 categorías).
- `CLAUDE.md` §6 y §13 y `docs/ideas-…md` → Economía estable: sin Tesoro ni límite de bolsa, sin
  Elixir, sin Cofre misterioso y sin Mercado negro como sección.
- `Casos_de_Uso.md`: UC nuevos con trazabilidad.
- `schema.sql` y `Esquema_Base_de_Datos.md`: `task_steps`, `tasks.guide`, `tasks.self_check`,
  `tasks.reflection`, `resources.ai_summary`, `daily_plans`, `ai_usage`, columnas de Game Master y semilla de logros.
