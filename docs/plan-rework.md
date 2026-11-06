# Plan del rework de Questly (rama `Remaked`)

Plan aprobado el 2026-10-31. Este archivo es el que se retoma para continuar: cada fase dice qué hacer, qué está hecho y cómo comprobarlo.

## Contexto
El tutor rechazó la versión RPG: crear una tarea (manual o con IA) solo guardaba una fila de texto y no pasaba nada después; había muchas pantallas de solo lectura y una economía de fantasía. Objetivo: **cada cosa que el usuario crea hace algo en su día real**, como un asistente.

Decisiones del usuario:
- **Juego ligero:** quedan XP, nivel y racha. Fuera Tienda/Monedas, Taverna/NPCs, Jefes, HP visible, Cofre, Inventario, títulos y Vision Board.
- **Nombre visible:** Questly (el repo y el paquete siguen como LifeQuest).
- **Tareas reales:** agenda por horas, recordatorio con botones de acción, repetición real, tiempo medido.
- **Asistente que actúa:** crea con fecha y hora, arma el día, divide y programa, replanifica.
- **Sistema:** voz, calendario del teléfono, compartir a la app, widget de inicio.
- **Plataforma:** Android primero (no se compila iOS en Windows).

Principios:
- Arquitectura sin cambios (CLAUDE.md §8): Clean + Bloc/get_it/go_router/fpdart, RPC `SECURITY DEFINER`, la XP la calcula el servidor.
- **Lo determinista va por reglas; la IA solo cubre el lenguaje.** Armar el día, replanificar y repartir fechas son Dart puro en `domain`, con tests. La IA (Gemini capa gratis) interpreta texto y propone subtareas.
- Todo gratis: plugins open source y Gemini sin facturación, con tope por usuario.
- Commits con `/fxcommit`: subir versión, sin `Co-Authored-By`, push.

## Estado

| Fase | Estado |
|---|---|
| 0 · Base | ✅ Hecha (`bfc64ea`) |
| 1 · Quitar fantasía y diseño nuevo | ✅ Hecha (v2.0.0 y v2.1.0, diseño «Calendario de taco») |
| 2 · Tareas que actúan | ✅ Hecha en código (v2.3.0); falta aplicar 032 en Supabase y probar en un teléfono |
| 3 · Asistente | ⏳ Pendiente |
| 4 · Integración con el teléfono | ⏳ Pendiente |

## Fase 1 · Hecho
- Borradas las features `tavern`, `marketplace`, `inventory`, `vision`, `rpgenie`, la pantalla de `goals`, el Cofre y la Edge Function `npc-mission`.
- Pestañas **Hoy · Tareas · Hábitos · Foco · Tú**; Tareas es la raíz y Proyectos y metas cuelga de ella.
- Diseño «Calendario de taco» (`docs/diseño/DESIGN.md`, `PRODUCT.md`): suelo de papel, hoja con borde arrancado, número del día en rojo, Archivo, acciones en tinta, filas `SheetRow` con check, movimiento de Emil Kowalski (escala 0,97 / 160 ms / ease-out fuerte).
- Contrato de dirección de impeccable: `.impeccable/surfaces/` (sin versionar).

**Deuda que queda de la fase 1:**
- Las tablas y RPC económicas siguen en Supabase sin uso visible. `shortcut:` limpiarlas en una migración cuando la app esté estable.
- Historial y Estadísticas siguen siendo de solo lectura (solo se reestilaron).
- Comentarios del código con términos viejos (Mazmorra, Stage, RPGenie) y nombres de clases (`DungeonBloc`, `MissionsBloc`).
- RF y UC del Project de claude.ai no reflejan el rework.

## Fase 2 · Tareas que actúan

**Migración `032_scheduling.sql`** (+ tests en `supabase/tests`):
- `tasks.scheduled_at timestamptz`: bloque en la agenda.
- `tasks.estimated_minutes`: vuelve a usarse como duración del bloque, sin tocar la recompensa.
- `tasks.reminder_minutes int`: aviso N minutos antes.
- `tasks.repeat_rule`: formato cerrado con `check` (`daily` | `weekdays` | `weekly:0,3` | `monthly:15`). `complete_task` crea la siguiente ocurrencia en la misma transacción.
- `tasks.focus_minutes int`: lo suma `end_dungeon` desde `focus_session_tasks`.
- `habits.reminder_time time`.
- RPC `schedule_task(id, at, minutes)` y `snooze_task(id, minutes)`; `create_task` acepta los campos nuevos.

**Hecho (032):** columnas, `check` de `repeat_rule`, siguiente ocurrencia por trigger al completar (en hora local con `game_master_settings.time_zone`, que el cliente debe guardar al abrir), `schedule_task`, `snooze_task`, `create_task` ampliado, `end_dungeon` reparte los minutos medidos `missions_overview` devuelve la agenda, `day_agenda` alimenta Hoy y `sync_reminders` guarda la zona horaria y lista los avisos. Tests: `supabase/tests/032_scheduling.test.mjs`. ⚠️ Falta aplicarla en Supabase.

**Hecho (Flutter):** hoja de tarea con hora, duración, aviso y repetición; fila con repetición y minutos de foco; Hoy con «Ahora» (bloque en curso), Agenda y «Sin hora» (botones Mover / Poner hora con selector de hora, en vez de arrastrar); feature `reminders` (`SyncReminders` corre la ventana de silencio y tiene tests) y `app/reminder_actions.dart` con Hecha / Posponer 1 h también con la app cerrada. Se sincroniza al iniciar sesión, al volver a la app y al cambiar tareas o agenda; al cerrar sesión se borran. Hábitos: hora de aviso al crear (no se edita después). «Empezar foco» en Hoy y Tareas abre Foco con esa tarea en la mochila (`/dungeon?task=<id>`). **Falta:** aplicar 032 en Supabase y la prueba en un teléfono Android.

**Flutter (plan original):**
- **Agenda por horas en Hoy:** debajo del número del día, rejilla de horas con las tareas programadas y los eventos del calendario (fase 4); arrastrar con `LongPressDraggable`/`DragTarget` → `schedule_task`; «Sin hora» con lo pendiente. La fila actual sigue siendo la única en rojo, con la línea «ahora».
- **Recordatorios** en `lib/core/reminders/` (`flutter_local_notifications` + `timezone` + `flutter_timezone`): tareas con hora, hábitos con hora y fin de ciclo de Foco. Botones **Hecha** y **Posponer 1 h** con un handler en segundo plano que inicia Supabase con la sesión guardada y llama a `complete_task` / `snooze_task`. Reprogramar al abrir y al cambiar; cancelar al completar o borrar. Respetar la ventana de silencio y el tono de invitación (CLAUDE.md §7). Android: `POST_NOTIFICATIONS`, alarmas inexactas.
- **Repetición:** selector en la hoja de crear o editar tarea.
- **Tiempo medido:** «Empezar foco» abre Foco con la tarea preseleccionada; el detalle muestra minutos reales frente a estimados.

## Fase 3 · Asistente

**Reglas** (feature `assistant`, `domain`, Dart puro y testeado):
- `PlanDay`: llena los huecos libres de hoy (entre eventos y bloques puestos) en orden: vencidas → urgencia/prioridad → fecha más próxima; respeta `estimated_minutes` (30 min por defecto).
- `Replan`: lo vencido o con bloque pasado sin hacer va al siguiente hueco de hoy o mañana.
- `SpreadDates`: reparte subtareas de forma uniforme hasta la fecha límite del proyecto.
- La UI muestra la propuesta como vista previa; se acepta con un toque (lote de `schedule_task`) o se ajusta.

**IA** (Edge Function `supabase/functions/assistant`, Gemini capa gratis; el `fetch`, el timeout de 25 s y el `reason` se recuperan de la `npc-mission` borrada, ver commit `8dd09f2`):
- `parse`: texto → `{title, scheduled_at, due_date, estimated_minutes, repeat_rule, reminder_minutes, priority, area, kind}` («gym mañana 6pm cada lunes»). Sin IA: parser local en `domain` (hoy, mañana, días de la semana, HH:mm, «cada …», «en N min»).
- `breakdown`: título → 3–7 subtareas; `SpreadDates` les pone fecha; se crean con `create_task`.
- **Privacidad y tope:** migración `033_assistant.sql` con tope diario por usuario (40 llamadas) y `game_master_settings.ai_enabled` apagado por defecto; aviso al activarlo (en la capa gratis Google puede usar los títulos). Solo se envía el texto y los títulos.
- **Captura:** barra «Escribe o dicta…» en Hoy y en el botón flotante → vista previa con chips (fecha, hora, repetir, aviso, área) → Confirmar. Si no es tarea, va a la Bandeja.

## Fase 4 · Integración con el teléfono
- **Voz:** `speech_to_text` en la barra de captura; el texto pasa por `parse`.
- **Calendario:** `device_calendar`; lee hoy y mañana para que la agenda y `PlanDay` no choquen; opcional escribir los bloques de Foco en un calendario «Questly». Pide permiso con explicación y funciona aunque se niegue.
- **Compartir:** `receive_sharing_intent`; texto o enlaces desde otra app abren la vista previa de captura (por defecto a la Bandeja).
- **Widget de inicio:** `home_widget` + `AppWidgetProvider` en Kotlin; próximas 3 tareas de hoy y marcar hecha con un callback Dart en segundo plano (`complete_task`).

## Verificación (cada fase)
- `flutter analyze` sin errores y `flutter test` en verde; tests nuevos de `PlanDay`, `Replan`, `SpreadDates`, el parser local y la repetición.
- SQL: `cd supabase/tests && npm test` sobre Postgres real (siguiente ocurrencia, `schedule_task`/`snooze_task`, `focus_minutes`, tope de IA, RLS entre dos usuarios).
- Edge Function: test Deno que valide la salida de `parse` sin confiar en el JSON de la IA.
- En un teléfono Android: dictar «llamar a mamá mañana 7pm» y verla en la agenda con aviso; Hecha y Posponer desde la notificación; repetir; Empezar → Foco → minutos guardados; armar el día evitando un evento; replanificar; dividir un proyecto; compartir desde Chrome; marcar desde el widget; modo claro y oscuro.
- Diseño: capturas con un test golden temporal (fuente Archivo cargada con `FontLoader`) para mirar cada pantalla; seguir `docs/diseño/DESIGN.md` y las skills impeccable, design-taste-frontend y emil-design-eng.

## Fuera de alcance
Borrar las tablas económicas, push remoto (FCM), widget y acciones de notificación en iOS, sincronización con Google Calendar en la nube, traducción al inglés.
