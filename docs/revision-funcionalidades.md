# Revisión de funcionalidades — app completa (2026-11-07)

Hecha con la skill `revision-funcionalidades` (`.claude/skills/revision-funcionalidades`) sobre el código actual de la rama `Remaked`. Prioridad = impacto en el día × cercanía al hueco × riesgo bajo (1–3 cada uno).

| Función | Dónde | Veredicto | Por qué | Qué le falta para actuar | Prioridad |
|---|---|---|---|---|---|
| Agenda de Hoy y «Armar mi día» | `day_agenda`, `DayPlanner` | Actúa | 1 · 4 · 5: bloques con hora, replanificar lo atrasado | — | — |
| Recordatorios con Hecha / Posponer | `ReminderActions`, 032/038 | Actúa | 1 · 3 | — | — |
| Tareas (crear, «Ya la hice», repetir) | `tasks`, `create_task` | Actúa | 1 · 4: fecha, aviso, repetición real | — | — |
| Foco | `focus`, 012/037 | Actúa | 2 · 4: mide minutos, pasos, cierre con «Agendar para mañana» | — | — |
| Dividir en pasos | `BreakDownTask`, Edge `assistant` | Actúa | 4 | Usar el temario del usuario (ver Recursos) | — |
| Cierre del día | `review`, aviso 21:00 | Actúa | 1 · 5 | — | — |
| Widget, voz, compartir, calendario | `app/` | Actúa | 3 | — | — |
| Hábitos buenos | `habits`, 011/034/039 | Actúa a medias | 1: el aviso suena, pero no sale en la agenda ni trae «Hecho» en la notificación | Botón «Hecho» en el aviso del hábito (pregunta 3) | **Alta** (3×3×2 = 18) |
| Hábitos malos | `register_bad_habit` | Solo guarda | Registrar un evento no cambia nada del día | Mostrar el patrón («suele pasar de noche») y proponer un hábito bueno a esa hora (pregunta 5) | Baja (2×1×2 = 4) |
| Proyectos y urgencia | `stage_overview`, `_project_urgency` | Solo muestra | La urgencia 🔴 se calcula pero no avisa fuera de la app ni mueve trabajo | Al pasar a 🔴, aviso local con «Armar mi día con este proyecto» (preguntas 3 · 5) | **Alta** (2×3×3 = 18) |
| Metas S.M.A.R.T. | `goals`, 014 | Solo guarda | Ficha y porcentaje; nada ocurre si se estanca | Si una meta lleva 7 días sin avance, proponer su siguiente paso en Hoy (pregunta 5) | Media (2×2×2 = 8) |
| Recursos | `create_resource`, 013 | Solo guarda | Título + enlace que nadie lee | Texto del recurso como contexto de «Dividir en pasos» (pregunta 4); **pendiente tu decisión de privacidad** | Media (2×2×2 = 8) |
| Bandeja (Brain Dump) | `brain_dump`, 023 | Actúa a medias | Convierte con G.T.D., pero lo no convertido se acumula en silencio | En el cierre del día: «Tienes 3 notas sin decidir» (pregunta 5) | Media (2×3×2 = 12) |
| Historial | `journal`, 020 | Solo muestra | Lista de lo hecho; su única acción es «Revisar semana» | Fundirlo con el cierre del día / la semana (quitar pantalla) | Media (1×3×3 = 9) |
| Estadísticas | `stats`, 025 | Solo muestra | Números y 3 observaciones sin acción | Cada observación con su botón («Rindes más de 9 a 11 → Armar mañana ahí») (pregunta 4) | Baja (1×2×3 = 6) |
| Centro de avisos | `notifications`, 029 | Solo muestra | Avisos dentro de la app que solo se marcan como leídos | Cada aviso abre su acción (tarea, hábito, proyecto) | Media (2×3×2 = 12) |
| Tú (perfil, áreas) | `profile`, 002 | Solo muestra | Nivel y áreas; las áreas no cambian nada del día | Aceptable como ajustes; sin cambio | — |

## Qué construir primero

1. ~~**Hábitos: «Hecho» en la notificación**~~ — hecho el 2026-11-07.
2. ~~**Proyecto en 🔴 avisa**~~ — hecho el 2026-11-07 (042): aviso a las 9:00 del día en que pasaría a 🔴.
3. ~~**Avisos que abren su acción**~~ — hecho el 2026-11-07 (043): «Abrir» en el centro de avisos y tocar un aviso del teléfono lleva a su pantalla.
4. ~~**Bandeja dentro del cierre del día**~~ — hecho el 2026-11-07 (044): «N notas sin decidir» con «Decidir» en la revisión.
5. ~~**Historial dentro de «Tu semana»**~~ — hecho el 2026-11-16.
6. ~~**Estadísticas con acción, metas quietas en Hoy y hábitos con hora en la agenda**~~ — hecho el 2026-11-16 (046).

## Bloqueadas

- **Recursos como contexto de la IA** — choca con la regla de privacidad (CLAUDE.md §11) hasta que decidas. Versión que cabe: texto pegado por el usuario, enviado solo al pulsar «Dividir en pasos», con aviso.
