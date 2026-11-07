# Planificadores del día que actúan sobre el día real: Structured, Sunsama, Motion y Notion Calendar (estado a nov 2026)

> Fecha de la investigación: 2026-11-07. Las fuentes oficiales (App Store, centros de ayuda) se prefieren sobre los blogs. Muchas reseñas de 2026 son blogs de afiliados o de competidores (Morgen, Akiflow, Saner, Carly), y se marcan así. `help.sunsama.com` no respondió por DNS durante la consulta: lo de Sunsama viene de fragmentos de búsqueda de su ayuda y de reseñas.

## 1. ¿Cómo planifica el día cada app y qué hace cuando el plan se rompe (vencidas, arrastre, reprogramación)?

### Takeaway
Hay tres modelos: Structured es una **línea de tiempo manual**, con "Replan" de pago para reubicar lo que faltó. Sunsama hace **timeboxing guiado por un ritual**, con arrastre automático a medianoche y archivado tras varios días. Motion usa un **motor que reprograma solo y de forma continua**, con una bandeja "Resolve Issues" para lo vencido. Notion Calendar es **un calendario donde arrastras tareas de bases de Notion**, sin reprogramación propia.

### Cited Findings

**Structured (unorderly GmbH; iOS/iPadOS/watchOS/macOS, Android con menos funciones)**
- Gratis: línea de tiempo visual del día con arrastrar y soltar, más un Inbox para capturar ideas y ordenarlas después. También subtareas con notas, colores e iconos — [App Store](https://apps.apple.com/us/app/id1499198946)
- Pro: conectar calendarios y Recordatorios, tareas recurrentes y rutinas, planificación del día con IA, **"Replan" (reprograma automáticamente tareas perdidas u olvidadas)** y notificaciones personalizadas — [App Store](https://apps.apple.com/us/app/id1499198946)
- Recordatorios de planificación, incluido uno matutino para planificar y avisos de tareas vencidas (versión 4.4.8). Se ajustan en Ajustes > Notificaciones — [App Store, What's New](https://apps.apple.com/us/app/id1499198946)
- Inbox con acciones por deslizamiento (4.6.4, sep 2026) — [App Store](https://apps.apple.com/us/app/id1499198946)
- Precios Pro: mensual, anual o vitalicio. En la ficha de EE. UU. aparecen entre 2,99 y 7,99 USD al mes, entre 9,99 y 49,99 USD al año y 99,99 USD el vitalicio. Los precios cambian por país y la ficha no dice qué precio es de qué región — [App Store](https://apps.apple.com/us/app/id1499198946)
- **Energy Monitor** (registro de la energía diaria; lo usan centros de rehabilitación neerlandeses para pacientes con fatiga). Está en Android — [Structured Help (Android)](https://help.structured.app/en/articles/331714); [Basalt revalidatie, guía en PDF](https://www.basaltrevalidatie.nl/site/assets/files/13871/20250312_uitleg_gebruikers_structured_agenda_met_energiemonitor.pdf)
- Funciones listadas en Android: Energy Monitor, widgets, Structured AI (Pro), importación de calendario (Pro), sincronización con Structured Cloud, tareas de todo el día, Inbox, iconos, recurrentes y notificaciones personalizables. Según el artículo, "no todas las funciones de iOS están aún en Android". Replan y el temporizador de foco no aparecen en la lista de Android — [Structured Help](https://help.structured.app/en/articles/331714)
- Una ficha de terceros de agosto de 2026 dice que Replan y la importación de calendario son solo de iOS. Choca con la ayuda oficial, que lista la importación de calendario en Android — [resumen de búsqueda, fuente de terceros](https://appgoblin.info/apps/io.unorderly.structured)
- Una suscripción Pro comprada en Apple vale también en Android — [Structured Help](https://help.structured.app/en/articles/331714)

**Sunsama (web, escritorio, iOS, Android)**
- Las tareas sin completar **pasan solas a la lista del día siguiente a medianoche**. Las recurrentes también — [Sunsama Help: Task rollover](https://help.sunsama.com/docs/task-rollover-and-recurring-tasks-the-basics) (fragmento de búsqueda; la página no cargó)
- **Auto-archive**: archiva las tareas que se arrastraron varios días seguidos. El umbral se puede cambiar o apagar — mismo artículo de ayuda (fragmento)
- "Priority rollover": eliges qué niveles de prioridad se conservan de un día a otro; los demás se reinician — [Sunsama changelog](https://sunsama.canny.io/changelog) (fragmento)
- Existe una página de ayuda sobre **auto-rescheduling** de los bloques de timeboxing. No pude leer su contenido — [Sunsama Help: Auto rescheduling](https://help.sunsama.com/docs/usage-guides/timeboxing/auto-rescheduling)
- Flujo matutino según una reseña: traes las tareas de las herramientas conectadas, estimas el tiempo de cada una, comparas el total con las horas disponibles, las arrastras al calendario y empiezas. El tiempo se mide solo al iniciar una tarea — [Asian Efficiency, reseña 2026](https://www.asianefficiency.com/schedule-management/sunsama-review/)
- **Aviso de sobrecarga**: compara el tiempo estimado total con las horas disponibles. Ejemplo citado: "You're over-committed by 4 hours. What can you move to tomorrow?" — [Asian Efficiency](https://www.asianefficiency.com/schedule-management/sunsama-review/)
- La guía de planificación de Sunsama funciona **por reglas** (suma de tiempos, aviso de sobrecarga), no con IA, a diferencia de Motion o Reclaim — [Asian Efficiency](https://www.asianefficiency.com/schedule-management/sunsama-review/)
- Precio: 25 USD al mes en pago mensual o 20 USD al mes en pago anual (240 USD al año), con prueba de 14 días y sin plan gratis — [Asian Efficiency](https://www.asianefficiency.com/schedule-management/sunsama-review/). Otras fuentes dan 16/12 o 17 USD, así que hay contradicción — [Morgen, Sunsama pricing](https://www.morgen.so/fr/blog-posts/sunsama-pricing); [Carly, reseña](https://www.usecarly.com/blog/sunsama-review/)

**Motion (web, escritorio, iOS, Android)**
- Programa las tareas según plazos, duración y prioridad. Destaca "tu prioridad #1 en cada momento", usa tu tiempo real disponible y avisa cuando reservaste más de lo que cabe — [Motion, AI Calendar](https://www.usemotion.com/features/ai-calendar)
- Recalcula cuando cambian las cosas (reuniones que se alargan, emergencias) y reordena el día y la semana. Lo prioritario se queda en el calendario. Ante sobrecarga ofrece extender el plazo o delegar — [Motion, AI Calendar](https://www.usemotion.com/features/ai-calendar)
- Lo vencido va a la **"Resolve Issues Box"**: marca roja de exclamación, más las tareas movidas de día por restricciones. Una tarea vencida se reprograma en el siguiente hueco libre — [Motion Help: Resolve Issues Box](https://help.usemotion.com/product-and-feature-guides/calendar/tasks/understanding-the-resolve-issues-box)
- Opciones para resolver: "Do ASAP" (lo programa lo antes posible), extender el plazo o poner una fecha nueva — [Motion Help: AI Agenda](https://usemotion.com/help/time-management/ai-agenda/ai-agenda-how-to-guide)
- Con **"hard deadline"** puede programar fuera del horario laboral para cumplir el plazo — [Motion Help: Task types](https://help.usemotion.com/product-and-feature-guides/calendar/tasks/task-types-explained) (fragmento de búsqueda)
- Según un usuario citado, lo no terminado "se queda en el calendario hasta completarse" y se reacomoda en tiempo real — [Morgen, Motion review](https://www.morgen.so/blog-posts/motion-review) (blog de un competidor)
- Precio 2026: Pro AI cuesta 29 USD al mes en pago anual o 49 USD en mensual (individual), con 7.500 créditos de IA al mes. Business AI cuesta 39 o 69 USD, con 15.000 créditos. Los créditos extra se cobran aparte. No hay plan gratis y la prueba de 7 días pide tarjeta — [Morgen, Motion review](https://www.morgen.so/blog-posts/motion-review). Otra fuente habla de "AI Employees" de 49 a 599 USD al mes — [Lindy, Motion pricing](https://www.lindy.ai/blog/motion-app-pricing) (no verificado en la web oficial)
- Críticas: caro, rígido ("auto-scheduling can feel rigid"), hay que pasar todo a Motion para que funcione bien, y se ha llenado de funciones extra (docs, wikis, sheets, notetaker). En Trustpilot tiene 1,5/5 con 25 reseñas — [Morgen](https://www.morgen.so/blog-posts/motion-review); resumen de búsqueda de [Lindy](https://www.lindy.ai/blog/motion-app-pricing)

**Notion Calendar (ex-Cron; gratis)**
- Es gratis y no gestiona tareas por sí mismo. El timeboxing consiste en arrastrar páginas de una base de Notion con propiedad de fecha desde la barra lateral a una franja horaria. Al soltarla, **se actualiza la fecha en la base de Notion** — [Notion Help: Getting started with Notion Calendar](https://www.notion.com/help/guides/getting-started-with-notion-calendar); [Zapier](https://zapier.com/blog/notion-calendar.md)
- La barra lateral muestra tareas sin programar y se filtra por estado o por fecha — [Simone Smerilli](https://simonesmerilli.com/writing/notion-calendar-database-integration); [itsourcecode, guía 2026](https://itsourcecode.com/notion/how-to-use-notion-calendar/)
- **No reprograma ni arrastra lo no hecho por sí mismo** (no encontré ninguna función de ese tipo en las fuentes)
- Notion Mail **cierra el 22 de septiembre de 2026** — [Notion Help: Schedule meetings with Notion Mail](https://www.notion.com/help/schedule-meetings-with-notion-mail)

### Inferences
- La reacción ante el plan roto va de menos a más automática. Notion Calendar no hace nada. Sunsama arrastra a medianoche y archiva tras N días. Structured tiene Replan, que se pulsa a mano (Pro). Motion reprograma de forma continua. El archivado de Sunsama y la bandeja "Resolve Issues" de Motion evitan que lo vencido se acumule sin fin: son dos formas de **cerrar el bucle de lo no hecho sin culpa**.
- Los avisos de sobrecarga de Sunsama (estimado contra disponible) son pura aritmética y no necesitan IA. Encajan con el "lo determinista va por reglas" de Questly.

### Gaps
- No pude leer el contenido de la ayuda de Sunsama sobre auto-rescheduling ni el umbral por defecto del auto-archive (help.sunsama.com no resolvió).
- Falta confirmar si Replan de Structured está en Android en noviembre de 2026; las fuentes se contradicen.
- No encontré datos sobre los modos de Motion "ASAP / soft deadline", la división en bloques ni el horario laboral, salvo los fragmentos citados.

## 2. ¿Qué rituales usan (planificación diaria, cierre) y cómo los guían?

### Takeaway
Sunsama es la referencia del **ritual guiado**: planificación matutina en cinco pasos y cierre (shutdown) a una hora fija, con repaso, arrastre deliberado y reflexión. Structured empuja el ritual con **recordatorios** (planificación matutina, vencidas). Motion sustituye el ritual por automatización. Notion Calendar no tiene rituales.

### Cited Findings
- Planificación de Sunsama en cinco pasos: **Process** (repasar lo de ayer), **Plan** (elegir lo de hoy), **Prioritize** (decidir qué puede esperar), **Prepare** (cerrar el plan) y **Publish** (compartir el plan en Slack). Lema: "Start each day right. End each day fulfilled." — [Sunsama, Daily planning and shutdown](https://www.sunsama.com/features/daily-planning-and-shutdown)
- Cierre de Sunsama: repasar lo completado, pasar lo no terminado a mañana, reflexionar opcionalmente sobre lo que fue bien y cerrar la app. La reseñista lo resume así: "Everything I didn't finish today is already scheduled for tomorrow." — [Asian Efficiency](https://www.asianefficiency.com/schedule-management/sunsama-review/)
- El cierre puede **interrumpirte a una hora fijada** para dejar de trabajar a tiempo, y genera "daily highlights" con resúmenes opcionales de IA — resúmenes de búsqueda de [Carly](https://www.usecarly.com/blog/sunsama-review/) y [Saner](https://blog.saner.ai/sunsama-reviews) (reseñas de terceros)
- Sunsama también tiene revisión semanal ligada a objetivos semanales, Pomodoro y analíticas — [Dupple](https://dupple.com/reviews/sunsama); [Asian Efficiency](https://www.asianefficiency.com/schedule-management/sunsama-review/)
- En móvil, los rituales de planificación y cierre "están más pulidos" según el changelog, y en 2025 se reconstruyó la app móvil. Aun así, las reseñas dicen que el escritorio es mejor para el ritual completo y que no hay modo offline — [Sunsama changelog](https://sunsama.canny.io/changelog); [Asian Efficiency](https://www.asianefficiency.com/schedule-management/sunsama-review/)
- Structured: recordatorio de "morning planning" y avisos de vencidas (4.4.8) — [App Store](https://apps.apple.com/us/app/id1499198946)
- Motion: la "AI Agenda" y la Resolve Issues Box hacen de repaso de problemas, pero no hay un ritual guiado — [Motion Help: AI Agenda](https://usemotion.com/help/time-management/ai-agenda/ai-agenda-how-to-guide)

### Inferences
- El ritual de Sunsama traducido a Questly: una mañana de 3 pasos (repasar lo arrastrado de ayer → elegir lo de hoy contra horas disponibles → confirmar) y un cierre a hora configurable (marcar hecho, mover a mañana o soltar, una línea de reflexión). Ambos pueden dar XP y racha sin dark patterns, porque premian planificar y cerrar, no abrir la app.
- "Publish to Slack" no aplica a un usuario único estudiante.

### Gaps
- No encontré documentación oficial con los pasos exactos del shutdown de Sunsama, porque la página oficial no los detalla.

## 3. Integraciones del sistema móvil (widgets, Live Activities, notificaciones con acciones, Siri/Assistant, calendario, foco, inbox)

### Takeaway
Structured es la app con más integración del sistema (Live Activities, widgets interactivos, Control Center, Siri AI, Apple Watch, temporizador de foco), pero casi todo es de iOS. Notion Calendar tiene widgets en Android 8+ e iOS, con una app móvil recortada. Sunsama y Motion se apoyan en integraciones con herramientas (correo, Slack, gestores), no en el sistema del teléfono.

### Cited Findings
**Structured**
- Gratis: temporizador Pomodoro, **Live Activities** y **widgets interactivos**, más sincronización entre iPhone, iPad, Apple Watch y Mac — [App Store](https://apps.apple.com/us/app/id1499198946)
- Focus Timer rediseñado e **Intervals** (Pro), un temporizador de foco y descanso para tareas largas (4.5.0, jun 2026) — [App Store](https://apps.apple.com/us/app/id1499198946)
- **Siri AI** crea y actualiza tareas (4.6.x, requiere iOS 27 y región compatible) — [App Store](https://apps.apple.com/us/app/id1499198946)
- Desde el **Control Center** se añaden tareas, se planifican tareas de todo el día o se envían cosas al inbox, y se abre el asistente "Plan with Structured AI" — resumen de búsqueda de la [ficha de App Store](https://apps.apple.com/app/apple-store/id1499198946)
- Guía para añadir widgets y correcciones de Live Activity (4.5.5–4.6.0) — [App Store](https://apps.apple.com/us/app/id1499198946)
- Accesibilidad: VoiceOver, Voice Control y una fuente para dislexia — [App Store](https://apps.apple.com/us/app/id1499198946)
- Android: widgets sí, sincronización con Structured Cloud sí, importación de calendario (Pro) — [Structured Help](https://help.structured.app/en/articles/331714)

**Sunsama**
- Más de 20 integraciones: Gmail, Outlook, Slack, Google Calendar, Asana, Notion, Todoist, Jira, Linear, Trello, ClickUp y GitHub. Funcionan como bandeja de entrada desde correo y otras herramientas — [Asian Efficiency](https://www.asianefficiency.com/schedule-management/sunsama-review/)
- Hay app de iOS y Android, "sólida para planificar por la mañana en movimiento". La reseña no menciona widgets — [Asian Efficiency](https://www.asianefficiency.com/schedule-management/sunsama-review/)

**Motion**
- Apps de iOS, Android, escritorio y web (Pro AI) — [Morgen](https://www.morgen.so/blog-posts/motion-review)
- La app móvil admite notificaciones push (nota de producto) — resumen de búsqueda de [Motion Help](https://www.usemotion.com/help/time-management)
- Se integra con Zoom, Google Meet, Gmail y Outlook, y tiene AI Meeting Notetaker — [Motion, AI Calendar](https://www.usemotion.com/features/ai-calendar)

**Notion Calendar**
- Plataformas: web, Mac, Windows, iOS y Android — [Notion Help: Notion Calendar apps](https://www.notion.com/help/notion-calendar-apps)
- **Widget de pantalla de inicio**: iOS 14+ y **Android 8+**. **Widget de pantalla de bloqueo**: iOS 16+. Se configuran los días mostrados, si salen los eventos de todo el día, si se ocultan los títulos en la pantalla de bloqueo y qué calendarios se excluyen — [Notion Help](https://www.notion.com/help/notion-calendar-apps)
- Limitaciones en móvil: no busca, no edita eventos (salvo los creados en iOS por el organizador), no crea snippets de disponibilidad, no conecta servicios, no puede ser la app de calendario por defecto, solo tiene vistas de 1, 2 o 3 días y no crea eventos de OOO ni Focus — [Notion Help](https://www.notion.com/help/notion-calendar-apps)
- Comparte disponibilidad para agendar reuniones — [workmanagementhub, guía 2026](https://workmanagementhub.com/notion-calendar-setup-guide-2026/)
- Según una guía de mediados de 2026, la sincronización bidireccional nativa con iCloud no estaba disponible — resumen de búsqueda de [itsourcecode](https://itsourcecode.com/notion/how-to-use-notion-calendar/) (sin verificar)

### Inferences
- Para Android, el equivalente a las Live Activities de Structured es una **notificación persistente (foreground service)** con el bloque o temporizador en curso y acciones Hecho / +5 min. El equivalente al widget interactivo es un widget de "siguiente bloque" con botón Hecho, que Questly ya tiene en la v2.5.0.
- Notion Calendar muestra que un widget de agenda configurable (días, ocultar títulos en la pantalla de bloqueo) es valioso incluso en una app gratuita.

### Gaps
- No encontré documentación de widgets, Live Activities ni notificaciones con acciones para Sunsama ni Motion.
- No hay datos de integración con Google Assistant o Gemini en Android para ninguna de las cuatro.
- No encontré nada oficial sobre las notificaciones de inicio o fin de tarea de Notion Calendar, ni de Structured en Android.

## 4. Funciones de IA (desglose, planificación) y si usan documentos o contexto del usuario

### Takeaway
Structured usa IA "ligera" sobre lo que escribes (borradores del día, lenguaje natural, subtareas sugeridas, imágenes adjuntas). Motion es la más agresiva: calendario con IA, docs, notetaker y créditos que se cobran aparte. Sunsama casi no usa IA, salvo resúmenes opcionales. Notion Calendar no tiene IA propia confirmada.

### Cited Findings
- Structured: planificación del día con IA (Pro). **Structured AI acepta varias imágenes adjuntas** (4.4.1), así que parte de lo que el usuario sube, no de sus documentos guardados — [App Store](https://apps.apple.com/us/app/id1499198946)
- Structured: creación de tareas en **lenguaje natural** (beta; detecta fecha, hora, duración y repetición en inglés, alemán, francés y **español**), Suggested Subtasks, Smart Task Icons 2.0, Color Prediction y Task Suggestions (betas). **La pestaña de IA se puede ocultar** y desde la 4.5.5 hay control sobre las funciones inteligentes — [App Store](https://apps.apple.com/us/app/id1499198946)
- Structured: la ficha de la tienda vende que la IA "drafts a day in seconds" a partir de una entrada en lenguaje natural — resumen de búsqueda de la [ficha de App Store](https://apps.apple.com/us/app/id1499198946)
- Motion: AI chat, meeting notetaker, AI docs y AI calendar. El chat, el notetaker, los docs y las acciones sobre tareas consumen créditos de IA — [Morgen](https://www.morgen.so/blog-posts/motion-review). Su notetaker y sus docs muestran que la IA de Motion trabaja con contenido de reuniones y documentos dentro de Motion, aunque la página no detalla qué contexto usa el scheduler — [Motion, AI Calendar](https://www.usemotion.com/features/ai-calendar)
- Motion: "Project and Task ETAs", un sistema predictivo que estima cuándo terminarán proyectos y tareas — [Motion blog: ETAs](https://usemotion.com/blog/etas)
- Sunsama: la planificación es por reglas, no por IA; los "highlights" de cierre tienen resúmenes opcionales de IA — [Asian Efficiency](https://www.asianefficiency.com/schedule-management/sunsama-review/); resumen de búsqueda de [Carly](https://www.usecarly.com/blog/sunsama-review/)
- Notion Calendar: "as of mid 2026 does not have built-in AI" según una guía. Otra fuente afirma que tiene resúmenes de reuniones con IA, pero nadie más lo corrobora — [itsourcecode](https://itsourcecode.com/notion/how-to-use-notion-calendar/); en contra, [aiindigo](https://aiindigo.com/tool/notion-calendar). La IA vive en Notion AI y sus agentes, que se conectan a calendario y correo — [Simone Smerilli](https://www.simonesmerilli.com/business/notion-ai-calendar-email-connections)

### Inferences
- La IA de Structured (lenguaje natural → tarea con fecha y duración, subtareas sugeridas, opción de apagar la IA) coincide casi punto por punto con lo que Questly ya hace con `LocalParser` + Gemini apagado por defecto. Valida el enfoque.
- El modelo de créditos de Motion y su precio (29–49 USD) son lo contrario de lo que quiere un estudiante. El valor que se puede copiar gratis es el algoritmo de reprogramación (prioridad → plazo → huecos libres), que es determinista.

### Gaps
- No encontré documentación oficial sobre qué datos envía Structured AI a su proveedor ni qué modelo usa.
- No pude confirmar si el auto-scheduler de Motion usa el contenido de documentos o reuniones para decidir.

## 5. ¿Qué ideas encajan en una app Android gratuita, para estudiantes y con gamificación ligera (Questly)?

### Takeaway
Conviene copiar lo determinista y barato: línea de tiempo del día, Replan con un toque, arrastre automático con archivado tras N días, aviso de sobrecarga (estimado contra disponible), ritual de mañana y de cierre con recordatorio, notificación persistente del bloque actual, widget de siguiente bloque con Hecho, y Energy Monitor como dato ligero. Hay que evitar la reprogramación continua tipo Motion, las integraciones de equipo y la IA con créditos.

### Cited Findings
- Replan de Structured (reprograma lo perdido) es Pro y no está claro que exista en Android: es un hueco en Android que Questly puede ocupar gratis — [App Store](https://apps.apple.com/us/app/id1499198946); [Structured Help](https://help.structured.app/en/articles/331714)
- El arrastre a medianoche y el auto-archive de Sunsama evitan que la lista crezca sin fin — [Sunsama Help](https://help.sunsama.com/docs/task-rollover-and-recurring-tasks-the-basics) (fragmento)
- El aviso "over-committed by X hours" de Sunsama — [Asian Efficiency](https://www.asianefficiency.com/schedule-management/sunsama-review/)
- Notion Calendar ofrece widgets en Android 8+ sin coste — [Notion Help](https://www.notion.com/help/notion-calendar-apps)
- El Energy Monitor de Structured se usa en rehabilitación para gestionar la fatiga — [Basalt PDF](https://www.basaltrevalidatie.nl/site/assets/files/13871/20250312_uitleg_gebruikers_structured_agenda_met_energiemonitor.pdf)
- Las críticas a Motion por rigidez y por exigir migrar todo — [Morgen](https://www.morgen.so/blog-posts/motion-review)

### Inferences (propuestas para Questly)
- **Replan gratis y por reglas**: un botón "Reacomodar lo que quedó", que mueve lo vencido de hoy al siguiente hueco libre del día (respetando el calendario del teléfono) o a mañana. Encaja con `DayPlanner`.
- **Arrastre + "soltar sin culpa"**: lo no hecho pasa a mañana. Tras 3 arrastres seguidos, se pregunta "¿mañana, algún día o soltar?" en lugar de archivar en silencio. Tono de invitación (§7).
- **Ritual de mañana (≤ 60 s)**: repasar lo arrastrado → elegir 3 tareas → ver la suma de minutos contra el tiempo libre del día, con aviso de sobrecarga. Pequeña XP por planificar.
- **Cierre del día** a hora configurable: marcar hecho, mover o soltar, y una línea "¿qué salió bien?". Cuenta para la racha de "días cerrados".
- **Notificaciones al inicio y al final del bloque** con acciones (Empezar foco / Hecho / +10 min), y **notificación persistente** durante Foco como equivalente Android de las Live Activities.
- **Widget** de siguiente bloque con Hecho (ya existe en la v2.5.0) y quizá una variante de "línea del día".
- **Energía opcional** (baja/media/alta) en el ritual matutino. El planificador por reglas propone tareas más ligeras si es baja, como en la propuesta de RPGenie «cansado / poco tiempo».
- **No copiar**: la reprogramación continua de Motion (rígida y opaca), los créditos de IA, la publicación en Slack ni las integraciones de equipo.

### Gaps
- No hay datos de uso o retención que demuestren qué ritual funciona mejor con estudiantes. Las propuestas son inferencias de diseño.
