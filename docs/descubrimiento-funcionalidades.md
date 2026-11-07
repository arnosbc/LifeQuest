# Descubrimiento de funcionalidades (2026-11-07)

Revisión de Questly con tres skills del proyecto: `ux-interaction` (qué falla al usarla), `product-discovery` (Cagan: valor, usabilidad, factibilidad, viabilidad) y `brainstorm-ideas-existing` (trío PM · Diseño · Ingeniería, 5 ideas priorizadas). Sirve para decidir qué rediseñar **antes** de escribir código. Lo visual se pule después con `impeccable`, `design-taste-frontend` y `emil-design-eng`.

## 1. Resultado que buscamos

> **Que el usuario termine más de lo que se propuso hoy, escribiendo y decidiendo lo mínimo.**

Es la promesa del rework («un asistente que actúa») y lo que pidió el tutor. Métricas para probar con usuarios:
- % de tareas creadas que se terminan en su fecha.
- Toques y caracteres escritos desde abrir la app hasta empezar a trabajar.
- Días por semana con al menos un hábito marcado.

## 2. Lo que falla hoy (auditoría `ux-interaction`)

| Pantalla | Problema | Pregunta de la skill que falla | Estado |
|---|---|---|---|
| Tareas | El check terminaba la tarea; en Foco el mismo check sirve para elegirla. Hubo una tarea terminada por error, con XP cobrada | 2 (significado) · 3 (accidente) | ✅ Arreglado (deslizar / «Ya la hice» + deshacer 5 s) |
| Tareas, Foco | El usuario escribe los pasos; la IA solo los proponía en «Anotar» | 4 (trabajo del usuario) | ✅ Arreglado («Dividir en pasos» en el formulario y en Foco) |
| Foco | «¿Qué vas a terminar en el primer ciclo?» repetía la tarea y sus pasos | 4 | ✅ Arreglado (la meta es el siguiente paso) |
| Hoy | Agenda + «Sin hora» + hábitos en listas: los hábitos quedaban dos pantallas abajo | 5 (día cargado) | ✅ Arreglado (hábitos en chips, agenda plegada) |
| **Todo el asistente** | La IA viene **apagada** y solo se enciende en Ajustes. Sin ella, «Dividir en pasos» y la lectura de frases no existen: la promesa principal es invisible | 4 | ⏳ Pendiente (idea 1) |
| **Crear** | Hay dos caminos con poderes distintos: «Anotar» (frase, IA, recordatorio, Bandeja) y «Nueva tarea» (formulario largo) | 2 · 4 | ⏳ Pendiente (idea 2) |
| Foco · preparar | Elegir duración total, ciclo y tareas con casillas antes de empezar: tres decisiones antes del primer minuto | 1 (acción principal) · 4 | ⏳ Pendiente (idea 3) |
| Hábitos | Solo se marcan; el aviso está escondido en el menú «⋯» y no tienen hora ni versión mínima | 4 · 5 | ⏳ Pendiente (idea 4) |
| Historial, Estadísticas | Pantallas de lectura; «Revisar semana» es la única acción | 1 | ⏳ Pendiente (idea 5) |
| Ayuda | «Respondemos en menos de 2 h» y preguntas frecuentes fijas: es una promesa falsa | — (honestidad) | ⏳ Quitar el texto o cumplirlo |
| Proyectos y metas | Jerga S.M.A.R.T. y P.A.R.A. visible para el usuario | 2 | ⏳ Bajo impacto, después |

## 3. Árbol de oportunidades

```
Terminar más de lo que se propuso hoy, decidiendo lo mínimo
├─ O1 · «No sé por dónde empezar» (tarea grande, sin pasos)
│    ├─ Pasos propuestos siempre, con o sin IA ........ idea 1
│    └─ Foco en un toque desde la tarea ............... idea 3
├─ O2 · «Anotar me cuesta» (dos formularios, campos vacíos)
│    └─ Un solo camino: frase → propuesta → aceptar ... idea 2
├─ O3 · «Los hábitos se me olvidan»
│    └─ Hábitos con hora y versión mínima en el día ... idea 4
└─ O4 · «No veo si avanzo / se me acumula»
     └─ Cierre del día que actúa ...................... idea 5
```

## 4. Lluvia de ideas (trío)

**PM (valor y objetivo)**
1. El asistente encendido desde el Onboarding, con su aviso de privacidad y el tope diario a la vista.
2. «Cierre del día» de 1 minuto a la hora que elija el usuario: lo hecho y, por cada pendiente, «Mañana», «Otro día» o «Soltar».
3. La racha cuenta días con al menos *una* cosa hecha (tarea, hábito o foco), no un hábito concreto: protege contra el todo o nada.
4. Plantillas de rutinas («Mañana», «Estudiar», «Cerrar el día») que crean hábitos y bloques de una vez.
5. Quitar de la vista lo que no actúa: Historial y Estadísticas dentro de una sola pantalla «Tu semana».

**Diseño (uso y gusto)**
6. **Una sola hoja de crear**: escribes la frase y ves la propuesta (fecha, hora, pasos, recordatorio) en chips editables; el formulario largo queda como «Editar detalles».
7. **Foco en un toque**: «Empezar foco» en cualquier tarea arranca 25 min con esa tarea y su primer paso; la duración se cambia durante la sesión.
8. Hábito con «versión de 2 minutos» («leer 1 página»): marcar la mínima también cuenta.
9. Hábitos con hora entran a la agenda de Hoy como bloques cortos y suenan.
10. Al terminar una tarea con pasos pendientes, preguntar «¿Terminaste también estos?» en vez de dejarlos colgando.

**Ingeniería (datos y factibilidad)**
11. **Pasos por reglas cuando no hay IA**: plantillas por verbo («estudiar», «preparar», «escribir», «mudarse»…) en `domain`, con tests; la IA solo mejora la propuesta.
12. Estimar la duración de una tarea con el tiempo real medido en Foco de tareas parecidas (mismo área o mismas palabras), para que «Armar mi día» acierte.
13. Hora sugerida para cada hábito según cuándo se marcó las últimas 2 semanas.
14. El widget de inicio muestra los hábitos de hoy además de las tareas.
15. Detectar tareas que se posponen 3 veces y proponer dividirlas o soltarlas.

## 5. Las 5 elegidas

Criterios: alineación con el resultado, impacto, esfuerzo y si se diferencia de una lista de tareas común.

### Idea 1 · Pasos siempre propuestos (reglas + IA, asistente en el Onboarding) — ideas 1 + 11
Toda tarea nueva sin pasos recibe una propuesta: primero por reglas (siempre, gratis, sin red) y, si la IA está encendida, la mejora Gemini. El Onboarding pregunta si se enciende el asistente.
- **Por qué:** es el fallo de fondo de las dos quejas sobre los pasos; hoy la función existe pero casi nadie la ve.
- **Riesgos:** valor medio (¿las plantillas por reglas son útiles o genéricas?); factibilidad baja de riesgo (Dart puro + tests); viabilidad: la IA se queda en la capa gratis con su tope.
- **Supuestos a validar:** 1) con 20 plantillas por verbo se cubre al menos la mitad de las tareas reales; 2) el usuario acepta la propuesta sin editarla más de la mitad de las veces.
- **Prueba barata:** tomar 30 títulos de tareas reales (tuyos y del tutor) y ver cuántos encajan en una plantilla.

### Idea 2 · Un solo camino para crear — idea 6
«Anotar» pasa a ser la única hoja de crear (botón «+» y barra de Hoy). El formulario actual queda como «Editar detalles» dentro de la propuesta.
- **Por qué:** quita la contradicción de dos caminos con poderes distintos y baja los toques.
- **Riesgos:** usabilidad media (quien prefiere formularios debe encontrar «Editar detalles»); factibilidad baja (ya existen las dos piezas).
- **Supuestos:** crear desde una frase es más rápido que el formulario en 4 de cada 5 tareas.
- **Prueba:** cronometrar a 5 personas creando 5 tareas de cada forma.

### Idea 3 · Foco en un toque — idea 7
«Empezar foco» en una tarea arranca directamente un ciclo de 25 min con esa tarea y su primer paso. La preparación (duración, más tareas) queda como «Ajustar» opcional.
- **Por qué:** hoy hay tres decisiones antes del primer minuto; el Modelo de Fogg pide quitar fricción justo antes de actuar.
- **Riesgos:** valor alto, usabilidad baja de riesgo; factibilidad: `start_dungeon` ya recibe tareas y duración.
- **Supuestos:** la mayoría empieza el foco con una sola tarea.
- **Prueba:** contar en la BD cuántas sesiones tienen una sola tarea.

### Idea 4 · Hábitos que suenan y caben en el día — ideas 8 + 9
Cada hábito bueno tiene hora opcional (sale en la agenda de Hoy y suena con «Hecho» en la notificación) y una versión mínima que también cuenta.
- **Por qué:** «Cada función debe actuar en el día real»; hoy un hábito solo es una casilla.
- **Riesgos:** valor alto (bucle señal → rutina → recompensa); factibilidad media (se reutilizan los avisos de tareas, 034 ya tiene `reminder_time`); viabilidad: hay que actualizar el RF de hábitos.
- **Supuestos:** con hora y aviso se marcan más días por semana.
- **Prueba:** activar el aviso en 2 hábitos tuyos durante una semana y comparar con la anterior.

### Idea 5 · Cierre del día que actúa — idea 2 (absorbe la 5)
A la hora elegida (por defecto 21:00), un aviso abre una hoja de 1 minuto: lo hecho hoy (con la XP) y cada pendiente con «Mañana», «Otro día» o «Soltar». Historial y Estadísticas quedan dentro de «Tu semana».
- **Por qué:** convierte las pantallas de lectura en una acción diaria y evita que se acumulen pendientes (pensamiento todo o nada).
- **Riesgos:** valor medio (¿lo abren?); factibilidad baja (la revisión semanal ya hace esto con `postpone_task` y `delete_task`).
- **Supuestos:** los usuarios dejan 2 o más pendientes al día.
- **Prueba:** una semana con el aviso; contar cuántas noches se abre.

## 6. Orden propuesto

| # | Idea | Esfuerzo | Necesita BD | Primero porque |
|---|---|---|---|---|
| 1 | Foco en un toque | Bajo | No | Gana más con menos código |
| 2 | Pasos siempre propuestos | Medio | No | Arregla la queja de fondo |
| 3 | Un solo camino para crear | Medio | No | Apoya la idea 2 |
| 4 | Cierre del día | Bajo-medio | No (reusa RPC) | Quita pantallas de lectura |
| 5 | Hábitos con hora | Medio | Sí (RF + RPC) | Requiere actualizar RF |

Antes de cada una: pasar `ux-interaction` sobre el boceto. Después: pulido con `impeccable` y `emil-design-eng`, y probar en un teléfono.

---

# Segunda ronda (2026-11-07): que enseñe y que atraiga

Mismas skills (`brainstorm-ideas-existing`, `product-discovery`, `ux-interaction`). Las ideas 1–5 de arriba ya están hechas.

## 7. Resultado buscado

> **Que la persona aprenda a organizarse mientras usa la app, y que tenga algo que quiera mostrar.**

- **Didáctico** = aprende haciendo, en el momento justo, con sus propios datos. Nada de lecciones largas ni pantallas de solo lectura (CLAUDE.md §14).
- **Atraer** = un momento que se pueda contar o compartir, sin red social, ranking ni dark patterns (§9).
- Métricas: % que termina el primer día guiado; % que vuelve el día 7; tarjetas compartidas por semana.

**Aviso (ponytail ultra):** más funciones no es mejor. Las quejas hasta hoy fueron de lo básico. Construir de una en una y medir; si una no mueve su métrica en 2 semanas, se quita.

## 8. Lluvia de ideas (trío)

**PM (valor)**
1. **Primer día guiado:** el Onboarding termina haciendo una tarea real de punta a punta: escribirla → dividirla en pasos → 5 min de foco → marcarla. Se aprende el ciclo usándolo.
2. **Plan de examen:** fecha del examen + temas → bloques de estudio repartidos con repaso espaciado (1, 3 y 7 días). Gancho fuerte para estudiantes (el público del proyecto).
3. **Tarjeta «Tu semana»:** imagen con lo hecho, horas de foco y racha, para compartir por WhatsApp o Instagram con el menú del sistema. Sin cuentas ni ranking.
4. **Plantillas de rutina:** «Mañana productiva», «Semana de parciales», «Cerrar el día»: crean hábitos y bloques de una vez.
5. **Reto de 7 días:** un objetivo pequeño por día (dividir una tarea, cerrar el día, un foco de 25 min…) que enseña cada parte de la app.

**Diseño (uso y gusto)**
6. **«¿Por qué funciona?»:** la primera vez que usas algo, una línea con la ciencia detrás (Pomodoro, Zeigarnik, intenciones de implementación) y «Saber más». Se muestra una sola vez.
7. **Logros que enseñan:** se desbloquean por aprender una técnica, no por abrir la app («Dividiste tu primera tarea grande»). Cada uno explica qué aprendiste.
8. **Mapa del año:** cuadrícula de días tipo calendario de contribuciones; ver la constancia engancha y se comparte.
9. **Celebración proporcional:** subir de nivel o cerrar un proyecto tiene una animación corta y distinta; lo diario, un toque sutil (`emil-design-eng`).
10. **Pistas en contexto:** máximo 3 marcas la primera vez que se abre cada pantalla, nunca un tour largo.

**Ingeniería (datos)**
11. **Lo pensado vs lo real:** compara el tiempo estimado con el medido en Foco («Pensaste 30 min, te tomó 50») y ajusta la próxima estimación. Enseña la falacia de planificación con sus datos.
12. **Tu mejor hora:** por reglas, la franja en que más terminas («Rindes más de 9 a 11») y «Armar mi día» la usa.
13. **Resumen del mes en lenguaje claro:** 3 frases por reglas (no IA) sobre el mes, en la Revisión.
14. **Widget con racha y siguiente paso** en la pantalla de inicio.
15. **Exportar a Google Calendar (.ics)** de los bloques planificados.

## 9. Las 5 elegidas

### A · Primer día guiado (idea 1 + 10)
- **Por qué:** enseña el ciclo completo en 2 minutos y deja la primera victoria hecha; hoy el Onboarding solo pregunta datos.
- **Riesgos:** valor alto · usabilidad media (no debe sentirse obligatorio: botón «Saltar») · factibilidad baja (reusa Crear, «Dividir en pasos» y Foco en un toque).
- **Supuesto:** quien termina el primer día vuelve más el día 7.
- **Prueba:** 5 personas nuevas con y 5 sin; contar quién vuelve.

### B · Lo pensado vs lo real (idea 11)
- **Por qué:** es la lección más útil de productividad y sale de datos que ya existen (`estimated_minutes` y los ciclos de Foco).
- **Riesgos:** valor medio-alto · factibilidad baja-media (una RPC de lectura) · usabilidad: tono de invitación, nunca de culpa (§7).
- **Supuesto:** ver la diferencia cambia cómo estiman la siguiente vez.
- **Prueba:** tras 2 semanas, ¿se acercan las estimaciones al tiempo real?

### C · «¿Por qué funciona?» + Logros que enseñan (ideas 6 + 7)
- **Por qué:** convierte cada función en una mini lección justo cuando se usa; los logros dan un motivo para probar cada técnica. La tabla `achievements` sigue en la BD.
- **Riesgos:** valor medio · usabilidad: una sola vez y breve, o se vuelve ruido · factibilidad media (catálogo + RPC que lo otorga).
- **Supuesto:** quien lee la explicación usa más la función.
- **Prueba:** comparar uso de «Dividir en pasos» antes y después.

### D · Plan de examen (idea 2)
- **Por qué:** el gancho más claro para el público estudiante: escribes «parcial de cálculo el 20, temas 1–4» y sale el plan.
- **Riesgos:** valor alto para estudiantes · factibilidad media (reglas en `domain` como `DayPlanner`: repartir temas y repasos; la IA solo lee la frase) · viabilidad: nicho, pero es el público del proyecto.
- **Supuesto:** los estudiantes no planifican el estudio porque cuesta armar el calendario.
- **Prueba barata:** hacer 3 planes a mano para compañeros y ver si los siguen.

### E · Tarjeta «Tu semana» + Mapa del año (ideas 3 + 8)
- **Por qué:** lo único de la lista que trae gente nueva; muestra constancia, no comparación.
- **Riesgos:** valor medio · viabilidad: privacidad (el usuario elige qué sale; nunca títulos de tareas por defecto) · factibilidad media (dibujar la imagen + menú de compartir del sistema, paquete nuevo `share_plus`).
- **Supuesto:** 1 de cada 10 usuarios activos comparte al menos una vez al mes.
- **Prueba:** botón «Compartir» simple; contar toques antes de pulir el diseño.

## 10. Orden propuesto

| # | Idea | Esfuerzo | BD | Motivo del orden |
|---|---|---|---|---|
| 1 | A · Primer día guiado | Bajo | No | Reusa lo ya hecho; mejora la primera impresión |
| 2 | B · Lo pensado vs lo real | Bajo-medio | RPC de lectura | Didáctico con datos reales |
| 3 | D · Plan de examen | Medio | No (crea tareas) | Gancho del público |
| 4 | C · ¿Por qué funciona? + logros | Medio | Sí (catálogo) | Lecciones en contexto |
| 5 | E · Tarjeta y mapa del año | Medio | No | Atrae gente; paquete nuevo |

Descartadas por ahora: rankings o retos entre amigos (choca con §10, un solo usuario), recompensas aleatorias no cosméticas (§9), notificaciones para «volver» sin motivo real (dark pattern).
