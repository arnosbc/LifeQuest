# 🎮 Ideas del Proyecto — Productividad Gamificada

> Documento vivo. Se actualiza a medida que surgen nuevas ideas, decisiones o ajustes. No es el documento formal de la propuesta — es el lugar donde se guarda el estado actual del pensamiento del proyecto.

**Última actualización:** Octubre 2026 — cierre del diseño de la app: se incorporan las decisiones tomadas durante el diseño (Diario sin Diario del Héroe, dificultad en Configuración, XP calculada por RPGenie, modo oscuro y temas, Mochila de la Mazmorra, Taverna, Refugio) y se define la **economía estable** de Monedas. *(Detalle en el Historial de cambios.)*

---

## 🎯 Concepto

App móvil de productividad gamificada: convierte tareas, hábitos y proyectos reales en misiones tipo RPG. El progreso real del usuario hace progresar a su personaje.

> «Convierte tus objetivos y responsabilidades diarias en una aventura donde tu progreso en la vida real hace progresar a tu personaje.»

## 🧠 Problema que resuelve

No es falta de saber qué hacer, es la **brecha entre intención y acción**:
- Las tareas grandes no tienen punto de entrada claro.
- Falta feedback inmediato (a diferencia de un videojuego).
- Fatiga de decisión al organizar pendientes.
- Pensamiento todo-o-nada cuando se rompe una racha o meta.

## 🔄 Ciclo principal

```
Vision Board (propósito) → Brain Dump / Quick Add (captura)
→ Diagnóstico (GTD Diagnosis Tool para Tarea/Proyecto · S.M.A.R.T. Diagnosis Tool para Meta)
→ Meta → Proyecto → Tarea/Misión → Mazmorra (sesión de concentración)
→ Tarea completada → XP + Monedas → Nivel de personaje + nivel de la skill/Área → Siguiente misión
```

**Bucle auxiliar (Taverna):** el usuario crea NPC → la IA (RPGenie) diseña su misión según tu meta actual → la completas y obtienes recompensas → puedes pedir otra misión al momento.

**Bucle de recompensa (Marketplace):** las Monedas ganadas se gastan en el Marketplace: Hotel (recuperar HP), Mercado (Elixir de enfoque, Cofre misterioso), Mercado negro (objetos raros y limitados como "Recuperar racha") y **Refugio** (mejoras permanentes con precio creciente). Lo que no cabe en la bolsa pasa al **Tesoro del reino** (prestigio). Ver **Economía estable**.

---

## 🧩 Sistemas principales

*Leyenda: 🆕 sistema nuevo incorporado · 🔧 sistema existente modificado · ⏸️ en pausa · sin marca = sin cambios.*

### 🆕 Vision Board (Visión del Personaje)
Un espacio, dentro del Perfil, donde el usuario define la visión de largo plazo de su personaje / su vida ideal. Las Metas y Proyectos se conectan de vuelta a esta visión, para que el progreso diario se sienta parte de algo más grande. Refuerza la necesidad de **propósito y autonomía** (Teoría de la Autodeterminación).

### 🆕 Perfil del Personaje
Pantalla principal del personaje. Debe mostrar de forma clara:
- **Nivel** y **progreso del nivel actual** (barra: XP actual → XP requerido).
- **Monedas** (saldo actual de la economía gastable).
- **HP / Vida** actual (ver Vitalidad).
- **Identidad del personaje:** nombre, rol/clase y la declaración de *"¿Quién eres en este reino?"* que el usuario define. Esa identidad también la usan los NPCs de la Taverna para personalizar sus misiones.
- **Tasa de finalización de objetivos:** % de metas/proyectos completados sobre el total.
- Acceso directo a Vision Board, Inventario/Logros, Configuración (Game Master) y Diario.
- **Skills / Áreas integradas:** las skills creadas por el usuario (que son a la vez las Áreas de P.A.R.A.) y su nivel propio se administran desde este mismo perfil.

### 🆕 Brain Dump (Bandeja de Captura)
Espacio para volcar pensamientos o ideas sueltas en cualquier momento, sin decidir de inmediato en qué Meta o Proyecto encajan. Se revisan después y se convierten en tareas o se descartan mediante el **GTD Diagnosis Tool** (ver abajo). Reduce la fricción de decisión que exige el **Modelo de Fogg** (baja la barrera de "Capacidad" en el momento de captura).

### 🆕 GTD Diagnosis Tool (clasificador Tarea / Proyecto / Meta)
Para quien no sabe si lo que tiene en mente es una Tarea, un Proyecto o una Meta: un botón junto a cada entrada del Brain Dump (y también accesible al crear algo desde cero) que abre una pestaña donde el usuario titula lo que quiere hacer y responde un checklist corto de opciones cerradas — no preguntas abiertas. El resultado se muestra al final y habilita el botón de creación ya con el tipo correcto:

1. **¿Es accionable?** → No: se guarda como Referencia o "Algún día / Tal vez" en el propio Brain Dump, y el diagnóstico termina ahí (no crea Tarea/Proyecto/Meta).
2. **¿Se resuelve en un solo paso, o necesita varios pasos/acciones para completarse?** → Un solo paso: sigue como candidato a **Tarea** (preguntas 3–5). Varios pasos: sigue como candidato a **Proyecto** o **Meta** (pregunta 3b).
   - *3b (solo si tiene varios pasos):* **¿Es un resultado que se completa con una lista de tareas en un rango de tiempo acotado (semanas), o es algo más amplio que probablemente vas a lograr completando varios proyectos o sosteniendo un hábito en el tiempo (meses)?** → Lo primero: **Proyecto**. Lo segundo: **Meta** (continúa en el S.M.A.R.T. Diagnosis Tool).
3. **¿Puedo hacerlo ahora mismo (toma un par de minutos)?** *(solo si es Tarea)* → Sí: se sugiere completarla al instante en vez de guardarla.
4. **¿Soy la persona correcta para hacerlo?** *(solo si es Tarea)* → No: 🟡 pendiente de diseño (¿se ofrece delegar/compartir, o solo se marca como nota?).
5. **¿Tiene un tiempo específico?** → Sí: se sugiere fecha límite / entrada en el Calendario. No: entra a la lista general de próxima acción.

> Adaptado del árbol de decisión clásico de **GTD (David Allen)**: las preguntas 1, 3, 4 y 5 vienen directo de ahí (accionable → 2 minutos → delegar → agendar); la pregunta 2 es la definición de "proyecto" de Allen — *"cualquier resultado que requiere más de una acción para completarse"* — que faltaba para poder separar Tarea de Proyecto. La 3b no es de GTD: Allen resuelve esa distinción con un modelo aparte (**Horizons of Focus**, donde Metas/Objetivos son una altitud por encima de los Proyectos — resultados a 1–2 años que normalmente se logran completando varios proyectos), así que aquí se adapta como una sola pregunta de alcance temporal.

Es lógica de reglas simples (sin IA), así que no depende de RPGenie — vive en el **MVP**, junto al Brain Dump. El Quick Add de Stage · P.A.R.A. reutiliza esta misma herramienta; no crea una segunda.

### Tareas 🔧 *(se agrega estimación automática de recompensa, ver más abajo)*
Campos: título, descripción, skill/Área, prioridad, fecha de creación, fecha límite, estado, etiquetas, subtareas, **vínculo opcional a un Proyecto o a una Meta**, recompensa (XP/Monedas — **calculada por RPGenie**), repetición.

**Decisión de diseño:** la tarea **no tiene tiempo estimado ni dificultad elegida por el usuario**. RPGenie determina la XP según la tarea (título, prioridad, vínculo con proyecto/meta); el usuario ve la estimación antes de crearla.

### Proyectos grandes → Subtareas
- El usuario puede ingresar proyectos de gran contexto (ej. "Realizar proyecto del semestre").
- Se dividen directamente en **tareas**, y estas en subtareas — generando más misiones jugables. (Se retira el nivel intermedio "Historia": mezclaba Scrum con P.A.R.A., que ya es la metodología de organización del proyecto.)
- El usuario asigna un **rango de tiempo** (inicio–fin) al proyecto completo.
- Un proyecto puede vincularse opcionalmente a una **Meta** (ver Módulo Goal → Boss Fight) — no es obligatorio, un proyecto puede existir sin meta asociada.
- El sistema calcula automáticamente la prioridad comparando **trabajo restante** contra **días restantes** → "ritmo necesario". Arranca como **regla simple** (Fase 2) y más adelante lo afina **RPGenie** (Fase 4).
- Clasificación de urgencia: 🟢 Baja / 🟡 Media / 🔴 Alta.
- **Decisión tomada:** el cambio de prioridad se **notifica al usuario**, nunca es silencioso. Ejemplo: *"🔔 Tu proyecto 'Proyecto del semestre' pasó a prioridad alta."*

### 🆕 Estimación automática de recompensa (XP/Monedas)
Adaptado de la función de IA de LiFE RPG 2.0. Al crear una tarea o proyecto, RPGenie calcula la recompensa — **reglas simples desde la Fase 2**, modelo de IA cuando llegue RPGenie (Fase 4). Regla del diseño: base +10 XP; +10 si el título describe una acción concreta (≥ 5 palabras); +10 prioridad Alta / +5 Media; +10 si está vinculada a una Meta / +5 a un Proyecto. **Siempre entre 10 y 40 XP por tarea.** Las Monedas salen solas (30 % de la XP). El usuario **no la edita a mano**: así se reduce la fatiga de decisión y no se puede inflar.

### 🔧 Sistema RPG: skills = Áreas *(sin atributos fijos)*
Se eliminan los cuatro atributos predefinidos (Conocimiento, Concentración, Disciplina, Energía): no son necesarios para el objetivo del proyecto. El árbol ya no tiene troncos fijos de fábrica.

- **Solo existe la Skill, y es 100% creada por el usuario.** Cada persona crea las skills que le convengan según lo que quiere desarrollar (ej. alguien que quiere aprender inglés crea la skill "Inglés").
- **Límite:** hasta **6 skills** por usuario en la versión base (con suscripción, más adelante, se amplía el límite). **Sin tope de nivel** por skill.
- **Los troncos/ramas del árbol son las Metas, Proyectos o Tareas** categorizadas con esa skill: la skill **es** el Área. Completar algo asignado a la skill "Inglés" sube de nivel esa misma skill.
- **Progreso específico por skill:** cada skill mantiene su propio nivel y % de avance hacia el siguiente nivel (ej. "Inglés — Nivel 3 · 40% hacia Nivel 4").
- **Desde el MVP** existe la skill básica (crear, asignar a tareas, subir de nivel), porque categorizar tareas depende de ella; la vista completa de Área (conteos, Goals/Projects asignados) llega con Stage · P.A.R.A. completo.

**Relación con las Áreas de P.A.R.A.:** un solo sistema — la skill del árbol **es** el Área de P.A.R.A. Hay una sola categorización, y la barra de nivel de la skill es la misma barra que se ve en Areas (ver Módulo Stage · P.A.R.A.).

### 🆕 HP / Vitalidad (adaptado con cautela)
LiFE RPG liga la pérdida de HP a hábitos negativos y permite "muerte del personaje". Se adapta para no chocar con el principio ético del proyecto:
- HP se convierte en un indicador **agregado de constancia general** (no ligado a un solo hábito).
- Baja lentamente si varios hábitos/rachas se descuidan **en simultáneo**; sube con actividad regular.
- **Proyectos, Metas o Tareas no completadas dentro de su plazo asignado** también restan HP. **Decisión:** todos los plazos incumplidos restan el **mismo valor fijo** de HP, sin distinción por tipo (Proyecto/Meta/Tarea).
- **Sesiones de estudio (Mazmorra / Deep Working):** si al cerrar la sesión no se completaron todas las tareas asignadas a esa sesión, se aplica una penalización de HP. **Decisión:** se define un **valor inicial de penalización**, que se **reduce a medida que se completan más tareas** de las asignadas a esa sesión (penalización proporcional al avance, no todo o nada).
- Los **malos hábitos registrados** también restan un **valor fijo** de HP por evento. Ver **Sistema de Dificultad** más abajo.
- **Propuesta de valores:** hábito malo −3 / −5 / −8 (según la gravedad que elige el usuario), plazo incumplido −5, día sin jugar −5. Se recupera **+4 de vida cada día con al menos un hábito bueno** (+1 por cada nivel del Huerto del Refugio).
- **Debilitado:** por debajo de **30 de vida** el personaje gana **−25 % de XP** (nunca menos Monedas) hasta superar 30. *(Propuesta a confirmar por el equipo.)* Nunca hay "muerte" ni pérdida de nivel o progreso.
- Se recupera retomando actividad, o comprando recuperación en el **Hotel** del Marketplace, no con un evento único de "revivir".

### 🆕 Sistema de Dificultad (Game Master)
Editable **solo desde Configuración** (y elegida una vez en el Onboarding): **3 niveles — Fácil, Normal y Difícil.**
- **XP:** ×1,2 (Fácil) · ×1 (Normal) · ×0,85 (Difícil).
- **Vida perdida:** ×0,75 · ×1 · ×1,25.
- **Monedas: iguales en todas las dificultades.** Así los precios del Marketplace valen lo mismo para todos y la economía no se rompe al cambiar de nivel.

### XP, Niveles y Monedas (economía dual)
Se separa la recompensa en dos monedas de significado distinto:
- **XP:** mide progreso real, nunca se gasta, sube de nivel (del personaje y de la skill/Área correspondiente).
- **Monedas:** se ganan junto al XP (proporcional a dificultad) y sí se gastan.

Esto no cambia cuánto "vale" completar algo — solo separa la medida de progreso (XP, permanente) de la recompensa consumible (Monedas, gastable), para que gastar una recompensa nunca se sienta como perder avance.

### 🆕 Economía estable (Monedas)
Objetivo: que una Moneda valga lo mismo el día 1 y el día 300, y para quien juega poco o mucho. La XP nunca tiene tope; las Monedas sí tienen controles.

**Los 6 estabilizadores:**
1. **Ingreso plano:** Monedas = **30 % de la XP** (3 por cada 10 XP), venga de donde venga. Las Monedas por acción **no suben con el nivel**; lo que crece es la XP necesaria para subir (100 × nivel^1,5).
2. **Tope suave diario:** las primeras **50** Monedas del día llegan completas, las **50 siguientes a la mitad** (+25) y después solo se gana XP. Máximo efectivo: **75 Monedas al día**.
3. **Bolsa con límite:** **400 + 25 por nivel** (máximo 1.000). Lo que no cabe pasa al **Tesoro del reino**: prestigio que no se gasta y desbloquea títulos.
4. **Precios fijos y anclados** al "día de juego" (≈ 50 Monedas, lo que gana un jugador regular). Nunca suben.
5. **Salidas que crecen:** el **Refugio** sube de precio con cada mejora (120 × 1,35ⁿ), y absorbe a quien tiene mucho sin castigar a quien tiene poco.
6. **Anti-trampas:** 10–40 XP por tarea; una tarea completada a menos de 2 min de crearla da el mínimo y 0 Monedas; máximo 15 tareas con Monedas al día; editar una tarea no recalcula su recompensa.

**Entradas:** tarea 3–12 · hábito bueno 2–4 · ciclo de Mazmorra 3 · misión de NPC 5–24 · cofre del día 15 (≥ 3 misiones) · proyecto completado +36 · jefe derrotado +90 · logros 50–200.

**Simulación (180 días, 40 partidas por perfil):** sin controles, las Monedas se acumulan sin parar (3.600 / 13.500 / 29.000 en jugadores casual, regular e intenso) y los precios dejan de importar. Con los 6 estabilizadores, los saldos quedan entre ~100 y ~900, se gasta el 70–96 % de lo ganado y la diferencia de ingreso entre casual e intenso baja de ×5,6 a ×3,3.

**Revisión tras el lanzamiento:** medir cada mes las Monedas por usuario activo/día, % gastado, % que va al Tesoro y lo más comprado. Si el % gastado baja de 60 %, se añade un objeto al Mercado negro; si los casuales gastan más del 95 %, se abarata la Siesta. **Solo se ajustan precios del Mercado negro y del Refugio; las reglas de ingreso no se cambian.**

### 🆕 Marketplace — Reward (Tienda del héroe)
El mercado es donde el **esfuerzo se convierte en alegría**: el usuario gasta Monedas del juego en mejoras de personaje y en recompensas.
- ❌ **Sin autorecompensas** (que el usuario defina y se compre su propia recompensa real, ej. un libro, un viaje, un café): mucha gente confundía su propósito. El usuario **ya no crea artículos propios** en el mercado.
- ✅ **Reemplazo de las autorecompensas (decidido en el diseño):** Refugio, Mercado y Mercado negro rotativo, más el Tesoro del reino como prestigio.
- **Carrito de compra y "Mis compras":** flujo de compra con carrito (total, saldo restante y aviso si no alcanza) e historial.
- **Hotel** (recuperar vida): Siesta +10 → **30** · Noche en la posada +25 → **70** · Banquete (vida completa) → **150**.
- **Mercado:** Elixir de enfoque (×1,5 XP en la próxima sesión de Mazmorra, 1 activo) → **40** · Cofre misterioso (consumible al azar, a veces un título; 1 al día) → **60**.
- **Mercado negro** (se repone el 1 de cada mes): Recuperar racha (rota en las últimas 48 h, 1 al mes) → **150** · Pase de Recuperación (1 al mes) → **90** · "Objeto del mes" rotativo y limitado.
- **Refugio** (mejoras permanentes, precio 120 × 1,35ⁿ, nunca dan más Monedas): **Huerto** (+1 vida diaria por nivel), **Biblioteca de RPGenie** (+1 misión ligera al día por nivel), **Estandarte del gremio** (+1 NPC en la Taverna por nivel). 4 niveles cada una.

### ⏸️ Módulo Financial Vault (Bóveda Financiera) — pausado, fuera de alcance
El equipo decide dejar este módulo fuera del alcance actual del proyecto. No aparece en el menú, en las fases ni en la arquitectura activa, y ningún otro módulo depende de él. Se conserva el diseño por si se retoma:

- Centro para gestionar **dinero real**: ingresos, gastos, presupuestos, lista de deseos, metas financieras y cuentas bancarias.
- Conectado con el Marketplace: flujo de *lo que ganas, lo que gastas y lo que logras*.
- **Flujo lista de deseos → mercado:** el usuario añade un artículo a su lista de deseos (ej. una cámara), fija su precio y lo lleva a su mercado; al comprarlo con Monedas se deduce la recompensa virtual **y** se registra un gasto en la bóveda.
- *(Nota: este flujo dependía de las autorecompensas, que ya se eliminaron — si se retoma el Vault, habrá que rediseñar esta conexión.)*

### 🆕 Pase de Recuperación
Con Monedas, el usuario puede comprar un pase limitado que protege una racha tras un día fallido: **90 Monedas, 1 al mes y como máximo 2 guardados**. Si la racha se rompe, hay **48 h** para usar un pase o «Recuperar racha» antes de que vuelva a 0 (el récord se guarda en los logros). Reemplaza la idea descartada de "energía" para rachas.

Para la versión "rara" de protección de racha, el **Mercado negro** ofrece el objeto **"Recuperar racha"** con límites y cooldown adicionales.

### Misiones (diarias, semanales, épicas)
Se mantiene la estructura (diarias, semanales, épicas). Ya **no son un ítem propio del menú**: las misiones actuales se ven en **Stage · P.A.R.A.** (dashboard de tareas), y las misiones cumplidas o falladas quedan registradas en el **Diario**. Las misiones de los NPCs viven en la Taverna.

### 🔧 Diario (Bitácora)
❌ **El Diario del Héroe se elimina** (decisión del diseño). El Diario es solo la **Bitácora**: cada vez que algo se completa o falla se guarda una entrada (`QuestLogEntry`). Se entra desde el Perfil y muestra arriba un resumen de la semana con enlace a Estadísticas.

**Bitácora (antes "Historial de Misiones")** — la lista cronológica y precisa. Cada entrada contiene:
- **Fecha y hora** en que terminó.
- **Mensaje de estado:** "Completaste la misión X" o "Fallaste la misión Y".
- **Recompensa obtenida** (XP / Monedas / objetos) o **penalización aplicada** (ej. HP perdido por un mal hábito).
- **Apartado de origen:** de qué módulo vino (Tarea/Misión, Proyecto, Hábito bueno/malo, NPC de la Taverna, Meta S.M.A.R.T., Mazmorra/Deep Working — nunca "P.A.R.A.", que solo es una vista sobre esas mismas entidades).
- Filtros por apartado y por periodo.

**Decidido:** Inventario/Logros vive en el **Perfil**, no en el Diario. Filtros del diseño: Todo, Tareas, Hábitos, Mazmorras, Metas.

🟡 **Abierto:** ¿el usuario puede escribir notas propias en la Bitácora? ¿Se añade filtro por skill/Área?

### 🆕 Taverna (NPCs — Companion Hall)
La Taverna es donde el usuario **crea sus propios NPCs** y la IA (RPGenie) les da misiones — por eso llega en la **misma fase que RPGenie**. El usuario decide *quiénes son* y *qué tipo de misiones le dan*. Cada NPC tiene una ficha propia con:
- **Nombre** del NPC.
- **Personalización:** icono/avatar y banner *(versión simple: lista de iconos predefinidos, mientras Personalización esté en pausa)*.
- **Noble misión:** el propósito del propio NPC (ej. "impulsarte todos los días", "que cumplas tus metas semanales").
- **Declaración de identidad del usuario:** el NPC responde *"¿Quién eres en este reino?"* — la identidad la define el usuario y la IA la usa para personalizar misiones.
- **Frecuencia:** diaria, semanal o mensual.
- **Misiones generadas por IA:** RPGenie diseña misiones que se ajustan a la situación exacta y a la meta actual del usuario.
- Al terminar la misión se presiona **"Completar"** y se obtienen las recompensas.
- Botón **"Pedir misión al momento"** para solicitar una misión en ese instante: **una gratis cada 3 h**; antes de eso cuesta 15 Monedas (salida pequeña de la economía).
- **Diseño:** salón con los NPCs (búho, zorra, tortuga… formas originales), ficha de cada NPC con su misión y el porqué, historial, y asistente **Crear NPC en 4 pasos** (forma y estandarte · nombre, papel y noble misión · frecuencia y enfoque · identidad + misión de ejemplo). Máximo 3 NPCs al inicio (más con el Estandarte del Refugio).
- Tipos de ejemplo: un **mentor** que impulsa todos los días, un **compañero tranquilo** que propone metas semanales.

### Hábitos — Buenos y Malos 🔧
**Buenos hábitos (Crecimiento):**
- El usuario crea hábitos **diarios o en días específicos** de la semana.
- Al completar un hábito se presiona **"Completar"** y se otorgan recompensas pequeñas (XP + Monedas).
- **Estadísticas de crecimiento:** panel que muestra cuántas veces se practicaron buenos hábitos esta semana, este mes y este año.
- **Mapa de calor de crecimiento:** minicalendario que se va llenando de color por cada día completado del mes; el usuario elige el mes ("Mes seleccionado") y el tema de color ("Color").

**Malos hábitos (Penalización):**
- Misma mecánica de creación y registro, pero en lugar de recompensa tienen **penalización: pérdida de un valor fijo de vida (HP)** al registrarse. Alimentan el indicador agregado de HP/Vitalidad.

Las rachas conservan su mecánica; conectadas agregadamente al indicador de HP/Vitalidad.

### 🔧 Mazmorras (Dungeon Runs) + Deep Working
Se renombra la sesión Pomodoro como **Mazmorra**: cada Mazmorra es un ciclo de trabajo (25/30/45 min, configurable), asociado a una tarea, enmarcado narrativamente como una incursión. Al completarla, el personaje "derrota" el desafío y obtiene XP + Monedas.

**Deep Working es el contenedor de la sesión completa**, y las Mazmorras son sus ciclos de trabajo:
- Al iniciar una sesión Deep Working, el usuario define la **duración total del bloque** (ej. "3 horas", en pasos de 30 min), **asigna las tareas** que piensa trabajar y elige la **duración del ciclo Pomodoro** (25/30/45 min).
- **Mochila de misiones (diseño):** las tareas se eligen en una hoja con buscador y filtros (Sugeridas por RPGenie, Hoy, Urgentes, Todas), con **máximo 5 tareas** por sesión, para no tener que recorrer una lista larga. Un mapa de ruta muestra cuántas mazmorras y descansos tendrá el bloque.
- El sistema encadena automáticamente los ciclos: cada ciclo es una Mazmorra sobre una de las tareas asignadas → XP + Monedas → **descanso cronometrado** → siguiente ciclo, hasta agotar el bloque o completar las tareas asignadas.
- El usuario puede **pausar, saltar un descanso puntual o terminar la sesión antes de tiempo sin perder el progreso ya ganado**.
- Al cerrar la sesión se muestra un **resumen**: ciclos completados, XP/Monedas totales, tareas avanzadas o completadas.
- Todo dentro de la sesión está diseñado para **tener el objetivo presente**: sin navegación extra, sin ruido.
- Las alertas de "fin de ciclo" / "fin de descanso" son **alertas de sesión** (como un temporizador que el propio usuario disparó), no notificaciones del sistema anti-estrés: quedan exentas del digest, del límite diario y de la ventana de silencio.
- La penalización de HP por tareas no completadas en la sesión se activa cuando llega HP/Vitalidad (Fase 2); en el MVP la sesión solo da recompensas.

> **Pendiente:** duración por defecto del descanso. Lo estándar de Pomodoro es 5 min de descanso corto por ciclo y 15–20 min de descanso largo cada 4 ciclos; falta confirmar si el descanso largo aplica igual para ciclos de 30/45 min.

### Logros
Incluye logros ocultos ("???"). Diseño: insignias hexagonales — doradas (conseguido), verdes (en curso, con progreso), grises (bloqueado o secreto) — con ficha de requisito, progreso y recompensa.

### Inventario y recompensas
Pantalla **Inventario y logros** dentro del Perfil, con dos pestañas: **Logros** y **Objetos**. Los consumibles comprados en el Marketplace se usan desde aquí. Los **títulos de prestigio** (por logros, nivel o el Tesoro del reino) no se compran, solo se ganan, y se muestran bajo el nombre en el Perfil y la Taverna.

### ⏸️ Personalización — en pausa
Por el momento el equipo no puede enfocarse en este apartado y todavía no está definido cómo se resolvería (¿arte específico, modelos generativos, etc.?). Quedan en pausa: avatar, ropa, accesorios, marcos de perfil, **temas visuales completos** (pixel art, cyberpunk, etc.) y las **recompensas cosméticas sorpresa**. No aparece en ninguna fase hasta que se decida el enfoque.

**Sí entran (no son personalización artística):** **modo claro / oscuro / automático** y **4 temas de color** (Bosque, Río, Brasa, Oro) en Configuración, y los **títulos de prestigio** del Inventario.

### Retos y Bosses 🔧 *(Boss reservado para Metas)*
Los proyectos grandes ya no se representan como Bosses por sí mismos. Se integra con el **Módulo Goal → Boss Fight**: cada Meta registrada es el Boss, y cada objetivo tiene su misión para que el usuario nunca se pierda, con el progreso siempre visible.

### 🆕 Módulo Goal → Boss Fight (Rastreador de Objetivos)
**Diseño:** arena del jefe (vida, fecha límite), lista de **ataques disponibles** (cada tarea o proyecto vinculado con su daño), golpes recientes, ficha S.M.A.R.T. desplegable y pantalla de victoria (+300 XP, +90 Monedas y un título). Si la fecha vence con el jefe vivo: estado **"El jefe escapó… por ahora"** — la XP de cada golpe se conserva, no hay castigo extra, y se ofrece replantear la meta con S.M.A.R.T. o archivarla como aprendizaje.

Rastreador de objetivos donde cada meta registrada es una "pelea de boss":
- Cada **objetivo tiene una misión** asignada, para que el usuario no se pierda qué debe hacer a continuación.
- El **progreso siempre es visible** (barra y % en todo momento).
- **Quién le resta vida al Boss:** cualquier Proyecto vinculado a esa Meta, y también cualquier Tarea vinculada directamente a la Meta. Completar cualquiera de los dos le resta HP al Boss; un Proyecto no es un Boss en sí mismo, es una de las formas de golpear al Boss de su Meta.

### 🔧 Módulo Growth & Objetivos Personales (S.M.A.R.T.)
Generador y validador de metas individuales de mediano/largo plazo (perder peso, crear un hábito, reto de 30 días).
**Flujo:** **S.M.A.R.T. Diagnosis Tool** (botón dentro de Stage · P.A.R.A., ver ahí el formulario) → Meta → Tareas/Misiones.
- **Objetivos de Crecimiento:** cada objetivo activo se muestra como tarjeta de misión con recompensa (Monedas + XP), línea de tiempo (inicio → fin), barra de progreso (%) y estado final — **Éxito / ¡Sigue así! / Fracaso**.
- ❌ **"Objetivo Personal" ya no es una vista aparte:** era prácticamente la misma información que la sección **Goals** de Stage · P.A.R.A. **Goals pasa a ser la única vista periódica de metas**; desde la pestaña Objetivos se accede a ella con un acceso directo.
- **Tareas · Misión:** cada objetivo se descompone en tareas individuales con su propia recompensa, agrupadas por estado — **Sin iniciar / En progreso / Completada**.
- **Vocabulario de estados unificado (Boss Fight / S.M.A.R.T. / P.A.R.A.):** **un solo estado real** por objetivo — Sin iniciar / En progreso / Completada / Vencida — y cada pantalla lo muestra con su propio "disfraz" cosmético: Boss Fight y Objetivos de Crecimiento lo muestran como Éxito/¡Sigue así!/Fracaso, el Calendario de P.A.R.A. como "¡Hazlo ahora!"/Vencida, etc. Una sola fuente de verdad con distinta piel visual.

### 🆕 Módulo Stage · P.A.R.A. (enfoque G.T.D.) 🔧 *(vista/dashboard, no un sistema con datos propios)*
Sistema P.A.R.A. (Projects, Areas, Resources, Archive + Tasks/Goals/Events) como **centro de mando** del día a día y dashboard de tareas (aquí viven las misiones actuales). **No duplica datos:** Tasks, Projects y Goals que se ven aquí son los mismos registros de sus módulos de origen — P.A.R.A. es una vista organizada por Área sobre esas entidades, más Resources/Events, que sí son exclusivos de este módulo.

**Se construye por partes** (ver Fases): Quick Add + Daily Highlight en el MVP, Goals + S.M.A.R.T. Diagnosis Tool en la Fase 2, y Areas completas, Resources, Archive, Calendario y Events en la Fase 3.

- **Quick Add:** creación rápida de cualquier entidad (Task, Project, Goal, Area, Event, Resource). Usa el **GTD Diagnosis Tool** para Task/Project y el **S.M.A.R.T. Diagnosis Tool** para Goal. Area/Resource/Event se crean directo, sin diagnóstico.
- **S.M.A.R.T. Diagnosis Tool** *(botón propio, en paralelo al GTD Diagnosis Tool)*: "Establecer metas es fácil, establecer buenas metas es el verdadero desafío" — guía al usuario a través del marco SMART para que su meta sea específica, medible, alcanzable, relevante y con plazo definido. Formulario:
  - **Título de tu Meta.**
  - **Skill relacionada:** ¿esta meta está relacionada con alguna de tus skills? Si es así, selecciona la skill correspondiente (*Seleccionar skill*).
  - **Específico (S):** ¿tu meta está claramente definida? (ej. "Mejorar mi inglés" vs. "Aprender 20 palabras de inglés al día") · ¿quién está involucrado o afectado? · ¿qué es exactamente lo que quieres lograr? · *Verificación: ¿la respuesta contiene una acción y un resultado claros?*
  - **Medible (M):** ¿cómo sabrás cuándo se logró la meta? · ¿qué métricas, números o señales puedes usar para medir el progreso? · ¿con qué frecuencia revisarás tu progreso? · *Verificación: ¿hay un indicador medible o condición de éxito?*
  - **Alcanzable (A):** ¿tienes los recursos (tiempo, habilidades, dinero, apoyo) para lograrla? · ¿es un reto pero sigue siendo realista? · según tu situación actual, ¿qué probabilidad (0–100%) crees tener de lograrla? · *Verificación: ¿es realmente posible dadas tus limitaciones?*
  - **Relevante (R):** ¿esta meta está alineada con tu visión más grande o tus prioridades actuales? · ¿lograrla te acerca a tu dirección de largo plazo? · ¿es importante para tus necesidades o valores actuales? · *Verificación: ¿es significativa y está alineada con tus prioridades?*
  - **Con plazo definido (T):** ¿cuándo quieres completarla? · ¿tiene fecha límite o de revisión? · ¿se puede dividir en hitos (1 semana, 1 mes, 3 meses)? · *Verificación: ¿hay un plazo o fecha límite específica?*
  - Botón final: **"Crear seguimiento para esta Meta."**
  - Al terminar, se muestra una **pantalla resumen** que repite cada bloque S.M.A.R.T. con las respuestas ya dadas (más el badge de la skill relacionada), para que el usuario verifique todo antes de confirmar con el mismo botón "Crear seguimiento para esta Meta" (el usuario compartió una referencia visual de esta pantalla).
- **Upcoming Event:** eventos con prioridad, fecha y contacto asociado.
- **Daily Highlight:** vista de "próxima acción" organizada por prioridad (Urgent, High, Medium, Low, Pending), con nivel y recompensa por tarea individual.
- **Calendario integrado** (Week/Month): cada tarea/proyecto aparece en su fecha real con badges de estado (Completed, In progress, Do it now!, EXPIRED).
- **Projects:** tarjetas con conteo de tareas por estado, % de progreso y advertencias como "No area assigned" si el proyecto no está vinculado a un Área.
- **Goals:** organizados por periodo (ej. Q4), creados aquí mismo con el **S.M.A.R.T. Diagnosis Tool**. Es la **única** vista periódica de metas.
- **Areas:** cada una es una skill creada por el usuario (no una lista predefinida), con su propio nivel/barra de progreso (la misma de la skill), barra de project status (avance agregado), conteo Not Started / In Progress / Completed / Total, y división interna entre Goals y Projects asignados.

**Flujo del módulo:** Brain Dump / Evento → Task → Project → Area (el Área/skill sube de nivel).

### Estadísticas y analíticas
Pantalla **Estadísticas** (desde el Perfil y el Diario), por semana o por mes: XP ganada, misiones, tiempo en la Mazmorra y racha (cada uno comparado con el periodo anterior); XP por día con vista de tabla; XP por Área; cumplimiento de misiones; hábitos más constantes; y 3 observaciones de RPGenie. El Mapa de calor sigue en Hábitos.

### 🔧 Sistema de recomendaciones → "RPGenie"
Asistente de IA (**Fase 4**) que sugiere la siguiente misión según las metas del usuario y su Vision Board, y que también afina el cálculo de prioridad de los proyectos grandes y la estimación de recompensa (que antes funcionan con reglas simples). No agrega complejidad nueva al plan, solo le da identidad y funciones concretas.

**Vista "Misión actual":** pantalla dedicada donde se muestra la **misión que la IA tiene activa para ti ahora mismo** — qué hacer, de qué apartado viene, su recompensa y **por qué la eligió** — con acceso directo para empezarla en la Mazmorra, "Ya la hice" y "Ahora no" (estoy cansado / poco tiempo / no es prioridad / ya no quiero hacerla), que cambia la misión sin castigo. Se entra desde "¿Por qué esta?" en Inicio.

**Cómo prioriza (propuesta):** 1) lo que vence antes, 2) lo que más daño hace a los jefes activos, 3) si el usuario dice que está cansado o con poco tiempo, lo más ligero.

**Rol en la Taverna:** RPGenie es quien **diseña las misiones de los NPCs**, ajustándolas a la situación exacta y a la meta actual del usuario.


### 🆕 Configuración / "Game Master"
Panel de ajustes (dentro de Perfil) donde el usuario define sus propias reglas: **apariencia** (modo claro/oscuro/automático y tema Bosque/Río/Brasa/Oro, aplicados a toda la app), **dificultad general** (Fácil/Normal/Difícil — solo se cambia aquí), **notificaciones** (límite diario opcional, ventana de silencio opcional), escala de urgencia y **cuenta** (cambiar contraseña, **cerrar sesión** con confirmación). Refuerza la autonomía real del usuario sobre las reglas del sistema, no solo sobre sus tareas.

### Sistema social (opcional)
Módulo opcional de fase avanzada: espacio de comunidad/chat para compartir progreso y logros, no solo rankings. ⏸️ **Modo cooperativo/gremio en pausa:** el proyecto se centra por ahora exclusivamente en la experiencia de un solo usuario.

### 🔧 Notificaciones (diseño anti-estrés)
Cubre recordatorios de misión, racha en riesgo, cercanía a subir de nivel y cambio de prioridad de proyecto, con un diseño explícito para que se sientan importantes **sin estresar** al usuario — uno de los puntos fuertes de la app:

**Niveles de prioridad:**
- **Crítica:** racha real a punto de romperse (últimas horas del día), cambio de proyecto a prioridad 🔴 Alta. Se entrega sola y puede saltarse la ventana de silencio si el usuario lo permitió explícitamente.
- **Motivacional:** cerca de subir de nivel, logro desbloqueado, hito de meta S.M.A.R.T. Se entrega en el momento, pero nunca se repite si se ignora.
- **Informativa:** recordatorio de misión diaria, resumen de hábitos, resumen del día. Se agrupa en un **digest** (mañana o noche).

**Reglas anti-estrés:**
- **Límite diario:** **sin límite fijo por defecto** — configurable en Game Master si el usuario quiere uno.
- **Ventana de silencio:** **sin ventana por defecto** — el usuario la define desde Game Master si la quiere (ej. 10pm–7am); solo pasarían las Críticas mientras esté activa.
- Silencio automático durante una sesión activa de Mazmorra/Deep Working, salvo Crítica.
- **Frecuencia decreciente:** si el usuario ignora el mismo tipo de notificación **5 veces seguidas**, su frecuencia baja sola (regla simple al inicio; RPGenie la afina en Fase 4).
- Ningún evento se notifica dos veces.

**Tono:** usa la aversión a la pérdida pero enmarcada como invitación, nunca como amenaza o culpa — ej. *"Tu racha de 12 días te está esperando 🔥"* en vez de *"¡Vas a perder tu racha!"*.

**Diseño:** centro de avisos (campana en Inicio, con contador) con pestañas Todos / Importantes y "Marcar todo como leído"; cada aviso lleva a su pantalla. En pantalla los niveles se muestran como **▲ Crítico · ● Importante · ○ Informativo** ("Importante" agrupa lo motivacional y los eventos próximos), siempre con símbolo + texto. Incluye guía de tono "Así sí / Así no".

### Sistema anti-trampa 🔧
Incluye: límite de usos/cooldown del Pase de Recuperación y del "Recuperar racha", cooldown de "Pedir misión al momento" en la Taverna, y validación para que la recompensa sugerida automáticamente no se pueda inflar editando repetidamente la descripción de una tarea. **Añadido con la economía:** XP por tarea acotada (10–40), tareas completadas a menos de 2 min de crearlas dan el mínimo y 0 Monedas, máximo 15 tareas con Monedas al día, tope suave diario de Monedas y bolsa con límite.

### 🔧 Menú / Navegación principal
**Decisión de diseño — barra inferior de 5 pestañas:** **Inicio** (dashboard principal) · **Stage** · **Hábitos** · **Mazmorra** · **Perfil**. El resto se abre desde ellas: Taverna, Brain Dump, Misión actual, Boss Fight y Avisos desde Inicio; Diario, Estadísticas, Vision Board, Inventario y logros, Marketplace y Configuración desde Perfil. Antes de entrar: Iniciar sesión / Registro / Recuperar contraseña y Onboarding de 5 pasos.

Contenido (lista original, ahora repartida en esas pestañas):
1. **Perfil del Personaje** — nivel, monedas, HP, identidad, tasa de finalización, progreso del nivel actual, **skills/Áreas integradas**, y acceso a **Inventario/Logros** y **Configuración (Game Master)**.
2. **RPGenie — Misión actual** — la misión activa recomendada por la IA *(aparece en Fase 4)*.
3. **Stage · P.A.R.A. (GTD)** — centro de mando y dashboard de tareas: aquí viven las **misiones actuales** (Tasks, Projects, Goals, Areas, Resources, Archive, Events, calendario — según la fase).
4. **Diario** — Bitácora (historial de misiones).
5. **Hábitos** — Buenos (recompensa) y Malos (penalización), con Estadísticas de crecimiento y Mapa de calor.
6. **Mazmorras / Deep Working** — sesiones de concentración en un entorno limpio de flujo.
7. **Objetivos** — Goal → Boss Fight + Objetivos de Crecimiento (S.M.A.R.T.), con acceso directo a Goals de P.A.R.A.
8. **Taverna** — creación de NPCs y sus misiones *(aparece en Fase 4)*.
9. **Marketplace — Reward** — carrito, Mis compras, Hotel (recuperar vida), Mercado, Mercado negro, Refugio.

---

## 🧠 Fundamentos psicológicos y de diseño

| Teoría / Framework | Aplicación en la app |
|---|---|
| Autodeterminación (Deci & Ryan) | Autonomía al elegir misiones y reglas propias (Game Master) y al crear sus propias skills; competencia vía niveles del personaje y de cada skill/Área; relación vía módulo social/comunidad |
| Modelo de Fogg | Descomposición Proyecto/Tarea/subtareas; GTD Diagnosis Tool y Brain Dump; notificaciones como disparador |
| Fijación de metas (Locke & Latham) | S.M.A.R.T. Diagnosis Tool; recompensa explícita por tarea (estimada por RPGenie) y vínculo visible tarea → proyecto → meta |
| Efecto Zeigarnik | Barras de progreso parciales, recordatorios de misiones inconclusas |
| Refuerzo de razón variable (Skinner) | Misiones de NPCs con recompensa variable (XP/Monedas). *Las recompensas cosméticas sorpresa quedan en pausa junto con Personalización.* |
| Teoría del Flow | Dificultad ajustable (Fácil/Normal/Difícil); entorno Deep Working para entrar en estado de flujo |
| Intenciones de implementación (Gollwitzer) | Campo opcional de "cuándo y dónde" al crear tarea/hábito |
| Bucle del hábito (Duhigg) | Señal (notificación) → rutina (Mazmorra/tarea) → recompensa (XP/Monedas) |
| Aversión a la pérdida (Kahneman & Tversky) | Rachas con Pase de Recuperación y HP/Vitalidad agregada, nunca punitivos de golpe |
| Octalysis Framework (Yu-Kai Chou) | Marco transversal: Vision Board (Significado Épico), skills/Áreas y Bosses (Logro), Game Master y creación de skills (Empoderamiento de Creatividad), Inventario/Tienda (Titularidad), Comunidad (Influencia Social), Mercado negro con objetos limitados (Escasez), misiones de NPCs (Imprevisibilidad), Pase de Recuperación y HP (Evitación de Pérdida) |
| G.T.D. (David Allen) | Brain Dump + GTD Diagnosis Tool (MVP); Quick Add, Daily Highlight, calendario y organización del día a día en Stage · P.A.R.A. |
| Criterio S.M.A.R.T. | S.M.A.R.T. Diagnosis Tool dentro de Stage · P.A.R.A.: validador de metas con diagnóstico escrito y pantalla resumen |

## ⚖️ Principio ético

Ninguna mecánica debe existir solo para que el usuario abra más la app — debe reforzar comportamiento productivo real. Por eso el HP no mata al personaje, el Pase de Recuperación tiene límites, y las recompensas variables no son apuestas. Se evitan patrones oscuros ("dark patterns").

---

## 🏗️ Arquitectura / Datos / Stack

- **Módulos activos:** Productividad, RPG, Marketplace/Reward, Analíticas. *(⏸️ Finanzas / Vault Financiero en pausa.)*
- **Entidades base:** User, Task, Habit, FocusSession, Mission, Achievement, InventoryItem, UserStats, UserLevel, Notification, Challenge.
- **Entidades añadidas:** Wallet/Currency (Monedas), MarketItem, PurchaseOrder/CartItem, VisionBoard, BrainDumpEntry, Companion/NPC, NpcMission, GameMasterSettings (incluye dificultad, apariencia y preferencias de notificación), VitalityStat (HP), PlayerIdentity, QuestLogEntry (alimenta la Bitácora y las Estadísticas), RefugeUpgrade (mejoras del Refugio), Treasury (Tesoro del reino), DailyCoinLedger (control del tope diario), **Skill/Area** (una sola entidad: skill creada por el usuario con nivel propio = Área de P.A.R.A.), Goal (metas S.M.A.R.T., con vínculo desde Task y desde Project), Project, Resource, CalendarEvent, HabitRecord (registros de buenos/malos hábitos).
- **⏸️ Entidades en pausa (Vault Financiero):** VaultAccount, VaultTransaction, Budget, FinancialGoal, WishlistItem.
- **Stack considerado:** Flutter/Dart (frontend); Node.js+Express, Supabase o Firebase (backend); PostgreSQL o Firestore (BD).

## 🚀 MVP y fases 🔧 *(reorganizado — Oct 2026)*

Criterio: cada fase solo usa cosas que ya existen en fases anteriores.

- **MVP — Núcleo jugable:** registro/login (+ recuperar contraseña y cerrar sesión), **Onboarding**, **Perfil del Personaje** (nivel, monedas, identidad, tasa de finalización, progreso de nivel), tareas y subtareas, XP, niveles, **Monedas básicas** (mismo evento que da XP), **skills/Áreas básicas** (crear hasta 6, asignar a tareas, subir de nivel), hábitos buenos, rachas, **Mazmorras / Deep Working** (entorno básico), **Brain Dump + GTD Diagnosis Tool**, **Stage · P.A.R.A. básico** (Quick Add + Daily Highlight, donde viven las misiones actuales), **Diario — Bitácora** (historial de misiones), logros.
- **Fase 2 — Metas y Gamificación:** Proyectos con priorización automática por reglas + notificación de cambio de urgencia, **Goals + S.M.A.R.T. Diagnosis Tool** (vista Goals de P.A.R.A.), Módulo Goal → Boss Fight, Objetivos de Crecimiento, HP/Vitalidad, malos hábitos, Sistema de Dificultad, Pase de Recuperación, **Marketplace** (carrito, My Purchases, Hotel, Mercado negro), estimación de recompensa por reglas, sistema de notificaciones anti-estrés.
- **Fase 3 — Experiencia y Organización:** Vision Board, Estadísticas + Mapa de calor, Refugio, modo oscuro y temas, **Stage · P.A.R.A. completo** (Areas con conteos, Resources, Archive, Calendario, Upcoming Events).
- **Fase 4 — Inteligencia:** **RPGenie** (Misión actual, priorización e estimación de recompensa con IA, observaciones de Estadísticas, frecuencia de notificaciones) y **Taverna** (NPCs con misiones generadas por RPGenie).
- **Fase 5 — Social:** Comunidad/chat.
- **⏸️ En pausa (sin fase asignada):** Vault Financiero, Personalización (avatar, temas visuales, cosméticos), modo cooperativo/gremio.

> **Nota:** esta reorganización es una propuesta para eliminar las dependencias rotas de la versión anterior (Goals y S.M.A.R.T. quedaban en Fase 6 aunque Boss Fight estaba en Fase 3; Taverna en Fase 3 dependía de RPGenie en Fase 5; no había Fase 1 ni 2). El equipo puede mover piezas mientras respete el criterio de arriba.

## 💰 Monetización

Freemium. Premium futuro: más de 6 skills, estadísticas avanzadas, IA (RPGenie avanzado) y, si se retoma, personalización. Visión largo plazo: B2B (vender el sistema de gamificación como servicio a otras apps).

## 🏷️ Nombres posibles

Questly · LifeQuest · LevelUp

---

## 📌 Pendientes / ideas por explorar

**Abiertos:**
- Definir la fórmula exacta de "ritmo necesario" (¿ritmo histórico del usuario o valor fijo por defecto al inicio?).
- **Confirmar las propuestas del diseño:** umbral de debilitado (30 de vida, −25 % XP), 48 h para recuperar una racha, multiplicadores de dificultad y orden de prioridad de la Misión actual.
- **Validar la economía con usuarios reales** el primer mes (métricas en la sección Economía estable) y definir el catálogo del Mercado negro para los próximos 6 meses.
- **Bitácora:** ¿notas propias del usuario? ¿filtro por skill/Área?
- Duración por defecto del descanso en Deep Working (¿descanso largo también para ciclos de 30/45 min?).
- **GTD Diagnosis Tool, pregunta 4 ("¿soy la persona correcta?"):** propuesta — si es "no", convertirla en **Evento con contacto** (quién debe hacerlo y cuándo seguir). Falta confirmar.
- Confirmar la **reorganización de fases** propuesta en Oct 2026.

**En pausa:**
- ⏸️ Enfoque de **Personalización visual** (arte específico vs. modelos generativos, etc.).
- ⏸️ Tipo de cambio Monedas ↔ dinero real en el Vault Financiero (y rediseño de su conexión con el Marketplace, ya que dependía de las autorecompensas).
- ⏸️ Modo cooperativo/gremio.

**Resueltos:**
- ~~Reemplazo de las autorecompensas y catálogo del Marketplace~~ → Hotel, Mercado, Mercado negro rotativo, Refugio y Tesoro del reino, con precios fijos (ver Economía estable).
- ~~Precios y cooldowns del Hotel, Mercado negro y Pase~~ → definidos en la sección Marketplace.
- ~~Qué afecta la Dificultad~~ → XP y vida perdida; las Monedas son iguales en todas.
- ~~Inventario/Logros: ¿Perfil o Diario?~~ → Perfil.
- ~~Diario del Héroe~~ → eliminado; el Diario es solo la Bitácora.
- ~~Cómo prioriza la Misión actual~~ → propuesta: vencimiento → daño a jefes → energía del usuario (falta confirmar).
- ~~Ajustes al Boss Fight~~ → diseñado (ataques, victoria y "el jefe escapó").
- ~~Tiempo estimado y dificultad por tarea~~ → eliminados; la XP la calcula RPGenie.
- ~~Niveles de urgencia~~ → 3 niveles 🟢/🟡/🔴 como escala única, ajustable desde Game Master.
- ~~Sistema de "energía" para rachas~~ → Pase de Recuperación.
- ~~Penalización de HP por plazo incumplido y por sesión incompleta~~ → valor fijo para todo plazo; en Deep Working, valor inicial que baja según el avance.
- ~~Penalización de HP por mal hábito~~ → valor fijo.
- ~~Árbol de habilidades vs. Áreas de P.A.R.A.~~ → sistema unificado: la skill **es** el Área.
- ~~Cantidad de skills y tope de nivel~~ → máximo 6 (más con suscripción), sin tope de nivel.
- ~~Sub-habilidades por rama del árbol de atributos~~ → ya no aplica: sin atributos fijos.
- ~~Deep Working como panel aparte~~ → contenedor de sesión; Mazmorras son sus ciclos.
- ~~Valores por defecto de notificaciones~~ → sin límite diario ni ventana de silencio por defecto; umbral de "ignorar" en 5 veces.
- ~~Nivel "Historia"~~ → eliminado.
- ~~Vocabulario de estados Boss Fight / S.M.A.R.T. / P.A.R.A.~~ → un solo estado real con distinta piel cosmética; "Objetivo Personal" fusionado con Goals.
- ~~Posición en fases de S.M.A.R.T. y P.A.R.A.~~ → P.A.R.A. se construye por partes (MVP / Fase 2 / Fase 3); S.M.A.R.T. en Fase 2 (propuesta Oct 2026).
- ~~Formato de las entradas del Historial de Misiones~~ → definido en la Bitácora del Diario (fecha, estado, recompensa/penalización, origen, filtros); solo quedan abiertos los filtros finos.

## 📝 Historial de cambios

- **Oct 2026 — Cierre del diseño de la app y economía estable:** (1) Se diseñan 60 tableros (pantallas, variantes y documentación) en el lienzo "Questly — Diseño de la app", con sistema de diseño «Bosque vivo», modo oscuro y 4 temas, y especificación para desarrollo. (2) **Economía estable:** Monedas = 30 % de la XP, tope suave diario (50 + 25), bolsa de 400 + 25/nivel con Tesoro del reino, precios fijos anclados al "día de juego", Refugio con precio creciente y nuevas reglas anti-trampa; validada con una simulación de 180 días. (3) Catálogo del Marketplace definido (Hotel, Mercado, Mercado negro, Refugio). (4) **Diario del Héroe eliminado**; Inventario/Logros en Perfil. (5) **Tareas sin tiempo estimado ni dificultad**; RPGenie calcula la XP (10–40) y las tareas se vinculan a Proyecto o Meta. (6) **Dificultad solo en Configuración**, con multiplicadores de XP y vida. (7) Propuestas de HP debilitado, racha (48 h) y prioridad de la Misión actual. (8) Navegación de 5 pestañas, Onboarding, acceso/cierre de sesión, Mochila de la Mazmorra, Taverna, Estadísticas, Notificaciones y estados vacíos/de error documentados.

- **Oct 2026 — Revisión de coherencia general:** (1) **Vault Financiero** retirado de Arquitectura, entidades activas y fases (queda en "en pausa"; se anota que su flujo dependía de las autorecompensas). (2) **Autorecompensas:** se quitan sus restos en Fase 3, en el Marketplace ("lo define el propio usuario") y en Game Master; el catálogo queda pendiente junto con su reemplazo. (3) **Personalización:** se quita "Temas visuales" de las fases, se ajusta Monetización, y se actualizan las filas de Skinner y Octalysis que dependían de cosméticos sorpresa. (4) **Fundamentos:** S.M.A.R.T. apunta ahora a Stage · P.A.R.A.; Octalysis y Autodeterminación usan skills/Áreas. (5) **Fases reorganizadas** (MVP → Fase 5, sin saltos): skill básica en el MVP, Stage básico en el MVP (porque ahí viven las misiones), Goals + S.M.A.R.T. en Fase 2 junto a Boss Fight, Taverna junto a RPGenie en Fase 4, P.A.R.A. completo en Fase 3. (6) **Diario** documentado como sección propia (Bitácora + Diario del Héroe sobre los mismos registros) con la explicación de su alcance. (7) Menú y MVP alineados (Misiones ya no es ítem propio). (8) Encabezado de "Última actualización" acortado; se renombra el clasificador a "GTD Diagnosis Tool" para distinguirlo del S.M.A.R.T. Diagnosis Tool. (9) Pendientes reorganizados en Abiertos / En pausa / Resueltos.

- **Sept 2026 — Traducción del S.M.A.R.T. Diagnosis Tool y solución a la duplicidad Objetivo Personal/Goals:** (1) se traduce al español el formulario y las pantallas del S.M.A.R.T. Diagnosis Tool y los estados del módulo Growth. (2) Se elimina la vista "Objetivo Personal" como pantalla aparte; "Goals" de P.A.R.A. pasa a ser la única vista periódica de metas. (3) Un solo estado real por objetivo (Sin iniciar/En progreso/Completada/Vencida), con una "piel" cosmética distinta según la pantalla.

- **Sept 2026 — S.M.A.R.T. Diagnosis Tool se muda a Stage · P.A.R.A.:** deja de vivir solo en el Módulo Growth y pasa a ser un botón dentro de Stage · P.A.R.A., en paralelo al GTD Diagnosis Tool. Se detalla el formulario completo y la pantalla resumen de verificación (el usuario compartió una referencia visual).

- **Sept 2026 — Valores por defecto de Notificaciones:** sin límite diario fijo, sin ventana de silencio por defecto (ambos opcionales desde Game Master), umbral de "ignorar repetidamente" en 5 veces seguidas.

- **Sept 2026 — Ronda de respuestas a pendientes:** escala de urgencia 🟢/🟡/🔴; modo cooperativo pausado; HP por plazo incumplido con valor fijo y penalización proporcional en Deep Working; máximo 6 skills sin tope de nivel; HP por mal hábito con valor fijo; nuevo **Sistema de Dificultad** (Fácil/Normal/Difícil).

- **Sept 2026 — Recorte de alcance y fusión skill = Área:** se eliminan los 4 atributos fijos y la skill pasa a ser el Área de P.A.R.A.; HP penaliza plazos incumplidos y sesiones incompletas; se eliminan las autorecompensas; Financial Vault pausado; Personalización reducida; Boss Fight marcado para ajustes al final; Menú reestructurado (sin Vault, Inventario/Logros y Configuración en Perfil, Misiones en Stage, nuevo Diario).

- **Sept 2026 — Corrección de incoherencias metodológicas:** se elimina el nivel "Historia"; "Boss" reservado para Metas; Diagnosis Tool rediseñado como clasificador Tarea/Proyecto/Meta (GTD + Horizons of Focus) y adelantado al MVP; Stage · P.A.R.A. redefinido como vista/dashboard sobre las mismas entidades.

- **Sept 2026 — Fusión Mazmorras + Deep Working:** Deep Working es el contenedor de la sesión y las Mazmorras sus ciclos Pomodoro con descansos cronometrados, con pausa, salto de descanso, cierre anticipado y resumen final.

- **Sept 2026 — Sistema de notificaciones anti-estrés:** niveles de prioridad (Crítica / Motivacional / Informativa), digest, ventana de silencio, silencio en Mazmorras, frecuencia decreciente y tono de invitación.

- **Sept 2026 — Resolución árbol RPG vs. Áreas P.A.R.A.:** se decidió que eran sistemas paralelos *(decisión revertida después: skill = Área)*.

- **Sept 2026 — Fusión de perfil:** el árbol de habilidades se integra dentro del Perfil del Personaje.

- **Sept 2026 — Módulos de recompensa, finanzas y enfoque:** se agregan Marketplace — Reward, Módulo Financial Vault y Módulo Deep Working.

- **Sept 2026 — Ampliación de diseño por el equipo:** Perfil del Personaje, skills con nivel propio, Historial de Misiones, RPGenie con "Misión actual", Taverna, hábitos buenos/malos con estadísticas y mapa de calor, Goal → Boss Fight, Growth S.M.A.R.T., Stage · P.A.R.A. y estructura de menú.

- **Sept 2026:** Documento creado con el estado consolidado del proyecto tras la propuesta académica.
- **Sept 2026:** Ideas de investigación externa ("LiFE RPG" en Notion y Octalysis Framework): economía dual XP/monedas, pase de recuperación, HP, vision board, brain dump, temas visuales, y más.
- **Sept 2026:** Ideas de IA de LiFE RPG 2.0: RPGenie, recomendación automática de recompensa y Companion Hall (NPCs).
- **Sept 2026 — Integración completa:** todas las funciones investigadas se fusionan con el diseño principal; se descarta la "energía" para rachas; se suaviza la "muerte del personaje" a un estado "debilitado" recuperable.
