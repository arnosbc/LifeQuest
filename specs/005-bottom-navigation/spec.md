# Feature Specification: Navegación principal de 5 pestañas

**Feature Branch**: `005-bottom-navigation`

**Created**: 2026-10-20

**Status**: Draft

**Input**: User description: "Navegación principal con barra inferior de 5 pestañas: Inicio · Stage · Hábitos · Mazmorra · Perfil (docs/ideas-proyecto-productividad-gamificada.md → Menú / Navegación principal). Misiones pasa a vivir dentro de Stage; Dungeon se llama Mazmorra. Las demás secciones se abren desde Inicio o Perfil. El botón Atrás del sistema siempre funciona y cada pestaña conserva su estado. Sin rediseño visual."

## Contexto

El documento de diseño fija una barra inferior de 5 pestañas: **Inicio · Stage · Hábitos · Mazmorra · Perfil**. El resto se abre desde ellas:

- **Desde Inicio:** Taverna, Brain Dump, Misión actual (RPGenie), Boss Fight y Avisos.
- **Desde Perfil:** Diario, Estadísticas, Vision Board, Inventario y logros, Marketplace y Configuración (los accesos del Perfil los define la spec 004).

Hoy la barra es **Inicio · Misiones · Dungeon · Hábitos · Perfil**, y Stage es una sección aparte que se abre desde Inicio. Ya cada pestaña recuerda su propio recorrido; esta función cambia qué pestañas hay, su orden y sus nombres, y dónde se abre cada sección. No se rediseña nada: se usan la barra y los componentes visuales actuales.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Las 5 pestañas del diseño (Priority: P1)

Como jugador, quiero una barra inferior con Inicio, Stage, Hábitos, Mazmorra y Perfil, para llegar en un toque a lo que uso cada día.

**Why this priority**: es el esqueleto de la app; el resto de pantallas del diseño cuelgan de estas 5.

**Independent Test**: abrir la app tras iniciar sesión y tocar cada pestaña.

**Acceptance Scenarios**:

1. **Given** la app abierta, **Then** la barra muestra 5 pestañas en este orden y con estos nombres: Inicio, Stage, Hábitos, Mazmorra, Perfil.
2. **Given** cualquier pestaña, **When** toca otra, **Then** se abre esa pestaña y queda marcada como activa (con símbolo y texto, no solo color).
3. **Given** la barra, **Then** ya no aparecen las pestañas «Misiones» ni «Dungeon».
4. **Given** la pestaña Mazmorra, **Then** abre la pantalla de sesión de concentración actual, con el nombre «Mazmorra» en todos los textos visibles.

---

### User Story 2 - Misiones dentro de Stage (Priority: P1)

Como jugador, quiero encontrar mis misiones dentro de Stage, el centro de mando, sin perderlas al quitar su pestaña.

**Why this priority**: al quitar la pestaña Misiones, la lista de misiones tiene que seguir a un toque de distancia.

**Independent Test**: abrir Stage, entrar a Misiones, volver a Stage.

**Acceptance Scenarios**:

1. **Given** la pestaña Stage, **Then** ve la pantalla de Stage actual con un acceso visible a Misiones.
2. **Given** Stage, **When** toca Misiones, **Then** se abre la pantalla de misiones actual dentro de la pestaña Stage, con la barra inferior visible y Stage marcada.
3. **Given** Misiones abierta, **When** pulsa Atrás, **Then** vuelve a Stage.
4. **Given** un enlace antiguo a Misiones, **When** se abre, **Then** lleva a Misiones dentro de Stage, sin error.

---

### User Story 3 - Cada pestaña recuerda dónde estaba (Priority: P1)

Como jugador, quiero que al cambiar de pestaña y volver encuentre la pantalla y el desplazamiento donde lo dejé.

**Why this priority**: perder el sitio al cambiar de pestaña obliga a repetir pasos y rompe el foco.

**Independent Test**: entrar a Misiones dentro de Stage y bajar la lista, ir a Hábitos, volver a Stage.

**Acceptance Scenarios**:

1. **Given** Misiones abierta dentro de Stage y la lista desplazada, **When** va a Hábitos y vuelve a Stage, **Then** sigue en Misiones en el mismo punto de la lista.
2. **Given** una pestaña con pantallas abiertas encima de su pantalla inicial, **When** toca otra vez esa misma pestaña, **Then** vuelve a su pantalla inicial.
3. **Given** una sesión de Mazmorra en curso, **When** cambia a otra pestaña y vuelve, **Then** la sesión sigue en curso, con el mismo tiempo restante.

---

### User Story 4 - El botón Atrás siempre funciona (Priority: P1)

Como jugador, quiero que el botón Atrás del sistema siempre haga algo predecible: nunca quedarme atrapado ni salir de la app sin querer.

**Why this priority**: un Atrás que no responde o que cierra la app por sorpresa es de los errores de navegación más frustrantes.

**Independent Test**: recorrer cada pestaña y cada sección abierta desde Inicio y Perfil pulsando Atrás hasta salir.

**Acceptance Scenarios**:

1. **Given** una pantalla abierta encima de otra (dentro de una pestaña o una sección), **When** pulsa Atrás, **Then** vuelve a la pantalla anterior.
2. **Given** la pantalla inicial de Stage, Hábitos, Mazmorra o Perfil, **When** pulsa Atrás, **Then** va a Inicio.
3. **Given** la pantalla inicial de Inicio, **When** pulsa Atrás, **Then** sale de la app como cualquier app del teléfono.
4. **Given** una hoja o diálogo abierto, **When** pulsa Atrás, **Then** se cierra solo la hoja o el diálogo.
5. **Given** cualquier pantalla de la app, **Then** pulsar Atrás nunca deja de responder.

---

### User Story 5 - Las demás secciones desde Inicio y Perfil (Priority: P2)

Como jugador, quiero abrir las demás secciones desde Inicio o Perfil, como dice el diseño, sin buscarlas en varios sitios.

**Why this priority**: ordena la app según el diseño; las pantallas destino pueden seguir siendo de ejemplo.

**Independent Test**: tocar cada acceso de Inicio y comprobar a dónde lleva.

**Acceptance Scenarios**:

1. **Given** Inicio, **Then** ofrece accesos a Taverna, Brain Dump, Misión actual, Boss Fight y Avisos.
2. **Given** un acceso con pantalla actual (Taverna, Misión actual, Boss Fight, Avisos), **When** lo toca, **Then** abre esa pantalla y Atrás vuelve a Inicio.
3. **Given** un acceso sin pantalla todavía (Brain Dump), **When** lo toca, **Then** ve el aviso de «próximamente» que la app ya usa, sin error.
4. **Given** Inicio, **Then** ya no ofrece Stage (es una pestaña), Diario ni Marketplace (se abren desde Perfil).

---

### Edge Cases

- Sesión cerrada o vencida mientras está en una pestaña: va al inicio de sesión como hoy, y al volver a entrar empieza en Inicio.
- Primer inicio de sesión con el Onboarding pendiente (spec 003): el Onboarding va antes de la barra; al terminarlo empieza en Inicio.
- Girar el teléfono o pasar la app a segundo plano: al volver, cada pestaña conserva su estado.
- Letra del sistema muy grande: los 5 nombres siguen legibles sin cortarse ni solaparse.
- Lector de pantalla: cada pestaña anuncia su nombre, su posición («2 de 5») y si está seleccionada.
- Tocar dos pestañas muy rápido: queda abierta la última, sin pantallas duplicadas.
- La Mazmorra en sesión silencia la navegación extra (CLAUDE.md §8): esta función no añade ruido nuevo dentro de una sesión.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: La barra inferior MUST tener exactamente 5 pestañas, en este orden: Inicio, Stage, Hábitos, Mazmorra, Perfil.
- **FR-002**: Todo texto visible que hoy dice «Dungeon» en la navegación MUST decir «Mazmorra».
- **FR-003**: Stage MUST ser una pestaña y MUST NOT abrirse además como sección aparte desde Inicio.
- **FR-004**: Misiones MUST abrirse desde Stage, dentro de la pestaña Stage, con la barra visible.
- **FR-005**: Los enlaces antiguos a Misiones y a la Mazmorra MUST seguir funcionando y llevar a su nuevo sitio.
- **FR-006**: Cada pestaña MUST conservar su pantalla abierta, su desplazamiento y su estado al cambiar de pestaña y volver, y al pasar la app a segundo plano.
- **FR-007**: Tocar la pestaña activa MUST volver a su pantalla inicial.
- **FR-008**: El botón Atrás del sistema MUST: cerrar la hoja o diálogo abierto; si no hay, volver a la pantalla anterior; si está en la pantalla inicial de una pestaña distinta de Inicio, ir a Inicio; si está en la pantalla inicial de Inicio, salir de la app.
- **FR-009**: Inicio MUST ofrecer accesos a Taverna, Brain Dump, Misión actual, Boss Fight y Avisos; los que no tienen pantalla MUST mostrar el aviso de «próximamente» actual.
- **FR-010**: Las secciones abiertas desde Inicio o Perfil MUST volver con Atrás a la pestaña desde la que se abrieron, en el estado en que estaba.
- **FR-011**: La navegación MUST cumplir WCAG 2.1 AA: zonas táctiles amplias, la pestaña activa marcada con símbolo y texto además del color, y nombres y posición anunciados al lector de pantalla.
- **FR-012**: MUST usarse la barra y los componentes visuales actuales; no se crean colores, fuentes ni componentes nuevos.
- **FR-013**: La navegación MUST tener pruebas automáticas: orden y nombres de las pestañas, Misiones dentro de Stage, conservación del estado entre pestañas, cada caso del botón Atrás y los enlaces antiguos.

### Key Entities

- **Pestaña**: una de las 5 entradas de la barra, con su nombre, su pantalla inicial y su propio recorrido de pantallas abiertas.
- **Sección**: pantalla que no es pestaña (Taverna, Brain Dump, Misión actual, Boss Fight, Avisos, Diario, Estadísticas, Vision Board, Inventario y logros, Marketplace, Configuración) y que se abre desde Inicio o Perfil.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Cada una de las 5 pestañas se abre con 1 toque desde cualquier otra.
- **SC-002**: Misiones se abre en 2 toques o menos desde cualquier pestaña.
- **SC-003**: En el 100 % de los recorridos probados, el botón Atrás responde y nunca saca de la app salvo desde la pantalla inicial de Inicio.
- **SC-004**: Volver a una pestaña muestra la misma pantalla y el mismo punto de desplazamiento en el 100 % de los casos probados.
- **SC-005**: Ninguna sección del diseño queda sin camino: todas se alcanzan desde una pestaña, Inicio o Perfil.

## Assumptions

- Ya existe una barra de 5 pestañas que recuerda el recorrido de cada una; aquí cambian las pestañas, sus nombres y dónde se abren las secciones.
- Stage, Misiones y las secciones siguen siendo pantallas de ejemplo; esta función no las conecta a datos.
- Misiones se abre desde un acceso en Stage, sin cambiar el contenido de la pantalla de Stage.
- Las secciones abiertas desde Inicio o Perfil se muestran como hoy (pantalla completa con botón de volver); no se meten dentro de la pestaña.
- Boss Fight es la pantalla actual de Objetivos; Avisos es la pantalla actual de Notificaciones; Misión actual es la pantalla actual de RPGenie.
- Los accesos del Perfil y la mudanza de Apariencia a Configuración los define la spec 004; esta spec solo exige que existan.
- Los iconos de las pestañas se reutilizan del conjunto actual: Stage toma un icono de tablero y Mazmorra conserva el actual.
- Se quitan de Inicio los accesos a Stage, Diario y Marketplace para no duplicar caminos; si el equipo prefiere conservarlos, es un cambio de una línea.
- RF-114 y el inventario de §5 de CLAUDE.md se actualizan para reflejar la barra de 5 pestañas (deuda documental §12).
