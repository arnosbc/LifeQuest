# Gestores de tareas que actúan en el día real: Todoist, TickTick y Things 3 (estado a nov 2026)

> Nota de método: 17 llamadas de búsqueda/lectura. El sitio de Cultured Code (culturedcode.com) no resolvió DNS desde el entorno de investigación, así que Things se cubre con MacRumors y resúmenes de búsqueda de sus notas de versión. El changelog oficial de TickTick (ticktick.com/public/changelog) cargó vacío (se renderiza con JS); TickTick se cubre con su página principal, su blog y agregadores (Releasebot, APKMirror), de fiabilidad menor. Lo que viene solo de memoria previa del investigador está marcado como **[sin verificar]** y no lleva fuente.

## 1. ¿Qué funciones de cada app actúan solas sobre el día (recordar, agendar, medir tiempo, integrarse con el sistema)?

### Takeaway
Las tres actúan sobre el día con recordatorios y widgets interactivos, pero con perfiles distintos: **Todoist** apuesta por captura con IA (voz «Ramble», fotos/PDF), alarmas «urgentes» a pantalla completa en Android y calendario bidireccional; **TickTick** es el más «todo en uno» (recordatorio constante hasta completar, Pomodoro/cronómetro con Live Activity, hábitos, vista de calendario/timeline); **Things 3** es solo Apple, sin IA propia ni Pomodoro, y actúa por Siri AI (iOS 27), Spotlight, widgets interactivos y posponer desde la notificación.

### Cited Findings

**Todoist (Android primero)**
- Ramble (voz → tareas con fecha, prioridad, etiquetas) lanzado el 21-ene-2026, en **todos los planes**, iOS/Android/escritorio, 38 idiomas; widget y atajo de Android desde el lanzamiento — [Todoist changelog Ramble, 21-ene-2026](https://www.todoist.com/help/todoist/product-updates/turn-your-scattered-thoughts-into-clear-tasks-ramble-jan-21-2026-HhmP8ue8R); [Todoist 2026 changelog](https://www.todoist.com/help/todoist/product-updates/2026-changelog-HD3jJAtLd)
- Ramble en Wear OS (beta) en marzo 2026: hablas al reloj y crea tareas — [Todoist, 23-mar-2026](https://www.todoist.com/help/todoist/product-updates/just-talk-to-your-wrist-ramble-on-wear-os-beta-mar-23-2026-Kskv3T9JF)
- Ramble admite asignar a miembros del proyecto al dictar (Web/Android 16-abr; iOS 25-jun) — [2026 changelog](https://www.todoist.com/help/todoist/product-updates/2026-changelog-HD3jJAtLd)
- **Recordatorios urgentes (Android, 20-ago-2026):** activar «Urgente» en un recordatorio dispara una alarma a pantalla completa que atraviesa Silencio y No molestar; desde 8-oct el sonido se repite hasta que se actúa («nag»). El 8-oct los planes **Free** reciben control de urgencia en su único recordatorio automático a la hora de vencimiento (Pro/Business ya lo tenían). En iOS los recordatorios urgentes se re-registran tras actualizar/restaurar (24-sep) — [2026 changelog](https://www.todoist.com/help/todoist/product-updates/2026-changelog-HD3jJAtLd)
- Recordatorios por ubicación existen (iOS los distingue con un pin de mapa, 19-feb; Android corrige radios inusuales, 2-abr) — [2026 changelog](https://www.todoist.com/help/todoist/product-updates/2026-changelog-HD3jJAtLd)
- Notificaciones de revisión matutina y vespertina; desde 5-nov-2026 las tareas con solo fecha límite cuentan en Hoy, Wear OS y esas notificaciones — [2026 changelog](https://www.todoist.com/help/todoist/product-updates/2026-changelog-HD3jJAtLd)
- Lenguaje natural en Quick Add: «Meet tomorrow 9-10» fija hora de inicio **y duración** (Android, planes de pago, 24-sep-2026) — [2026 changelog](https://www.todoist.com/help/todoist/product-updates/2026-changelog-HD3jJAtLd)
- Calendario / time-blocking: en Android, mantener pulsado y arrastrar en la vista calendario fija la hora de inicio de una tarea nueva (15-oct); en iOS arrastrar para mover bloques nuevos antes de guardar (17-sep); colorear tareas del calendario por prioridad/proyecto/etiqueta (20-ago); ajustes de calendario reorganizados en cuentas, eventos y **sincronización de tareas** con Google/Outlook (Android, 5-nov) — [2026 changelog](https://www.todoist.com/help/todoist/product-updates/2026-changelog-HD3jJAtLd)
- Cabecera de Hoy en iOS con resumen «5 tareas · 2 h 30 min» (iOS 26+, 22-oct) — [2026 changelog](https://www.todoist.com/help/todoist/product-updates/2026-changelog-HD3jJAtLd)
- Widgets: Android con widget de lista que conserva el scroll al completar (16-jul), widget de Acciones rápidas, atajo de Ramble en el widget (17-sep); Wear OS con widget «Day Progress» (15-oct); iOS con botón Ramble en widgets medianos/grandes (24-sep), widgets de meta semanal y productividad (9-jul) — [2026 changelog](https://www.todoist.com/help/todoist/product-updates/2026-changelog-HD3jJAtLd)
- Siri / Shortcuts (iOS): App Shortcuts «Abrir Ramble», «Abrir Hoy», «Abrir Próximo» (26-feb); los atajos que crean tarea/proyecto confirman sin abrir la app ni desbloquear (22-oct); con Siri AI de iOS 27 Siri lee la pantalla («completa la tercera», «reprograma la segunda para mañana», 24-sep y 1-oct) — [2026 changelog](https://www.todoist.com/help/todoist/product-updates/2026-changelog-HD3jJAtLd)
- Compartir a la app: Quick Add se abre más rápido desde la hoja de compartir (iOS, 17-sep); escaneo imagen→tarea desde compartir (corregido 8-oct) — [2026 changelog](https://www.todoist.com/help/todoist/product-updates/2026-changelog-HD3jJAtLd)
- Email Assist: correos reenviados se vuelven tareas — [Todoist Assist](https://www.todoist.com/todoist-assist)
- Live Activities y botones de acción en la notificación (Hecho/Posponer): **no aparecen** en el changelog 2026 leído (solo un fix de «Leer todo» en Android, 21-may) — [2026 changelog](https://www.todoist.com/help/todoist/product-updates/2026-changelog-HD3jJAtLd)

**TickTick**
- Recordatorio constante: las notificaciones se repiten hasta completar la tarea; recordatorios repetitivos semanal/mensual/anual/personalizado; fechas y horas en el texto se reconocen (NLP) para fijar recordatorio — [ticktick.com](https://ticktick.com/)
- «Annoying Alert» repite avisos de tareas de alta prioridad; «Prominent Alerts» atraviesa Silencio/Focus como una alarma del Reloj; recordatorios constantes también para hábitos; posponer minutos/horas/día siguiente — resumen de búsqueda basado en [Android Authority](https://www.androidauthority.com/keep-coming-back-to-ticktick-3719344/) y [App Store](https://apps.apple.com/JP/app/id626144601) (no verificado en fuente oficial)
- «Constant reminders» y formatos de fecha personalizados (20-may-2026), navegación rápida de fechas (2-jun-2026), reglas de repetición avanzadas (último día del mes, fechas anuales especiales, v8.0.3.0) — [Releasebot](https://releasebot.io/updates/ticktick); [APKMirror 8.0.3.0](https://www.apkmirror.com/apk/ticktick-limited/ticktick-to-do-list-with-reminder-day-planner/ticktickto-do-list-calendar-8-0-3-0-release/) (agregadores)
- Pomodoro de 25 min incorporado; hábitos con biblioteca, seguimiento flexible y estadísticas; sincronización en tiempo real teléfono/PC/tablet/reloj; suscripción a calendarios; vistas Calendario, Timeline, Kanban, vista dividida; vista semanal que resalta bloques libres/ocupados — [ticktick.com](https://ticktick.com/)
- Foco: cuenta atrás Pomodoro o cronómetro ascendente, 17 ruidos blancos; en iPhone el temporizador es **Live Activity** (pantalla de bloqueo y Dynamic Island) — [TidBITS, ago-2025](https://tidbits.com/2025/08/14/ticktick-provides-a-focused-daily-task-list-and-more/); modo cronómetro y estadísticas de foco — [blog TickTick, 2020](https://blog.ticktick.com/2020/05/06/brand-new-focus-experience-ticktick/) (antiguo)
- IA: asistente conversacional que crea tareas, organiza listas y «desglosa proyectos con una sola instrucción»; AI Voice Capture extrae fechas y prioridades y crea varias tareas a la vez — [ticktick.com](https://ticktick.com/)
- v8.0 (15-ene-2026) con tareas sugeridas; voz con IA, soporte MCP y transcripción de audio en 8.x — reseñas de terceros con fechas que no coinciden — [TechHarry, sep-2026](https://www.techharry.com/2026/09/tick-tick-review.html); [Nathan Ojaokomo](https://nathanojaokomo.com/blog/ticktick-review)
- «Quick Ball» (botón flotante de captura rápida) en Android, listado como Premium; Premium ≈ 3 USD/mes o 35,99 USD/año; descuento educativo 25 % — [TechHarry](https://www.techharry.com/2026/09/tick-tick-review.html); [ticktick.com](https://ticktick.com/)
- Límites del plan gratuito reportados: ~9 listas, 99 tareas por lista, 19 subtareas por tarea — resumen de reseñas en búsqueda (no oficial)
- Última versión Android encontrada: 8.0.8.1 (19-may-2026); creación de tareas por Telegram en 8.1.0.1 (build Windows) — [APKMirror](https://www.apkmirror.com/apk/ticktick-limited/ticktick-to-do-list-with-reminder-day-planner/ticktickto-do-list-calendar-8-0-2-0-release/); [Adaptiva](https://adaptiva.com/patch-library/1000006189_patch_for_ticktick_x86)

**Things 3 (solo Apple)**
- 3.24 (14-sep-2026, iOS 27): **Siri AI** crea to-dos hablando natural y sigue la conversación para añadir notas, fecha de inicio y alertas sin abrir la app; índice completo en **Spotlight** (desactivable); **posponer desde la notificación**: 15 min, 1 h, 3 h y «hasta mañana»; nuevo widget XL vertical — [MacRumors, 14-sep-2026](https://macrumors.com/2026/09/14/things-3-updated-for-ios-27)
- Widgets interactivos (completar to-dos desde Small/Medium/Large; en Mac también en el escritorio); 3.24 añade opción para **apagar** la interactividad del widget — [Things iPhone Release Notes](https://culturedcode.com/things/support/articles/2409121/); [Mac Release Notes](https://culturedcode.com/things/support/articles/1100684/) (vía resumen de búsqueda; el sitio no cargó)
- Recordatorios por hora que se envían a todos los dispositivos al instante; Siri: «En Things, recuérdame llamar a John a las 5» — mismo resumen de [Things Release Notes](https://culturedcode.com/things/support/articles/2409121/)
- 3.23 (ago-2026) rehace los to-dos repetitivos y añade edición en lote; 3.22 rediseño Liquid Glass; soporte iPhone Duo (21-oct-2026); última versión 3.25.2 (2-nov-2026) — [MacRumors roundup](https://www.macrumors.com/roundup/things-3/); [Borncity](https://borncity.com/news/things-3-23-cultured-code-ueberarbeitet-wiederholungs-system/)
- Eventos del calendario del teléfono (los calendarios que elijas) aparecen arriba en Hoy y en Próximo (lectura, no time-blocking) — [Tools and Toys](https://toolsandtoys.net/things-3-for-ios-apple-watch-and-mac/); [TechRepublic](https://www.techrepublic.com/article/things-3-review/)
- Live Activity «Today» de Things: **solo** lo afirma un blog de baja calidad que se contradice; sin nota oficial — [notewall.info](https://notewall.info/blog/live-activities-for-reminders-iphone)

### Inferences
- Patrón común 2026: la captura se mueve fuera de la app (voz en widget/reloj, compartir, Siri que lee la pantalla). La app que «actúa» es la que no obliga a abrirla.
- Todoist y TickTick convergen en recordatorios «que no se pueden ignorar» (urgente/constante a pantalla completa). Things se queda en posponer suave.
- La vista de calendario con arrastrar para crear bloque (Todoist Android) y la duración por NLP («9-10») son la forma más barata de time-blocking.

### Gaps
- No pude confirmar en fuente oficial si las notificaciones de Todoist y TickTick en Android traen botones Hecho/Posponer. **[sin verificar]** ambas los tienen desde hace años.
- No hay fuente sobre notificación continua del temporizador de TickTick en Android (equivalente a Live Activity).
- Todoist: no hay Pomodoro nativo en lo leído **[sin verificar]**. Recordatorios por ubicación de Todoist son de pago **[sin verificar]**.
- TickTick: sincronización bidireccional con Google Calendar es Premium **[sin verificar]**; la página oficial solo dice «suscribir calendarios».
- Things: sin recordatorios por ubicación, sin Android, sin Pomodoro, sin IA propia **[sin verificar]** (ninguna fuente lo confirma o desmiente). Things es compra única por plataforma **[sin verificar]**.
- Entradas ene-ago 2026 del changelog de Todoist solo se leyeron parcialmente (últimos 33 k caracteres sin leer).

## 2. ¿Cómo ayuda cada app a partir una tarea grande en pasos, y su IA usa contexto o documentos del usuario?

### Takeaway
Todoist tiene el desglose con IA más documentado («Suggest subtasks» junto a «Añadir subtarea», usando el título y el contexto disponible) y extrae tareas de **texto pegado, fotos de pizarra, capturas y PDF**; TickTick lo promete vía su asistente conversacional sin un botón documentado; Things solo tiene listas de verificación manuales dentro de cada to-do.

### Cited Findings
- Todoist «Suggest subtasks», junto a «Add sub-task» en la vista de tarea, sugiere subtareas a partir del título de la tarea y «cualquier contexto disponible»; forma parte de Todoist Assist — [Todoist, Subtask suggestions](https://www.todoist.com/help/articles/subtask-suggestions-may-9-wvMAyd5w5) (texto del resumen de búsqueda; la página fetcheada solo mostró el índice)
- Antes: extensión «AI Assistant / Task Assist» → «Break task down» en menú de tres puntos; la ayuda la lista para Pro/Business en Web/Windows/Linux, no iOS/Android — [Todoist help, Task Assist](https://www.todoist.com/help/todoist/todoist-and-ai/use-the-task-assist-extension-with-todoist-ZgldtcPeT); un blog dice que es gratis — conflicto con la ayuda oficial, [Asian Efficiency](https://www.asianefficiency.com/task-management/todoist-ai-setup-guide/)
- Todoist «Extract tasks…» en Quick Add: tareas desde texto pegado, fotos de pizarra o PDF, con revisión antes de guardar (oct-2026) — [2026 changelog](https://www.todoist.com/help/todoist/product-updates/2026-changelog-HD3jJAtLd); captura de captura de pantalla/PDF/nota manuscrita, texto de reuniones/correos, Email Assist — [Todoist Assist](https://www.todoist.com/todoist-assist)
- Todoist expone descripciones de proyecto y sección por API/CLI/MCP para que agentes de IA lean el contexto (9-jul-2026); conectores oficiales con Claude y ChatGPT y servidor MCP (OAuth) — [2026 changelog](https://www.todoist.com/help/todoist/product-updates/2026-changelog-HD3jJAtLd); [Todoist Assist](https://www.todoist.com/todoist-assist)
- Planes Todoist: Filter Assist y básicos gratis; capacidades avanzadas con uso mensual limitado en Free y completo en pago — [Todoist Assist](https://www.todoist.com/todoist-assist)
- Privacidad Todoist (afirmación del proveedor): IA en infraestructura propia; datos no usados para entrenar; solo proveedores que se comprometen a no entrenar — [Todoist Assist](https://www.todoist.com/todoist-assist)
- TickTick: asistente IA «desglosa proyectos con una sola instrucción» y crea varias tareas a la vez desde voz — [ticktick.com](https://ticktick.com/); no se encontró botón nativo de «desglose» documentado; Gemini→subtareas vía Make es un flujo externo — [Make](https://www.make.com/integrations/ticktick/gemini-ai)
- Things: listas de verificación (checklists) dentro del to-do para trabajo de varios pasos que no merece proyecto; proyectos con encabezados para lo grande — [Tools and Toys](https://toolsandtoys.net/things-3-for-ios-apple-watch-and-mac/)

### Inferences
- El desglose útil para un estudiante es el de Todoist: sugerencia en el sitio donde ya se añaden subtareas, revisión antes de guardar. Ninguna de las tres pone fechas a cada paso automáticamente según lo leído.
- Contexto de documentos: solo Todoist usa documentos del usuario (PDF/foto/texto) y solo para **extraer** tareas, no para desglosar con ese material.

### Gaps
- No se confirmó si «Suggest subtasks» de Todoist funciona en móvil ni su plan exacto en 2026.
- TickTick: no hay doc oficial de qué contexto envía a su IA ni con qué proveedor.

## 3. ¿Qué gamificación o motivación usa cada una y hay dark patterns?

### Takeaway
Todoist Karma (puntos, 8 niveles, metas diaria/semanal con rachas, con días libres y modo vacaciones que protegen la racha y opción de apagarlo) es la referencia de gamificación ética; TickTick usa nivel/puntuación de logros (datos de 2017), rachas de hábitos y estadísticas de foco; Things no tiene gamificación. Los únicos patrones discutibles son de monetización (pantallas de upgrade) y alarmas insistentes, ambas opcionales.

### Cited Findings
- Karma: puntos por tarea completada, 8 niveles hasta «Enlightened», más difícil subir cuanto más alto; meta diaria 5 y semanal 25 por defecto; rachas por cumplir metas suman Karma; días libres y modo vacaciones no rompen la racha; soporte restaura la última racha rota; se puede pausar Karma sin perder rachas; gráfico de tendencia en Productividad — [Todoist, Introduction to Karma](https://todoist.com/help/articles/introduction-to-karma-OgWkWy)
- Karma resta con tareas vencidas: el modal corregido indica umbral de 5 días de retraso (27-ago-2026, web) — [2026 changelog](https://www.todoist.com/help/todoist/product-updates/2026-changelog-HD3jJAtLd)
- Widgets de meta semanal y productividad en iOS — [2026 changelog](https://www.todoist.com/help/todoist/product-updates/2026-changelog-HD3jJAtLd)
- TickTick 4.0 (2017): 10 niveles, puntuación de logros ligada a tareas completadas y vencidas, temas desbloqueables por nivel — [blog TickTick 4.0, 2017](https://blog.ticktick.com/2017/10/18/say-hi-to-ticktick-40/) (antiguo)
- TickTick hábitos: racha actual y días totales, estadísticas de hábito; panel de estadísticas de tareas, foco y estado semanal de hábitos; «Win Badges» — [blog TickTick Habit, 2020](https://blog.ticktick.com/2020/05/22/a-healthier-life-with-ticktick-habit/) (antiguo); botón «Freeze» que protege la racha un día — solo [mindcrate, abr-2026](https://mindcrate.vercel.app/how-to-track-habits-on-ticktick-d9ad45) (no verificado)
- Todoist reconstruyó la pantalla «Upgrade to Pro» en Android con comparativa lado a lado (17-sep-2026) — [2026 changelog](https://www.todoist.com/help/todoist/product-updates/2026-changelog-HD3jJAtLd)
- Things 3.24 permite apagar Spotlight y la interactividad del widget (control del usuario) — [MacRumors](https://macrumors.com/2026/09/14/things-3-updated-for-ios-27)

### Inferences
- Karma y TickTick premian y además restan por tareas vencidas: aversión a la pérdida suave, mitigada en Todoist con días libres/vacaciones/pausa. Patrón copiable: «proteger racha» sin pagar.
- No se encontró evidencia de dark patterns fuertes (cajas de botín, monedas compradas, rankings). Las alarmas insistentes son opt-in por tarea.

### Gaps
- Sin fuente 2026 del sistema de logros actual de TickTick.
- Sin reseñas que analicen dark patterns en estas apps explícitamente.

## 4. ¿Qué funciones distintivas copiaría una app de productividad para estudiantes?

### Takeaway
Las más baratas y con más efecto en el día: captura por voz desde widget/atajo con lenguaje natural que fija fecha **y duración**; recordatorio «urgente» que repite hasta Hecho/Posponer; posponer con opciones fijas (15 min / 1 h / 3 h / mañana); arrastrar en calendario para crear bloque; temporizador de foco atado a una tarea con notificación en curso; extraer tareas de foto de pizarra/PDF de un sílabo; racha con días libres.

### Cited Findings
- Voz → varias tareas con fechas y prioridades, desde widget, reloj y atajos — [Todoist Ramble](https://www.todoist.com/help/todoist/product-updates/turn-your-scattered-thoughts-into-clear-tasks-ramble-jan-21-2026-HhmP8ue8R); [ticktick.com](https://ticktick.com/)
- NLP con duración («tomorrow 9-10») y resumen del día «5 tareas · 2 h 30 min» — [2026 changelog](https://www.todoist.com/help/todoist/product-updates/2026-changelog-HD3jJAtLd)
- Alarma urgente que atraviesa No molestar y repite sonido hasta actuar — [2026 changelog](https://www.todoist.com/help/todoist/product-updates/2026-changelog-HD3jJAtLd); recordatorio constante hasta completar — [ticktick.com](https://ticktick.com/)
- Posponer 15 min / 1 h / 3 h / hasta mañana desde la notificación — [MacRumors](https://macrumors.com/2026/09/14/things-3-updated-for-ios-27)
- Arrastrar en calendario para fijar inicio de tarea nueva — [2026 changelog](https://www.todoist.com/help/todoist/product-updates/2026-changelog-HD3jJAtLd)
- Foco Pomodoro/cronómetro con ruido blanco y Live Activity — [TidBITS](https://tidbits.com/2025/08/14/ticktick-provides-a-focused-daily-task-list-and-more/)
- Extraer tareas de foto de pizarra o PDF con revisión — [2026 changelog](https://www.todoist.com/help/todoist/product-updates/2026-changelog-HD3jJAtLd)
- Revisión matutina/vespertina por notificación — [2026 changelog](https://www.todoist.com/help/todoist/product-updates/2026-changelog-HD3jJAtLd)
- Racha con días libres, vacaciones y pausa — [Todoist Karma](https://todoist.com/help/articles/introduction-to-karma-OgWkWy)
- Descuento educativo 25 % en TickTick Premium (señal de mercado estudiantil) — [ticktick.com](https://ticktick.com/)
- Eventos del calendario del teléfono arriba de la lista de Hoy — [Tools and Toys](https://toolsandtoys.net/things-3-for-ios-apple-watch-and-mac/)

### Inferences
- Para Questly (Flutter, Android primero, Gemini gratis): «extraer tareas de foto/PDF de un sílabo» y «desglose con fechas por paso» serían diferenciadores frente a las tres, porque ninguna fecha cada paso automáticamente según lo leído.
- La alarma tipo «urgente» en Android requiere permiso de alarma exacta y full-screen intent; conviene opt-in por tarea, como hacen Todoist y TickTick.

### Gaps
- No se midió qué funciones usan de verdad los estudiantes (sin datos de uso públicos).
