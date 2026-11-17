# Questly: todas las funcionalidades y cómo se conectan

> Referencia completa de lo que hace la app (rama `Remaked`, v2.9.0, 16 de noviembre de 2026). Sirve para recordar todo lo que tiene Questly, explicarlo sin olvidar nada y ver qué pieza alimenta a cuál.
> El nombre visible es **Questly**; el repositorio y el paquete siguen llamándose LifeQuest.

---

## 1. Qué es Questly en una frase

**Questly es un asistente de productividad para el celular que convierte lo que tienes en mente en un día que avanza:** capturas una idea en segundos, la app la ordena, la pone en tu agenda, te avisa a tiempo, mide el tiempo que trabajas y al final del día te ayuda a cerrar lo pendiente. El progreso (XP, nivel y racha) refleja lo que cumpliste. No es un juego de fantasía.

### La regla que guía todo

> **Cada función debe actuar en tu día real, no solo guardar texto.**

El tutor rechazó la primera versión (un RPG con reino, tienda, jefes y NPCs) porque crear una tarea solo guardaba una fila y había muchas pantallas que solo mostraban información. Por eso cada función de Questly hace al menos una de estas cinco cosas:

| # | Pregunta | Ejemplo en Questly |
|---|---|---|
| 1 | **Tiempo:** ¿pasa algo a una hora concreta? | El aviso de una tarea suena 10 min antes |
| 2 | **Medida:** ¿mide algo real y te lo devuelve? | Foco suma los minutos reales a la tarea |
| 3 | **Sistema:** ¿usa el teléfono? | Notificación con botones, widget, voz, compartir |
| 4 | **Siguiente paso:** ¿te deja la próxima acción lista? | «Dividir en pasos», «Empezar foco» |
| 5 | **Reacción:** ¿responde cuando el plan se rompe? | «Replanificar lo atrasado», proyecto que pasa a 🔴 |

### Principios de producto

1. Cada pantalla tiene una acción que cambia el día; nada solo informa.
2. Capturar cuesta un toque; ordenar lo hace la app.
3. El progreso se ve, pero nunca castiga.
4. Se lee con una mano en 3 segundos.
5. **Lo determinista va por reglas, la IA solo interpreta el lenguaje.** Las fechas, los huecos de la agenda, el orden y la XP se calculan con reglas probadas. La IA (Gemini, capa gratis) solo entiende frases, propone pasos y lee recursos, y viene apagada.
6. **Gratis:** nada puede generar un cobro.
7. **Tono de invitación, nunca de culpa:** «Tu racha de 12 días te está esperando», nunca «¡Vas a perder tu racha!».

---

## 2. El ciclo completo de un día

<!-- diagrama:ciclo -->

```
 CAPTURAR ──► ORDENAR ──► AGENDAR ──► AVISAR ──► HACER ──► MEDIR ──► CERRAR EL DÍA
 Anotar,      Asistente:  Agenda de   Notifica-  Foco      Minutos   Revisión:
 voz,         fecha, hora, Hoy,       ción con   (Pomodoro reales,   mañana / otra
 compartir,   área, pasos, «Armar mi  Hecha /    con       XP, nivel, semana / soltar
 Bandeja      recordatorio día»       Posponer   pasos)    racha
     ▲                                                                  │
     └──────────── lo que no se decidió vuelve a la Bandeja ◄───────────┘
```

**Así se recorre en la práctica:**

1. **Capturas** «llamar a mamá mañana 7pm» escribiendo, dictando o compartiendo desde otra app.
2. El **asistente lo interpreta**: título «Llamar a mamá», mañana a las 19:00, con aviso. Como es algo puntual con hora, lo marca como **recordatorio**. Te muestra la propuesta en chips que puedes quitar o cambiar.
3. Queda en la **agenda** de mañana y el teléfono **avisa** a su hora con los botones **Hecha** y **Posponer 1 h**, aunque la app esté cerrada.
4. Para una tarea más grande («Preparar el parcial de cálculo»), «**Dividir en pasos**» propone de 3 a 7 pasos con fechas repartidas hasta la fecha límite.
5. **Empezar foco** abre un ciclo de 25 min con esa tarea; marcas los pasos mientras avanzas. Foco **mide los minutos reales** y da XP por cada ciclo.
6. Por la noche, el **cierre del día** te muestra lo que hiciste y, por cada pendiente, te pide decidir: «Mañana», «A la otra semana» o «Soltar».
7. Lo cumplido suma **XP**, sube tu **nivel** y mantiene tu **racha**.

---

## 3. Navegación

<!-- diagrama:navegacion -->

**Barra inferior de 5 pestañas:**

| Pestaña | Para qué | Abre además |
|---|---|---|
| **Hoy** | Tu día: qué hacer ahora, hábitos, agenda, cierre del día | Anotar, Armar mi día, Replanificar, Tu semana |
| **Tareas** | Todas las tareas abiertas agrupadas por cuándo tocan | Proyectos y metas, Crear, Editar, Recursos |
| **Hábitos** | Hábitos buenos para cumplir y malos para evitar | Crear hábito, Aviso, Resumen del mes |
| **Foco** | Sesión de concentración (Pomodoro) | Mochila de tareas, pasos, descansos, resumen |
| **Tú** | Tu progreso, identidad y áreas | Tu semana, Estadísticas, Ajustes, Avisos, Ayuda |

**Accesos que no son pestañas:**

- **Botón flotante «+»** en cualquier pestaña excepto Foco: abre **Crear** (Anotar) con la mínima fricción.
- **Barra «Escribe una tarea…»** y **micrófono** arriba en Hoy.
- **Bandeja**: desde Crear («A la Bandeja»), desde la revisión del día («Decidir») y desde lo compartido.
- **Notificaciones del teléfono**: al tocarlas se abre la pantalla de lo que avisan (tarea, hábito, proyecto o perfil), también con la app cerrada.
- **Widget** en la pantalla de inicio del teléfono.
- Al volver a una pestaña, sus datos se recargan solos.

---

## 4. Funcionalidades una por una

Cada ficha dice: **qué hace**, **cómo se usa**, **con qué se conecta** y **qué hay detrás** (la RPC o migración de Supabase y el código).

### 4.1 Cuenta y sesión

- **Qué hace:** registro con nombre de usuario, correo y contraseña (con aceptación de términos), verificación por correo («Revisa tu correo») e inicio de sesión.
- **Seguridad:** la sesión (token de acceso y de renovación) se guarda **cifrada** en el Keystore de Android (`flutter_secure_storage`). Las copias de seguridad de Android están desactivadas para la app, solo se acepta HTTPS con certificados del sistema y el APK de release va ofuscado (R8) y firmado con una llave propia. Ver el informe `docs/seguridad/informe-seguridad.md` (hallazgos H-01 a H-08, OWASP Mobile Top 10).
- **Al cerrar sesión:** se borran los avisos programados y se vacía el widget.
- **Detrás:** Supabase Auth, `AuthBloc` global, `core/storage/secure_session_storage.dart`.
- **Nota:** los botones «Google» y «Apple» solo muestran «estará disponible pronto».

### 4.2 Bienvenida (Onboarding)

- **Qué hace:** se muestra en el primer inicio de sesión, en 5 pasos con «Saltar» y «Atrás»:
  1. **Bienvenida:** «Tarea → XP → Nivel», lo que cumples se convierte en progreso visible.
  2. **Identidad:** «¿Qué quieres lograr este año?» (opcional).
  3. **Primera área:** «¿Qué área de tu vida quieres hacer crecer?» (Salud, Estudio, Creatividad, Relaciones… o una propia; opcional).
  4. **Dificultad:** fácil, normal o difícil (cambia cuánta XP ganas). Después solo se cambia en Ajustes.
  5. **Asistente con IA:** encenderlo ya o dejarlo para después, con su aviso de privacidad.
- **Con qué se conecta:** la identidad y las áreas aparecen en **Tú**; la dificultad multiplica la XP de todo; la IA habilita las funciones inteligentes de **Crear** y **Foco**.
- **Detrás:** `onboarding_overview`, `complete_onboarding` (015, marca `profiles.onboarded_at`). Mientras no se complete, el router lleva siempre al Onboarding.

### 4.3 Hoy (la pestaña principal)

La hoja del día, con diseño de «calendario de taco»: el número del día en rojo y la fecha.

| Sección | Qué muestra | Acción |
|---|---|---|
| **Encabezado** | Fecha, cuántas tareas quedan, racha | — |
| **Barra de captura** | «Escribe una tarea…» + micrófono | Abre Crear (escribiendo o dictando) |
| **Progreso del día** | Tareas, hábitos y minutos de foco de hoy | — |
| **Ahora** | El **bloque de la agenda en curso** o, si no hay, la **tarea más urgente** (vencida o que vence en menos de 24 h → prioridad → fecha) | **Empezar foco** |
| **Tu meta te espera** (nuevo) | Una meta sin avance en 7 días y su siguiente tarea | **Empezar foco** con esa tarea, o **Ver meta** si no tiene tareas |
| **Hábitos de hoy** | Chips de los hábitos buenos que tocan hoy, con contador hechos/total | Tocar el chip lo marca como hecho |
| **Agenda** | Línea de tiempo con los **eventos del calendario del teléfono**, las **tareas con hora**, los **recordatorios** y los **hábitos con hora** (nuevo). Plegada muestra lo próximo; «Ver toda la agenda» la abre | Marcar un recordatorio o un hábito, **Mover** una tarea de hora, **Replanificar** si algo quedó atrás |
| **Sin hora** | «N tareas sin hora» | **Armar mi día** |
| **Cierra el día** (desde las 19:00) | Invitación a revisar lo pendiente | **Cerrar el día** |
| **Conectar calendario** | Invitación a leer el calendario del teléfono, antes de pedir el permiso | **Conectar** |

- **Con qué se conecta:** con casi todo. Lee tareas, hábitos, metas, el calendario del teléfono y la XP; abre Foco, Crear, el Asistente y la Revisión; cada cambio reprograma los avisos y actualiza el widget.
- **Detrás:** `home_dashboard` (001/036/038) y `day_agenda` (032/038/046).

### 4.4 Crear (Anotar): una sola hoja para todo

Es la puerta de entrada de casi todo lo que el usuario crea. Se abre con el «+», la barra de Hoy, el micrófono o al compartir desde otra app.

**Cómo funciona:**

1. Eliges el tipo (**Tarea**, **Proyecto** o **Meta**) y escribes o dictas una frase en lenguaje normal.
2. El asistente la **interpreta** y muestra una **vista previa en chips**: fecha, hora, duración, aviso, repetición, prioridad y **área**. Cada chip se quita con su X.
3. Confirmas, o mandas el texto **a la Bandeja** si aún no es algo por hacer.

**Lo que entiende el intérprete por reglas** (`LocalParser`, funciona sin internet ni IA):

| Escribes | Entiende |
|---|---|
| «hoy», «mañana», «el lunes», «el 15» | Fecha |
| «7pm», «18:30» | Hora (si ya pasó hoy, la pone mañana) |
| «en 20 min» | Dentro de 20 minutos |
| «cada día», «cada lunes», «de lunes a viernes», «cada mes el 15» | Repetición |
| «30 min», «1 h» | Duración del bloque |
| «avísame 10 min antes» | Aviso |
| «urgente» | Prioridad alta |

**Lo que decide solo:**

- **Tarea o recordatorio:** si es algo puntual (llamar, pagar, enviar…) o dura 5 min o menos, y además tiene hora, lo trata como **recordatorio**. Un recordatorio suena a su hora, se marca con «Hecho» en la agenda de Hoy, **no da XP** y no aparece en Tareas ni en Foco. Se corrige con el selector **Tarea / Recordatorio**.
- **Área sugerida (nuevo):** si el título nombra un área («Salud: correr») o comparte al menos 2 palabras con tareas anteriores de esa área, propone esa área en un chip. Tocarlo la cambia y su X la quita. Si hay empate o nada claro, no propone ninguna.

**Otras acciones en la hoja:**

- **Dividir en pasos:** propone de 3 a 7 pasos con fechas repartidas (ver §4.5).
- **Recursos:** adjuntar enlaces, fotos, PDF o notas antes de crear (ver §4.8).
- **Crear y empezar foco:** crea la tarea y abre Foco con ella.
- **Usar el formulario:** el formulario completo, para quien prefiere campos.
- **Meta:** con la IA, escribe la ficha S.M.A.R.T. y los primeros pasos; si no, se completa a mano.

- **Detrás:** `CaptureBloc`, `InterpretCapture`, `LocalParser`, `AreaSuggester`, `SaveCapture`; crea con `create_task` (010/032/038), `create_project`, `create_goal`; la Bandeja con `capture_thought`.

### 4.5 El asistente: reglas que arman tu día y una IA opcional

<!-- diagrama:asistente -->

**Reglas (siempre activas, sin IA, en `features/assistant/domain`, con tests):**

| Función | Qué hace |
|---|---|
| **Armar mi día** (`planDay`) | Llena los huecos libres de hoy (jornada de 8:00 a 22:00, en tramos de 15 min) esquivando los eventos del calendario y los bloques ya puestos. Orden: vencidas → urgencia/prioridad → fecha más próxima. Sin duración, una tarea cuenta como 30 min. |
| **Replanificar** (`replan`) | Lo atrasado (un bloque que ya pasó sin hacerse o una tarea vencida sin hora) va al siguiente hueco de hoy o de mañana. |
| **Repartir fechas** (`spreadDates`) | Reparte los pasos de una tarea de forma uniforme desde mañana hasta su fecha límite (sin fecha límite, uno por día). |
| **Pasos por plantilla** (`StepTemplates`) | Sin IA, propone pasos según el verbo del título: estudiar, preparar, escribir, pagar… o una plantilla genérica. |
| **Guía de descanso** (`FocusGuide`) | En Foco, sugiere qué sigue durante el descanso. |

Todas muestran una **vista previa**: no cambian nada hasta que tocas **Aceptar**. Al aceptar, se guarda cada bloque, se recarga Hoy y se reprograman los avisos.

**IA (Gemini, capa gratuita; Edge Function `assistant`):**

- **Apagada por defecto.** Se enciende en el Onboarding o en Ajustes, con un aviso de privacidad: en la capa gratuita Google puede usar los textos.
- **Tope de 40 llamadas al día** por usuario (`consume_ai_call`, 033). Sin cupo o si falla, todo sigue con las reglas y la app avisa.
- **Solo envía** lo que escribiste, el título y, al dividir en pasos, los recursos de esa tarea.
- **Qué hace:**
  - `parse`: entiende frases más libres que las reglas.
  - `breakdown`: propone pasos y lee fotos, PDF, notas y enlaces de la tarea.
  - Escribe la ficha S.M.A.R.T. de una meta.
  - `recall`: hace de 1 a 3 preguntas de repaso en Foco.
- La respuesta de la IA nunca se usa sin validar: `sanitize.ts` la limpia y comprueba.

### 4.6 Tareas

- **Qué muestra:** las tareas abiertas agrupadas en **Para hoy** (incluye lo vencido), **Después** y **Sin fecha**, con la XP en juego. Debajo de cada tarea se ven su repetición, sus minutos de foco medidos y sus pasos.
- **Acciones:**
  - **Ya la hice** o deslizar: completa la tarea y da la XP. Hay **5 segundos para deshacer** y, si se deshace, no se toca el servidor.
  - **Empezar foco:** arranca 30 min con un ciclo de 25 directamente con esa tarea.
  - **Nueva tarea:** abre Crear.
  - **Menú «⋯»:** **Editar** (título, prioridad, fecha, hora, duración, aviso y repetición; no recalcula la XP), **Recursos**, **Quitar la hora**, **Renombrar** y **Borrar** (lo completado no se borra).
  - **Pasos:** añadir y quitar pasos (subtareas).
  - **Proyectos:** abre Proyectos y metas.
- **Repetición real:** al completar una tarea que se repite, el servidor crea la siguiente ocurrencia en la misma transacción, en tu hora local.
- **XP por reglas, de 10 a 40 por tarea:** base 10, +10 si el título tiene 5 palabras o más, +10 si la prioridad es alta o +5 si es media, +10 si va vinculada a una meta o +5 a un proyecto. Se multiplica por la dificultad. El usuario no la edita y editar la tarea no la cambia, para que no se pueda inflar. Completar una tarea en menos de 2 minutos desde que se creó da la XP mínima.
- **Detrás:** `missions_overview`, `create_task`, `complete_task`, `update_task` (034), `rename_task`/`delete_task` (028), `schedule_task`/`snooze_task` (032); el orden de creación lo fija 041.

### 4.7 Proyectos y metas (P.A.R.A.)

Se abre desde Tareas («Proyectos»). La regla es simple: **lo grande, dividido en tareas.**

```
Meta (meses) ─┬─ Proyecto (semanas) ── Tarea ── Paso
              └─ Tarea (vinculada directo a la meta)
```

- **Proyectos:** tienen fecha de fin y su lista de tareas. Se completan con «Completar proyecto», que da 120 XP.
  - **Urgencia automática** 🟢🟡🔴: compara el ritmo necesario (trabajo que falta ÷ días que quedan) con tu ritmo real (tareas terminadas en los últimos 14 días ÷ 14). Si el necesario es más de 1,5 veces el real, la urgencia es alta 🔴; si es más de 1,2 veces, media 🟡; si no, baja 🟢. Todo se calcula en el teléfono y en el servidor, sin IA.
  - **Aviso de proyecto atrasado:** el teléfono avisa a las 9:00 del día en que el proyecto pasaría a 🔴 si no avanzas. Si avanzas, se recalcula (042).
- **Metas S.M.A.R.T.:** título más las 5 preguntas (específica, medible, alcanzable, relevante y con fecha). Muestran su porcentaje según las tareas y proyectos vinculados. Si una meta lleva 7 días sin avance, **Hoy** la propone (046).
- **Áreas:** agrupan tareas, proyectos, metas y hábitos (máximo 6, editables en Tú). Un proyecto sin área muestra «Sin vincular».
- **Acciones:** «¿Qué quieres añadir?» (tarea, proyecto, meta o recurso), **Archivar**, **Borrar** (lo vinculado queda suelto; lo completado no se borra, 040), **Recursos** de cada proyecto y meta, y la sección **Archivo**.
- **Detrás:** `stage_overview` (013/031), `create_project`, `create_goal` (014), `complete_project`, `archive_item`, `delete_item` (040).

### 4.8 Recursos (adjuntos)

- **Qué hace:** una tarea, un proyecto o una meta puede guardar **enlaces**, **fotos** (cámara o galería), **PDF** de hasta 10 MB y **notas**.
- **Cómo se usa:** se adjuntan en Crear (como chips, se guardan al crear) o desde «Recursos» en el menú de una tarea, un proyecto o una meta. Se abren con una URL firmada temporal y se quitan con 5 s para deshacer.
- **Por qué actúa:** con la IA encendida, **«Dividir en pasos» lee los recursos**: por ejemplo, la foto del temario se convierte en pasos de estudio. En Foco, las notas sirven de repaso.
- **Privacidad:** los archivos van a un bucket **privado** de Supabase Storage, en una carpeta por usuario y con políticas de acceso.
- **Detrás:** `core/resources` (`ResourceRepository`, `ResourcesBloc`), `core/widgets/resources_sheet.dart`, migración 045 (`attach_resource`, bucket `resources`).

### 4.9 Hábitos

- **Hábitos buenos** (para cumplir):
  - Frecuencia diaria o en días concretos de la semana.
  - Un registro por día con **«Hecho»**, que da 10 XP.
  - **Racha** de días seguidos y **récord**.
  - **Versión mínima** opcional («leer 1 página»): se muestra en la fila para que hacer lo mínimo también cuente.
  - **Aviso con hora:** suena con un botón **«Hecho»** en la notificación y ahora **aparece en la agenda de Hoy** (046).
- **Hábitos malos** (por evitar): se registra cada vez que pasa (varias veces al día), con gravedad leve, media o grave. «Sin recaídas» se muestra cuando no hay registros.
- **Resumen:** días con hábitos cumplidos este mes, hábitos completados, XP obtenida y registros de hoy.
- **Rachas justas:** cada día corre una tarea que pone en cero las rachas falladas. Al romperse, hay **48 h** para salvarla y el récord se conserva.
- **Menú:** poner, cambiar o quitar el aviso; renombrar; borrar.
- **Detrás:** `habits_overview` (011/034/039), `create_habit` (039, versión mínima), `complete_habit`, `register_bad_habit`, `set_habit_reminder` (034), `break_missed_streaks` (diaria).

### 4.10 Foco (Deep Work + Pomodoro)

Siempre en **modo oscuro**, sin navegación extra y respetando la reducción de movimiento del sistema.

<!-- diagrama:foco -->

**Antes de empezar:**

- **En un toque:** «Empezar foco» desde Hoy o Tareas arranca 30 min con un ciclo de 25 y esa tarea.
- **Preparar a mano:** «Elige qué harás y cuánto tiempo»: **duración total** en pasos de 30 min, **duración del ciclo** de 25, 30 o 45 min y la **mochila** de tareas (máximo 5).
- **Tu ruta:** el mapa de ciclos y descansos, y «Terminas a las HH:MM».
- **Repaso de 1 minuto:** si la tarea tiene notas, «La última vez en…» y, con la IA, de 1 a 3 preguntas («¿Puedes responder sin mirar?») antes de «Ver mis notas».
- **Dónde lo dejaste:** la nota que dejaste la última vez en esa tarea.

**Durante el ciclo:**

- Temporizador con «Ciclo N de M», **meta del ciclo** (el siguiente paso) y **barra de nivel** que muestra «+N XP» al ganar.
- **Pasos:** se marcan con «Hecho» y una **prueba opcional** (nota o foto: «Lo que lograste o dónde te trabaste»). Con «Añadir paso» se agregan más. **Marcar el último paso completa la tarea.**
- **Anotar distracción:** lo que te vino a la cabeza va a la **Bandeja** sin salir del ciclo.
- Pausar, añadir o quitar 30 min, o terminar antes **sin perder lo ganado**.
- Mientras dura la sesión se silencian los avisos que no son críticos.

**Descansos:** 5 min el corto y 15 min el largo cada 4 ciclos, configurables en Ajustes. «Saltar descanso». La guía de descanso dice qué sigue. El fin de ciclo y el de descanso suenan como **alertas de sesión**.

**Al terminar (resumen):**

- Lo terminado, la XP ganada, los ciclos y los minutos.
- La **semana comparada** con la anterior.
- **«Dónde lo dejé»** en cada tarea sin terminar (la app propone «Sigue: <siguiente paso>»).
- **«Agendar para mañana»** lo que quedó pendiente, con selector de hora.
- Cuántas distracciones mandaste a la Bandeja.

**XP:** 10 por ciclo completado. Los minutos medidos se suman a cada tarea (`focus_minutes`) y se ven en Tareas, en Estadísticas y en la revisión.

- **Detrás:** `dungeon_overview` (012/017/037/045), `start_dungeon`, `complete_dungeon_cycle`, `end_dungeon`, `set_resume_note` (045). El temporizador vive en `FocusBloc`. (Las RPC conservan el nombre antiguo «dungeon».)

### 4.11 Bandeja (Brain Dump)

- **Qué hace:** saca de tu cabeza todo lo pendiente; decides después.
- **Entradas:** «Capturar» en la Bandeja, «A la Bandeja» en Crear, lo **compartido desde otra app**, las **distracciones** de Foco y el texto que no es una tarea.
- **Decidir** cada idea con el diagnóstico G.T.D. (reglas, sin IA):
  1. ¿Es accionable? Si no, se guarda como referencia o «algún día».
  2. ¿Es un paso o varios? Uno es una tarea; varios, un proyecto (semanas) o una meta (meses).
  3. ¿Se hace en 2 minutos? Si es así, la app sugiere hacerla ya.
  4. ¿Eres la persona correcta? Si no, es una tarea delegada («¿a quién?»).
  5. ¿Tiene tiempo específico? Si lo tiene, se le pone fecha u hora; si no, va a la lista de próximas.
- Cada idea se puede **archivar**, **devolver a la bandeja** o **borrar**.
- **Por qué actúa:** el cierre del día te recuerda «N notas sin decidir» con un botón «Decidir», así nada se acumula en silencio.
- **Detrás:** `brain_dump_overview`, `capture_thought`, `file_thought`, `convert_thought`, `delete_thought` (023).

### 4.12 Cierra el día / Tu semana (revisión)

- **Cuándo:** con un aviso diario a las **21:00**, con la fila «Cierra el día» de Hoy desde las 19:00, desde «Revisar semana» en Estadísticas o desde **Tú → Tu semana**.
- **Qué muestra:**
  - **Esta semana:** tareas hechas, minutos de foco y hábitos cumplidos.
  - **Lo que hiciste (nuevo):** la bitácora de la semana plegada (tareas, hábitos, foco y metas con su XP). Reemplaza la antigua pantalla Historial.
  - **N notas sin decidir en la Bandeja**, con el botón **Decidir**.
  - **Pendiente:** cada tarea vencida o de esta semana con **Mañana**, **A la otra semana** o **Soltar** (pide confirmación: «Decidir no hacerla también es avanzar»).
- **Por qué actúa:** evita el pensamiento todo-o-nada. Lo pendiente se decide en un minuto en lugar de acumularse.
- **Detrás:** `weekly_review` (034/044), `postpone_task` (034/039), `delete_task`; la bitácora sale de `journal_overview` (020) y se compone en `app/` con `JournalLog`.

### 4.13 Estadísticas

- **Qué muestra:** los últimos 7 días frente a los 7 anteriores (XP, tareas, minutos de foco y racha con su récord), **XP por día** (barras), **XP por área** y **hábitos más constantes** en 30 días.
- **«Qué puedes hacer» (nuevo):** 3 observaciones por reglas, siempre en tono de invitación. Cada una con su botón si aplica:
  - «Esta semana aún no hay XP: una tarea pequeña basta para arrancar.» → **Armar mi día**
  - «Ganaste N XP más que la semana pasada.» → **Revisar semana**
  - «Tu racha de N días te está esperando.» → **Ir a Hábitos**
- **Detrás:** `stats_overview` (025), `StatsBoard.observations`.

### 4.14 Avisos

**Dos sistemas que trabajan juntos:**

**a) Notificaciones del teléfono** (locales, sin servidor de push):

| Aviso | Cuándo | Botones |
|---|---|---|
| Tarea con hora | N minutos antes del bloque | **Hecha** · **Posponer 1 h** |
| Recordatorio | A su hora | **Hecha** · **Posponer 1 h** |
| Hábito con hora | A su hora | **Hecho** |
| Cierre del día | Todos los días a las 21:00 | Abre la revisión |
| Proyecto que se atrasa | A las 9:00 del día en que pasaría a 🔴 | Abre Proyectos |
| Fin de ciclo o descanso de Foco | Al terminar | Alerta de sesión |

- Los botones funcionan **con la app cerrada**: un proceso en segundo plano inicia Supabase con la sesión guardada y llama a `complete_task`, `snooze_task` o `complete_habit`.
- Tocar un aviso **abre su pantalla**.
- Los avisos se sincronizan al iniciar sesión, al volver a la app y al cambiar tareas o la agenda. Al cerrar sesión se borran.
- Respetan la **ventana de silencio** y el **límite diario** de Ajustes.

**b) Centro de avisos** (Tú → Notificaciones): «Lo importante de hoy, sin ruido».

- Cada aviso se genera una sola vez por evento (clave única).
- Cada uno lleva su botón **Abrir** hacia Hábitos, Proyectos, Tareas o Tú.
- **Marcar N como leídos**, o «Todo en calma» cuando no hay nada.
- Niveles: ▲ Crítico · ● Importante · ○ Informativo, siempre con símbolo y texto, nunca solo color.

- **Detrás:** feature `reminders` (`SyncReminders`), `app/reminder_actions.dart`, `sync_reminders` (032/042), `notifications_overview` y `mark_notifications_read` (029/043).

### 4.15 Tú (perfil)

- **Qué muestra:** nivel, barra de XP, **tasa de finalización** y racha; **Tu identidad** («¿Qué quieres lograr este año?», editable) y tus **áreas** con su nivel propio (crear, renombrar y eliminar; máximo 6).
- **Accesos rápidos:** **Tu semana**, **Estadísticas** y **Ajustes**.
- **Cuenta:** Notificaciones (centro de avisos), Ayuda (preguntas frecuentes y buscador) y Apariencia.
- **Detrás:** `profile_overview` (002/009).

### 4.16 Ajustes

| Grupo | Opciones |
|---|---|
| **Dificultad** | Fácil (XP ×1,2) · Normal (×1) · Difícil (×0,85) |
| **Asistente con IA** | Encender o apagar, con aviso de privacidad («¿Activar la IA?») |
| **Avisos** | Límite diario (sin límite por defecto), **ventana de silencio** (desde–hasta) y si los críticos pueden sonar dentro de ella |
| **Descansos del foco** | Descanso corto, descanso largo y cada cuántos ciclos |
| **Apariencia** | Tema claro / oscuro / del sistema y tamaño del texto |
| **Cuenta** | Cerrar sesión (con confirmación) |

- **Detrás:** `settings_overview` y un update directo de `game_master_settings` con checks de rango (016/033). La apariencia se guarda en el teléfono (`AppearanceBloc`, `shared_preferences`).

### 4.17 Integración con el teléfono

| Función | Qué hace | Detrás |
|---|---|---|
| **Voz** | Micrófono en Hoy y en Crear: dictas, y al terminar la frase se interpreta sola, en el idioma del teléfono | `speech_to_text`, `VoiceInput` |
| **Calendario** | Lee los eventos de hoy y mañana (con permiso explicado antes de pedirlo). Se ven en la agenda y «Armar mi día» los esquiva. Sin permiso todo funciona igual. No escribe en el calendario | `device_calendar_plus`, `core/calendar` |
| **Compartir a Questly** | Un texto o enlace compartido desde Chrome, WhatsApp, etc. abre «Guardar lo compartido», con la Bandeja como acción principal. Si no hay sesión, espera a que la haya. Se corta a 500 caracteres | `receive_sharing_intent`, `app/share_intake.dart` |
| **Widget de inicio** | Las próximas 3 tareas de hoy; «✓» la completa en segundo plano. Se actualiza cada vez que cambia Hoy y se vacía al cerrar sesión | `home_widget`, `QuestlyWidgetProvider.kt`, `app/home_widget_sync.dart` |
| **Notificaciones con acción** | Ver §4.14 | `flutter_local_notifications`, `app/background_boot.dart` |

---

## 5. El progreso: XP, nivel y racha

Questly conserva un **juego ligero** y nada más: XP, nivel y racha.

| Qué haces | XP |
|---|---|
| Completar una tarea | 10–40 según sus reglas (§4.6) |
| Completar un proyecto | 120 |
| Cumplir un hábito bueno | 10 |
| Terminar un ciclo de Foco | 10 |
| Recordatorio | 0 (no es trabajo) |

- **Nivel:** subir del nivel *n* al siguiente cuesta **100 × n^1,5** XP (nivel 1 → 100 XP, nivel 4 → 800 XP).
- **Dificultad:** multiplica la XP (×1,2 / ×1 / ×0,85).
- **Áreas:** la XP de una tarea o un hábito vinculado sube también el nivel de su área, que no tiene tope.
- **Racha:** días seguidos cumpliendo un hábito bueno; se guarda el récord y hay 48 h para salvarla.
- **Anti-trampa:** **el teléfono nunca escribe la XP.** Todo cobro pasa por funciones del servidor (`SECURITY DEFINER`) que, en una sola transacción, validan que la tarea sea tuya y siga abierta, aplican la dificultad, actualizan tus estadísticas y tu área y dejan la fila en la bitácora. Es como en un juego en línea: ves tu oro, pero solo el servidor lo cambia.
- **Nunca castiga:** no hay «muerte» ni pérdida de progreso. La vida (HP) quedó como regla interna sin pantalla.

---

## 6. Cómo se conectan las funciones entre sí

<!-- diagrama:conexiones -->

### 6.1 Mapa de dependencias

| Esta función… | …alimenta o usa a… | Cómo |
|---|---|---|
| **Crear** | Tareas, Proyectos, Metas, Bandeja, Recursos, Avisos | Guarda con fecha, hora, aviso, repetición y área; adjunta recursos; reprograma avisos |
| **Asistente (reglas)** | Hoy, Tareas, Pasos | Pone horas (`schedule_task`), reparte fechas a los pasos |
| **Asistente (IA)** | Crear, Foco, Metas | Interpreta frases, divide en pasos leyendo recursos, escribe S.M.A.R.T. y hace preguntas de repaso |
| **Calendario del teléfono** | Hoy, Armar mi día | Los eventos ocupan huecos de la agenda |
| **Hoy** | Foco, Crear, Revisión, Widget, Avisos | Empezar foco, capturar, cerrar el día; cada cambio actualiza el widget y los avisos |
| **Tareas** | Foco, Proyectos, Metas, XP | Completar da XP y avanza el proyecto y la meta; la repetición crea la siguiente |
| **Proyectos** | Avisos, Hoy | La urgencia 🔴 programa un aviso; el progreso alimenta la meta |
| **Metas** | Hoy | Una meta quieta 7 días aparece en Hoy con su siguiente tarea |
| **Recursos** | IA, Foco | La IA los lee al dividir; las notas sirven de repaso y prueba de paso |
| **Hábitos** | Hoy, Avisos, Estadísticas, Racha | Chips y agenda en Hoy; aviso con «Hecho»; XP y racha |
| **Foco** | Tareas, Bandeja, XP, Estadísticas, Revisión | Mide minutos, completa pasos y tareas, manda distracciones a la Bandeja, agenda para mañana |
| **Bandeja** | Tareas, Proyectos, Metas | El diagnóstico G.T.D. la convierte en lo que corresponde |
| **Cierre del día** | Tareas, Bandeja, Bitácora | Mueve o suelta lo pendiente, invita a decidir notas, muestra lo hecho |
| **Estadísticas** | Hoy, Hábitos, Revisión | Cada observación lleva a su acción |
| **Ajustes** | XP, Avisos, Foco, IA | Dificultad, silencio y límite, descansos, interruptor de IA |
| **Avisos** | Tareas, Hábitos, Proyectos, Revisión | Botones que actúan con la app cerrada; tocar abre la pantalla |
| **Widget** | Tareas | Completar desde la pantalla de inicio |
| **Compartir** | Bandeja, Crear | Lo que llega de otra app entra a la captura |

### 6.2 Cuatro recorridos de ejemplo

**A. Del pensamiento a la acción (2 minutos)**
Compartes un enlace desde Chrome → «Guardar lo compartido» → **Bandeja** → por la noche el **cierre del día** dice «1 nota sin decidir» → **Decidir** → es una tarea de un paso con fecha → queda en **Tareas** con aviso.

**B. Una tarea grande que da miedo**
«Preparar parcial de cálculo el 20» en **Crear** → adjuntas la **foto del temario** → **Dividir en pasos**: la IA lee la foto y propone 5 pasos con fechas hasta el 20 → al día siguiente, **Hoy** muestra el primero en «Ahora» → **Empezar foco** → marcas el paso con una foto de tus apuntes como **prueba** → cierras con **«Dónde lo dejé»** → la próxima vez Foco te hace **preguntas de repaso**.

**C. Un día que se rompe**
A las 10:00 tenías un bloque que no hiciste → Hoy marca la agenda con **Replanificar** → el asistente lo mueve al siguiente hueco libre, esquivando tu reunión del calendario → **Aceptar** → el aviso se reprograma solo.

**D. Un hábito que se olvida**
Creas «Leer» con aviso a las 21:15 y versión mínima «1 página» → aparece en la **agenda de Hoy** → a las 21:15 suena → tocas **Hecho** en la notificación sin abrir la app → +10 XP y la **racha** sube → **Estadísticas** te muestra tu hábito más constante con «Ir a Hábitos».

---

## 7. Privacidad, ética y accesibilidad

- **Privacidad:** a la IA solo va lo que escribiste o adjuntaste a esa tarea, con aviso y con la IA apagada por defecto. El cálculo de urgencia, el plan del día y la XP nunca salen a la IA. Los archivos están en un bucket privado. **Toda tabla tiene RLS**: cada persona solo ve sus filas (probado con dos usuarios en los tests SQL).
- **Ética:** sin dark patterns, sin avisos para «volver» sin motivo, sin castigos de golpe, sin apuestas, sin rankings ni red social (un solo usuario). Lo que una notificación ignorada no se repite.
- **Accesibilidad (WCAG 2.1 AA):** contraste de 4,5:1, zonas táctiles de 44 px o más, `Semantics` en los botones de icono, el color nunca va solo (símbolo y texto), respeto a la reducción de movimiento y prueba con el texto al 130 % en 360 dp.
- **Deshacer en lugar de confirmar:** completar una tarea y quitar un recurso tienen 5 s para deshacer; solo «Soltar», «Borrar» y «Cerrar sesión» piden confirmación.

---

## 8. Cómo está construida (resumen técnico)

| Capa | Tecnología |
|---|---|
| App | **Flutter / Dart**, Android primero |
| Arquitectura | Clean Architecture por features: `domain` (Dart puro) → `data` → `presentation`, con **Bloc**, **get_it**, **go_router**, **fpdart** (`Either`) y **equatable** |
| Backend | **Supabase**: Auth, PostgreSQL 15+ con RLS, funciones `plpgsql SECURITY DEFINER` expuestas por RPC, Storage y Edge Functions |
| IA | Gemini (capa gratuita) detrás de la Edge Function `assistant`, con tope diario |
| Diseño | Sistema minimal sobrio (zinc + índigo, fuente Inter), tokens en `lib/core/theme/questly_theme.dart` |
| Pruebas | `flutter test` (322 pruebas), pruebas SQL sobre Postgres real (`supabase/tests`, una por migración, con RLS entre dos usuarios) y test de la limpieza de la IA |

**Features del código:** `auth`, `onboarding`, `home` (Hoy), `assistant`, `tasks`, `stage` (Proyectos y metas), `habits`, `focus`, `brain_dump` (Bandeja), `review` (Tu semana), `journal` (bitácora), `stats`, `notifications`, `reminders`, `profile` (Tú), `settings`. Lo compartido vive en `core/` (recursos, calendario, errores, widgets) y la composición entre features en `app/` (rutas, captura, avisos, widget, compartir).

**Migraciones:** de `001_home.sql` a `046_agenda_habits_goals.sql`, en orden.

---

## 9. Lo que se quitó en el rework (y por qué)

| Se quitó | Por qué |
|---|---|
| Ambientación de fantasía: reino, héroe, Mazmorra, Taverna, NPCs, jefes, RPGenie | El tutor pidió una app útil, no un RPG |
| Tienda, Monedas, Mercado negro, Hotel, Refugio, Elixir, Cofre del día | Economía de fantasía que no actuaba en el día |
| Boss Fight, HP visible, «debilitado» | Castigo visible; se cambió por progreso que nunca castiga |
| Inventario, logros visibles y títulos | Solo mostraban |
| Vision Board | Solo guardaba |
| Pantalla Historial | Solo mostraba; ahora vive dentro de «Tu semana» |

Los nombres nuevos son **Hoy · Tareas · Hábitos · Foco · Tú**, Bandeja (antes Brain Dump), Áreas (skills), Proyectos y metas (Stage · P.A.R.A.), Ajustes (Game Master) y Tu semana (Historial).

---

## 10. Pendientes conocidos antes de la entrega

**Para que todo funcione en el teléfono:**

- [ ] Aplicar en Supabase las migraciones **037 a 046**, en orden. Sin ellas fallan Foco que guía (037), recordatorios (038), «Mañana» y la versión mínima de hábitos (039), borrar (040), orden de pasos (041), aviso de proyectos (042), «Abrir» en avisos (043), notas en la revisión (044), recursos (045) y hábitos y metas en Hoy (046).
- [ ] Redesplegar la Edge Function `assistant`.
- [ ] Probar en un teléfono Android: dictar, Hecha y Posponer, repetir, Foco, Armar mi día con un evento, Replanificar, dividir, compartir desde Chrome, widget, y modo claro y oscuro.
- [ ] Generar el APK de release (`flutter build apk --release`).

**Detalles visibles que quedan del diseño anterior:**

- [ ] Ajustes → «Contenido de la Tienda» todavía aparece (solo dice «próximamente»): conviene quitarlo.
- [ ] El Onboarding dice «Bienvenido a LifeQuest»: debería decir Questly.
- [ ] Botones «Google» y «Apple» en el inicio de sesión que aún no funcionan.
- [ ] Ayuda: preguntas frecuentes fijas; revisar que no prometan tiempos de respuesta.

**Atajos aceptados (`shortcut:` en el código):**

- «Armar mi día» no esquiva los hábitos con hora (son un instante).
- Al borrar una tarea, un proyecto o una meta, sus archivos quedan en Storage (las filas sí se borran).
- Un recordatorio de otro día solo se ve ese día en Hoy.
- Las tablas de la economía antigua que aún leen funciones vivas siguen en la base.

**Documentación:** actualizar los RF y UC del Project de claude.ai con `docs/rf-uc-rework.md` (RF-117 a RF-137 y UC-32 a UC-44).
