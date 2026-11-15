# Feature Specification: Dinámica estilo Duolingo

**Feature Branch**: `007-dinamica-duolingo`

**Created**: 2026-11-13

**Status**: Implementado y probado en teléfono (2026-11-14)

**Input**: User description: "Aplicar la misma dinámica de Duolingo a la app para hacerla más dinámica, interactiva y moderna, sin cambiar su objetivo." Más la idea del audio: "al registrar un hábito, filtrarlo por prioridad (alta, media, baja) y que en el camino aparezcan de mayor a menor prioridad".

## Contexto

LifeQuest ya convertía tareas, hábitos y metas en un RPG, pero el progreso se veía en listas y tarjetas. Duolingo demuestra que un **camino visible**, **metas pequeñas con cofre**, **competencia semanal** y **una mascota que acompaña** sostienen el hábito de volver cada día. Esta fase toma esas mecánicas y las adapta al objetivo de LifeQuest (productividad real), sin copiar su contenido ni su arte.

## Decisiones

- **Un solo usuario (CLAUDE.md §1, §10).** No hay ranking social: la Liga compite contra **10 rivales simulados** por el servidor, deterministas por usuario y semana, que avanzan al ritmo de la división. La pantalla lo explica. Se descartaron de las referencias el muro de amigos y la suscripción de pago.
- **El servidor manda en la economía (§8).** Desafíos y Liga se calculan y cobran con funciones `SECURITY DEFINER` (`challenges_overview`, `claim_challenge`); cada cofre se cobra una sola vez y pasa por `_award`. Metas y premios son reglas **provisionales** en `game_rules` (`challenge_*`, `league_base_xp`).
- **Las tareas se completan en Foco (040).** El camino guía el orden pero no bloquea: cualquier tarea de hoy se puede empezar en Foco. Los hábitos sí siguen el orden por prioridad (idea del audio).
- **La mascota se llama Nevi** (decisión del usuario 2026-11-14) y es la voz de la app: guía el onboarding, firma recordatorios y avisos en primera persona y su cara es el ícono de las notificaciones.
- **Ético primero (§9).** Sin dark patterns: la racha rota se muestra con ánimo («tu récord sigue ahí»), nunca con culpa; las animaciones respetan «reducir movimiento» del sistema.
- **Una sola dependencia nueva: `audioplayers`.** Confeti dibujado a mano, vibración del sistema (`HapticFeedback`), imágenes WebP de la mascota (22 archivos, 847 KB) y 3 sonidos propios generados por síntesis (`assets/sounds/*.wav`, 84 KB, sin derechos de terceros).

## Requerimientos funcionales (propuestos para el documento de RF)

- **RF-124** Al crear un hábito el usuario elige su prioridad (alta, media, baja); el Camino de hábitos de hoy los ordena de mayor a menor prioridad y solo deja cumplir el primero pendiente. (`051_habit_priority.sql`)
- **RF-125** El usuario ve tres desafíos del día (ganar XP, completar tareas, terminar un ciclo de Mazmorra) con su progreso y un cofre que cobra Monedas al cumplirlos, una vez por día. (`052`)
- **RF-126** El usuario ve el Desafío del mes (cobrar 30 desafíos del día) y cobra su premio una vez por mes.
- **RF-127** El usuario compite cada semana en una Liga de 10 divisiones contra 10 rivales simulados; al cerrar la semana los 3 primeros suben y los 3 últimos bajan. La app indica que los rivales son simulados.
- **RF-128** El Inicio muestra «Tu camino de hoy»: lo hecho hoy, la tarea actual (con «EMPEZAR»), las tareas de hoy y el cofre diario como meta, en un zigzag uniforme.
- **RF-129** El Inicio muestra una barra fija con nivel, racha, Monedas y Constancia, y un banner con la meta actual y su avance (o una invitación a crear una).
- **RF-130** La mascota acompaña el camino con poses que se turnan, a color hasta el punto actual y en gris más adelante; celebra al completar el camino del día.
- **RF-131** La app celebra los logros: vibración al tocar y al ganar, confeti al recibir recompensas, pantalla de racha una vez al día y la mascota en la subida de nivel. Todo se desactiva si el sistema pide reducir el movimiento.
- **RF-132** Si la racha de un hábito se reinicia, la pantalla de Hábitos anima a retomarlo mostrando el récord.
- **RF-133** La app reproduce sonidos cortos al cumplir una tarea o hábito, al cobrar un cofre o desafío y al subir de nivel; el usuario los apaga en Configuración → Apariencia (encendidos por defecto).
- **RF-134** Nevi guía el onboarding (una pose y un globo por paso), firma los recordatorios del día y los avisos («Nevi: …», con tono de invitación) y su cara aparece en las notificaciones. (`053`, `055`)
- **RF-135** Los recordatorios llegan por push (Firebase Cloud Messaging) aunque la app esté cerrada; el servidor los envía cada 5 minutos según las mismas reglas y nunca duplica lo que ya mostró el teléfono. (`050`, `054`)
- **RF-136** La racha del Inicio cuenta días seguidos con al menos una actividad real (tarea, hábito cumplido, ciclo de Foco, paso guiado, proyecto o meta); si hoy aún no hay actividad sigue viva desde ayer. Premios y malos hábitos no cuentan. Se calcula, no se guarda. (`056`)
- **RF-137** El usuario desbloquea 12 logros (primera tarea, 10 y 50 tareas, primer hábito, rachas de 3, 7 y 30 días, 10 ciclos de Foco, 10 cofres, 10 desafíos, nivel 5 y ascenso de liga). El servidor los revisa tras cada actividad, paga su premio una sola vez y Nevi avisa; se ven en Perfil → Logros. La primera recompensa de cada día muestra la pantalla de racha con la racha diaria. (`057`)
- **RF-138** Los recordatorios de la noche (19:30 y 21:30) defienden la racha diaria del Inicio y no aparecen si hoy ya hubo alguna actividad real. (`058`)
- **RF-139** El Perfil muestra la racha diaria y un calendario del mes donde cada día se enciende según cuántas actividades reales hubo. (`059`)
- **RF-140** Si un día no hay actividad y el usuario tiene un Protector de racha guardado, esa noche se gasta solo y la racha diaria sigue viva (el día protegido no suma). Nevi lo cuenta en el resumen de la mañana. (`060`)
- **RF-141** Cada domingo a las 19:00 Nevi envía el resumen de la semana (XP, días con actividad, tareas, racha y mejora frente a la semana pasada); una semana sin actividad recibe ánimo, nunca culpa, y a quien lleva 2 semanas sin usar la app no se le escribe. (`061`)
- **RF-142** Al llegar a 7, 30, 100 y 365 días de racha la pantalla de racha celebra el hito con Nevi, confeti y sonido; los hitos de 7, 30 y 100 días dan su logro con Monedas («Semana de fuego», «Llama eterna», «Leyenda»). (`062`)
- **RF-143** En el Inicio, Nevi cambia de pose y mensaje según el día: saluda, corre si ya hay avances, avisa del cofre listo, celebra el camino completo y, de noche sin actividad, recuerda que la racha espera (sin culpa).
- **RF-144** El usuario elige su meta diaria de XP (30, 50 o 100) en Configuración; es la meta del desafío «Gana N XP» y la barra del Inicio muestra un anillo con la XP de hoy. (`063`)
- **RF-145** Al completar lo último pendiente del día, la app muestra el repaso del día (tareas, hábitos, XP, minutos de Foco y racha) y Nevi se despide hasta mañana; no reaparece al solo abrir la app.
- **RF-146** Nevi avisa al empezar la semana si el usuario subió, se mantuvo o bajó de división (con ánimo), y desde el miércoles, una vez por semana, cuando va entre los 3 primeros de la Liga. (`064`)
- **RF-147** El Perfil muestra una vitrina con los 3 logros más recientes y el conteo (p. ej. 3/13); tocarla abre Logros.
- **RF-148** Al terminar el Onboarding, Nevi muestra una guía de 3 pasos (el camino, la barra de arriba y el botón de ideas); se cierra tocando fuera y no vuelve a salir.

## Casos de uso (propuestos para el documento de UC)

- **UC-32 Cumplir el camino del día** (RF-128, RF-131): el usuario toca «EMPEZAR» en el nodo actual → elige las tareas en Foco → las completa con «Completar» → el camino marca lo hecho → con 3 tareas el cofre muestra «¡COBRAR!» → lo cobra y la mascota celebra.
- **UC-33 Cobrar desafíos** (RF-125, RF-126): el usuario abre Desafíos y Liga desde el Inicio → ve el progreso → toca cada cofre dorado → recibe Monedas y suma puntos al Desafío del mes.
- **UC-34 Revisar la Liga** (RF-127): el usuario abre la pestaña Liga → ve su división, su puesto, la zona de ascenso y descenso y cuántos días faltan; al empezar la semana siguiente ve si subió o bajó.
- **UC-35 Retomar una racha** (RF-132): tras romperse una racha, la tarjeta de ánimo invita a cumplir el hábito hoy.
- **UC-36 Consultar la racha diaria** (RF-136, RF-139): el usuario ve el 🔥 en la barra del Inicio → abre Perfil → ve «Racha de N días» y el calendario del mes con la intensidad de cada día → la primera recompensa del día muestra la pantalla de racha.
- **UC-37 Desbloquear un logro** (RF-137, RF-142, RF-147): el usuario completa una actividad → el servidor revisa los logros → si cumple uno, paga sus Monedas y Nevi avisa por push → el usuario lo ve en la vitrina del Perfil y en Logros; en los hitos de 7, 30, 100 y 365 días la pantalla de racha celebra.
- **UC-38 Proteger la racha con un Protector** (RF-140): el usuario compra un Protector en Recompensas → un día no registra actividad → esa noche el servidor gasta el Protector y la racha sigue → a la mañana siguiente Nevi lo cuenta en el resumen. Alterno: sin Protector guardado, la racha vuelve a 0 y el récord se conserva.
- **UC-39 Elegir la meta diaria de XP** (RF-144): el usuario abre Configuración → Meta diaria → elige 30, 50 o 100 XP → el anillo del Inicio y el desafío «Gana N XP» usan la nueva meta → al cumplirla abre su cofre en Desafíos.
- **UC-40 Recibir los avisos de Nevi** (RF-134, RF-135, RF-138, RF-141, RF-146): el servidor revisa cada 5 minutos y envía por push los recordatorios del día, el aviso de racha en riesgo (19:30 y 21:30, solo si hoy no hubo actividad), el resumen semanal (domingo 19:00) y los avisos de Liga (resultado el lunes, zona de ascenso desde el miércoles) → el usuario toca el aviso y entra a la app.
- **UC-41 Terminar el día** (RF-143, RF-145): el usuario completa lo último pendiente → al volver al Inicio aparece el repaso del día (tareas, hábitos, XP, minutos de Foco y racha) → toca «Hasta mañana» → Nevi queda celebrando en el banner.
- **UC-42 Primer ingreso** (RF-148): el usuario se registra → confirma su correo → inicia sesión → completa el Onboarding con Nevi → Nevi muestra la guía de 3 pasos (camino, barra de arriba, botón de ideas) → llega al Inicio. Alterno: toca fuera de la guía y la cierra.

## Archivos principales

- Servidor: `053_nevi_reminders.sql`, `054_push_tick.sql`, `055_nevi_notifications.sql` y la Edge Function `push-dispatch`; `supabase/migrations/052_challenges_league.sql` (+ `supabase/tests/052_challenges_league.test.mjs`), `051_habit_priority.sql`.
- App: `features/challenges/` (Desafíos y Liga), `features/home/presentation/widgets/task_path.dart`, `progress_card.dart` (`HomeStatusBar`), `home_link_card.dart` (`GoalBanner`), `core/widgets/questly/quest_path.dart` (`QuestPath`, `QuestPathNode`, `MascotPose`), `confetti.dart`, `reward_moment.dart`.
- Arte: `assets/images/mascota/mascota_<pose>_<izquierda|derecha>.webp` (11 poses × 2 lados).

## Fuera de alcance

- Muro de novedades de amigos y cualquier ranking contra personas reales (§10).
- Suscripción de pago (el freemium sigue como idea futura, §1).

## Criterios de aceptación (verificados en el teléfono el 2026-11-14 y 2026-11-15)

- Completar 3 tareas en Foco suma XP y Monedas, marca «3 tareas hechas hoy» en el camino y pone el cofre en «¡COBRAR!»; al cobrarlo da +15 Monedas y la mascota cambia a «celebrando».
- «Gana 30 XP» y «Completa 2 tareas» se cumplen, sus cofres se cobran una sola vez y el Desafío del mes pasa de 0/30 a 2/30.
- La Liga refleja la XP de la semana (de #11 a #8 con 45 XP).
- 2026-11-15, prueba de campo: anillo 20/50 y «Gana 50 XP» con la meta elegida, Liga #9, vitrina 2/13, calendario de racha, «¡Día completo!» al terminar la última tarea, registro nuevo con confirmación de correo, Onboarding y guía de Nevi.
- Nada se desborda con texto grande (1,3×) en pantallas de 360 dp (prueba automática).
- Pruebas: 228 comprobaciones SQL y 346 pruebas Flutter en verde.
