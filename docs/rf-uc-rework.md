# Cambios a RF y UC por el rework (para el Project «LifeQuest»)

`Requerimientos_Funcionales.md` y `Casos_de_Uso.md` viven en el Project de claude.ai, no en el repo. Este documento lista qué cambiar allí para que reflejen la app de la rama `Remaked` (v2.5.x). Los RF nuevos se proponen desde **RF-117**; ajusta la numeración si ya está ocupada. Fuente del detalle: `docs/plan-rework.md` y las migraciones 032–035.

## 1. RF que se retiran (funciones quitadas de la app)

Marcarlos como **Retirado (rework, nov 2026)** en lugar de borrarlos, para conservar la trazabilidad:

- Tienda, carrito y «My Purchases», catálogo de recompensas (RF-043, RF-048 y los de compra).
- Hotel y recuperación de HP; HP visible y estado «debilitado» en la interfaz (RF-034 queda solo como regla interna sin UI).
- Mercado negro, Pase de Recuperación, Refugio, Elixir, Cofre del día.
- Taverna y NPCs con misiones (incluida la sugerencia con IA de la misión del NPC).
- Boss Fight como pantalla (las Metas siguen; el daño al jefe sigue en la base sin UI).
- Inventario, logros visibles y títulos de prestigio.
- Vision Board.
- Diario del Héroe (RF-116 ya lo indicaba en el cierre del diseño).

## 2. RF que se modifican

| RF | Antes | Ahora |
|---|---|---|
| RF-022 / RF-112 | Recompensa sugerida por dificultad y tiempo, editable | XP por reglas (10–40) que calcula el servidor; editar la tarea **no** la cambia (`update_task`, 034) |
| RF-089 | Daily Highlight en pantalla propia | El orden de urgencia sigue (`v_daily_highlight`) y alimenta Tareas y «Armar mi día» |
| RF-097 | «Misión actual» de RPGenie | «Ahora» en Hoy: el bloque de agenda en curso o, si no hay, la tarea más urgente; sin pantalla aparte |
| RF-114 | Menú de 9 secciones | Barra de 5 pestañas: **Hoy · Tareas · Hábitos · Foco · Tú**; Proyectos y metas cuelga de Tareas; Historial, Estadísticas, Bandeja y Ajustes desde Tú o Hoy |
| RF-116 | Diario | Historial (Bitácora) con acción principal «Revisar semana» |
| RF-030 / RF-031 / RF-032 | Penalización de HP visible | Se calcula en la base sin UI (pendiente de retirar del todo) |
| RF-067 | Descansos de la Mazmorra | Descansos de Foco, iguales (5/15 min, largo cada 4 ciclos) |

Terminología en todos los RF y UC: Mazmorra → **Foco**; Misión → **Tarea**; Brain Dump → **Bandeja**; Game Master → **Ajustes**; RPGenie → **asistente**; Diario → **Historial**. Sin ambientación de fantasía.

## 3. RF nuevos

| RF | Requisito | Dónde |
|---|---|---|
| RF-117 | Una tarea puede tener **hora de inicio y duración** (bloque en la agenda) | 032, Tareas, Hoy |
| RF-118 | **Aviso** N minutos antes del bloque, con botones **Hecha** y **Posponer 1 h** que funcionan con la app cerrada; respetan la ventana de silencio | 032, `reminders` |
| RF-119 | **Repetición** cerrada (cada día, lunes a viernes, días de la semana, día del mes); al completar se crea la siguiente ocurrencia en la hora local del usuario | 032 (`spawn_next_occurrence`) |
| RF-120 | **Tiempo medido**: Foco suma los minutos reales a las tareas de la sesión; «Empezar foco» abre Foco con la tarea elegida | 032 (`end_dungeon`) |
| RF-121 | **Agenda de Hoy**: bloques del día, «Sin hora» con «Poner hora» y «Mover» | 032 (`day_agenda`) |
| RF-122 | **Armar mi día** y **Replanificar**: el asistente propone bloques en los huecos libres (reglas, no IA); el usuario acepta o no | `assistant` (`DayPlanner`) |
| RF-123 | **Anotar en lenguaje natural** («gym mañana 6pm cada lunes») con vista previa editable; sin IA usa reglas locales; lo que no es tarea va a la Bandeja | `assistant` (`LocalParser`) |
| RF-124 | **IA opcional** (apagada por defecto, aviso de privacidad al activarla, tope de 40 llamadas al día) para interpretar notas y **dividir en pasos** con fechas repartidas hasta la fecha límite | 033, Edge Function `assistant` |
| RF-125 | **Dictar** tareas con la voz | `speech_to_text` |
| RF-126 | Leer el **calendario del teléfono** (con permiso explicado) para mostrar eventos en Hoy y que la agenda no choque | `core/calendar` |
| RF-127 | **Compartir** texto o enlaces desde otra app hacia la Bandeja | `receive_sharing_intent` |
| RF-128 | **Widget de inicio** con las próximas 3 tareas de hoy y marcar hecha | `home_widget` |
| RF-129 | **Editar** una tarea abierta (título, prioridad, fecha, agenda, aviso y repetición) | 034 (`update_task`) |
| RF-130 | Poner, cambiar o quitar la **hora del aviso** de un hábito bueno | 034 (`set_habit_reminder`) |
| RF-131 | **Revisión semanal**: lo hecho en la semana y, por cada pendiente, «A la otra semana» o «Soltar»; aviso los domingos a las 18:00 | 034 (`weekly_review`, `postpone_task`) |
| RF-132 | **Recursos** de una tarea, proyecto o meta: enlace, foto (cámara o galería), PDF (≤ 10 MB) o nota; se adjuntan al crear o después, se abren y se quitan con deshacer | 045 (`attach_resource`, bucket `resources`), `core/resources` |
| RF-133 | Con la IA encendida, **«Dividir en pasos» lee los recursos** de la tarea (fotos y PDF como archivo; notas y enlaces como texto) | 045, Edge Function `assistant` (`paths`, `context`) |
| RF-134 | **Prueba del paso** en Foco: al marcar un paso, nota o foto opcional que queda como recurso del paso | 045 (`dungeon_overview.steps[].proof`) |
| RF-135 | **Dónde lo dejé**: al cerrar Foco, una línea por tarea sin terminar (la app propone el siguiente paso); se muestra al volver a esa tarea | 045 (`set_resume_note`) |
| RF-136 | **Repaso activo** al empezar Foco con una tarea que tiene notas: «La última vez…» y, con la IA, 1–3 preguntas para comprobarse antes de ver las notas | Edge Function `assistant` (`recall`) |
| RF-137 | **Anotar distracción** en Foco: la idea va a la Bandeja sin salir del ciclo; el resumen dice cuántas | `capture_thought` (023) |

## 4. Casos de uso

- **Retirar**: los UC de Tienda, Mercado negro, Hotel, Taverna/NPC, Boss Fight, Inventario, títulos y Vision Board.
- **Renombrar**: los UC de Mazmorra → Foco; Misión → Tarea; Brain Dump → Bandeja.
- **Nuevos** (uno por RF nuevo, con su trazabilidad):
  - UC-32 Programar una tarea en la agenda (RF-117, RF-121)
  - UC-33 Responder a un aviso de tarea: Hecha / Posponer (RF-118)
  - UC-34 Completar una tarea que se repite (RF-119)
  - UC-35 Armar el día o replanificar con el asistente (RF-122)
  - UC-36 Anotar una tarea escribiendo o dictando (RF-123, RF-125)
  - UC-37 Dividir una tarea en pasos con IA (RF-124)
  - UC-38 Conectar el calendario del teléfono (RF-126)
  - UC-39 Guardar algo compartido desde otra app (RF-127)
  - UC-40 Completar una tarea desde el widget (RF-128)
  - UC-41 Editar una tarea (RF-129)
  - UC-42 Hacer la revisión semanal (RF-131)
  - UC-43 Adjuntar y abrir recursos de una tarea, proyecto o meta (RF-132, RF-133)
  - UC-44 Trabajar en Foco dejando prueba, repaso y Dónde lo dejé (RF-134, RF-135, RF-136, RF-137)
- Corregir de paso las referencias rotas conocidas: UC-08 → UC-10 y UC-15; UC-09 → UC-11.

## 5. Esquema

`Esquema_Base_de_Datos.md` y `schema.sql` deben sumar: columnas de agenda en `tasks` (`scheduled_at`, `estimated_minutes`, `reminder_minutes`, `focus_minutes`, `repeat_rule` con check), `habits.reminder_time`, `game_master_settings.time_zone` y `ai_enabled`, la tabla `ai_usage`, en `resources` (045) `task_id`/`project_id`/`goal_id` (máx. uno, cascada), `kind resource_kind`, `storage_path`, `size_bytes` y `note`, `tasks.resume_note`/`resume_at`, y quitar las tablas borradas en 035 (`market_items`, `user_market_selection`, `purchases`, `black_market_items`, `black_market_redemptions`, `recovery_passes`, `vision_boards`, `inventory_items`, `user_inventory`, `npcs`).
