# Feature Specification: Actualización del Perfil (vitalidad, Tesoro, títulos y accesos)

**Feature Branch**: `004-profile-update`

**Created**: 2026-10-20

**Status**: Draft

**Input**: User description: "Actualiza la spec de Perfil: (1) el aviso de vitalidad baja dice «−25 % de XP» con vida por debajo de 30; las Monedas no bajan; (2) se muestran el Tesoro del reino y el título activo bajo el nombre, y el usuario puede elegir uno de los títulos que ya ganó (nunca comprarlos); (3) los accesos desde Perfil son Diario, Estadísticas, Vision Board, Inventario y logros, Marketplace y Configuración (llevan a sus pantallas actuales aunque sean de ejemplo). Requiere que profile_overview devuelva el Tesoro, el título activo y los títulos ganados (nueva migración). Sin rediseño visual."

## Contexto

El Perfil ya muestra el personaje, su vitalidad, sus Monedas y sus skills con datos reales. Desde el cierre del diseño (oct 2026) cambiaron tres cosas que el Perfil todavía no refleja:

- **Debilitado:** la regla vigente es vida por debajo de 30 → −25 % de XP y nunca menos Monedas. El Perfil aún dice «ganas un 10 % menos», que era la regla anterior (≤ 20 % de vida, −10 % de XP y Monedas).
- **Prestigio:** las Monedas que no caben en la bolsa van al **Tesoro del reino**, y los **títulos de prestigio** se ganan (logros, nivel, Tesoro) y nunca se compran. El Perfil no muestra ninguno de los dos.
- **Navegación:** desde Perfil se abren Diario, Estadísticas, Vision Board, Inventario y logros, Marketplace y Configuración. Hoy los accesos son Vision Board, Inventario, Historial y Game Master.

No se rediseña nada: se usan los componentes visuales que ya tiene el Perfil.

## Clarifications

### Session 2026-10-20

- Q: ¿Apariencia se queda en Perfil o pasa a Configuración? → A: Pasa a Configuración: Configuración enlaza la pantalla de Apariencia actual y la fila se quita del Perfil.
- Q: ¿Qué se muestra si el jugador aún no ganó ningún título? → A: Nada bajo el nombre; la entrada para elegir título sigue visible y abre un estado vacío que explica cómo se ganan (logros, nivel, Tesoro).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Entender la vitalidad baja (Priority: P1)

Como jugador con poca vida, quiero que el aviso me diga exactamente qué pierdo y qué no, para no pensar que el juego me quita Monedas.

**Why this priority**: el aviso actual da una regla que ya no es la vigente; un mensaje equivocado sobre una penalización rompe la confianza en la economía.

**Independent Test**: dejar a un jugador con 29 de vida y otro con 30, abrir el Perfil y comparar los avisos.

**Acceptance Scenarios**:

1. **Given** un jugador con menos de 30 de vida, **When** abre el Perfil, **Then** ve un aviso que dice que gana un 25 % menos de XP hasta recuperarse y que sus Monedas no cambian.
2. **Given** un jugador con 30 de vida o más, **When** abre el Perfil, **Then** no ve el aviso.
3. **Given** el aviso visible, **Then** usa tono de invitación (cómo recuperarse), nunca de amenaza, y no depende solo del color.

---

### User Story 2 - Ver mi prestigio (Priority: P1)

Como jugador, quiero ver mi Tesoro del reino y mi título activo bajo mi nombre, para sentir el progreso que no se gasta.

**Why this priority**: el Tesoro y los títulos son la recompensa de largo plazo del diseño; sin mostrarlos, las Monedas que pasan al Tesoro parecen perdidas.

**Independent Test**: dar a un jugador Tesoro y un título activo y comprobar que el Perfil los muestra; a otro sin ninguno, que el Perfil no muestra huecos ni ceros confusos.

**Acceptance Scenarios**:

1. **Given** un jugador con título activo, **When** abre el Perfil, **Then** ve el nombre del título bajo su nombre.
2. **Given** un jugador sin título activo, **Then** no ve ningún título bajo su nombre (ni un texto vacío).
3. **Given** un jugador con Tesoro, **Then** ve su Tesoro del reino separado de las Monedas, con una explicación breve de que no se gasta.
4. **Given** un jugador con Tesoro 0, **Then** ve 0 con la misma explicación.

---

### User Story 3 - Elegir mi título (Priority: P2)

Como jugador, quiero elegir cuál de los títulos que ya gané se muestra, o no mostrar ninguno, sabiendo que los títulos se ganan y no se compran.

**Why this priority**: da autonomía sobre la identidad; depende de que existan títulos ganados.

**Independent Test**: dar a un jugador dos títulos ganados, elegir uno, luego el otro, luego «Sin título», y comprobar el Perfil tras cada cambio.

**Acceptance Scenarios**:

1. **Given** un jugador con títulos ganados, **When** abre la elección de título, **Then** ve solo los que ganó, con el activo marcado.
2. **Given** la elección abierta, **When** elige otro título, **Then** ese pasa a ser el activo y se ve bajo su nombre.
3. **Given** la elección abierta, **When** elige «Sin título», **Then** deja de mostrarse título.
4. **Given** un jugador sin títulos ganados, **Then** la entrada para elegir título sigue visible en el Perfil; **When** la abre, **Then** ve un estado vacío que explica cómo se ganan (logros, nivel, Tesoro) y ninguna opción de compra.
5. **Given** cualquier intento de activar un título no ganado, **Then** se rechaza y el título activo no cambia.

---

### User Story 4 - Ir a cada sección desde Perfil (Priority: P2)

Como jugador, quiero que Perfil me lleve a Diario, Estadísticas, Vision Board, Inventario y logros, Marketplace y Configuración, como dice la navegación del diseño.

**Why this priority**: alinea Perfil con la navegación de 5 pestañas; las pantallas destino pueden seguir siendo de ejemplo.

**Independent Test**: tocar cada uno de los 6 accesos y comprobar a dónde lleva.

**Acceptance Scenarios**:

1. **Given** el Perfil, **Then** ve exactamente 6 accesos, en este orden: Diario, Estadísticas, Vision Board, Inventario y logros, Marketplace y Configuración.
2. **Given** un acceso con pantalla actual (Diario, Marketplace, Configuración), **When** lo toca, **Then** abre esa pantalla aunque muestre datos de ejemplo.
3. **Given** un acceso sin pantalla todavía (Estadísticas, Vision Board, Inventario y logros), **When** lo toca, **Then** ve el aviso de «próximamente» que el Perfil ya usa hoy, sin error.
4. **Given** el Perfil, **Then** ya no aparecen los accesos «Historial» ni «Game Master» (los sustituyen Diario y Configuración).
5. **Given** el Perfil, **Then** ya no aparece la fila «Apariencia».
6. **Given** Configuración, **When** toca «Apariencia», **Then** abre la pantalla de Apariencia actual, y el modo elegido (claro, oscuro o del sistema) se aplica y se conserva como hoy.

---

### Edge Cases

- Vida exactamente 30: no está debilitado.
- El catálogo de títulos todavía está vacío: el Perfil funciona igual y la elección muestra el estado vacío.
- Un título activo que se retira del catálogo: el jugador queda sin título, sin error.
- Error de red al cambiar el título: mensaje con tono de invitación, el título anterior se conserva y se puede reintentar.
- Tesoro con números grandes (ej. 12 500): se muestra con separador de miles en español.
- Nombre del título largo: no rompe la tarjeta del personaje ni tapa el nombre.
- Los 6 accesos caben en pantalla de teléfono sin desplazamiento horizontal y con zonas táctiles amplias.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El Perfil MUST mostrar el aviso de vitalidad baja solo cuando la vida está por debajo de 30, y su texto MUST decir que se gana un 25 % menos de XP y que las Monedas no bajan.
- **FR-002**: El dato de «debilitado» y su umbral MUST venir del servidor, no calcularse en la app.
- **FR-003**: El Perfil MUST mostrar el Tesoro del reino del jugador, separado de las Monedas.
- **FR-004**: El Perfil MUST mostrar el título activo bajo el nombre, y nada si no hay título activo.
- **FR-005**: El jugador MUST poder elegir como activo cualquiera de sus títulos ganados, o ninguno.
- **FR-005a**: La entrada para elegir título MUST estar visible aunque el jugador no tenga títulos ganados; en ese caso abre un estado vacío que explica cómo se ganan (logros, nivel, Tesoro), sin opción de compra.
- **FR-006**: El sistema MUST rechazar activar un título que el jugador no ganó; la app MUST NOT ofrecer comprar títulos.
- **FR-007**: Los datos del Perfil MUST incluir, en la misma carga que hoy, el Tesoro, el título activo y la lista de títulos ganados; este cambio en el servidor va en una corrección nueva, sin editar las ya aplicadas.
- **FR-008**: El Perfil MUST ofrecer 6 accesos en este orden: Diario, Estadísticas, Vision Board, Inventario y logros, Marketplace y Configuración.
- **FR-009**: Cada acceso MUST llevar a su pantalla actual si existe; si no existe, MUST mostrar el aviso de «próximamente» actual.
- **FR-010**: El cambio MUST usar los componentes visuales existentes del Perfil, sin colores, fuentes ni componentes nuevos.
- **FR-011**: Textos en español con tono de invitación; WCAG 2.1 AA (contraste, zonas táctiles, etiquetas para lectores de pantalla, el color nunca solo).
- **FR-012**: El cambio de servidor MUST tener pruebas automáticas: Tesoro, título activo y títulos ganados en los datos del Perfil; rechazo de un título no ganado; aislamiento entre dos jugadores.
- **FR-013**: La app MUST traer pruebas de la lectura del Perfil (Tesoro y títulos), del cambio de título y del estado de la pantalla.
- **FR-014**: Apariencia MUST abrirse desde Configuración y MUST NOT aparecer en el Perfil; la pantalla de Apariencia y la forma de guardar el modo no cambian.

### Key Entities

- **Personaje**: vida, vida máxima, debilitado (vida < 30), Monedas en la bolsa y Tesoro del reino.
- **Título de prestigio**: entrada del catálogo global con nombre y descripción; se gana, no se compra.
- **Título ganado**: un título que un jugador ya consiguió.
- **Título activo**: el título ganado que el jugador eligió mostrar (o ninguno).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: El 100 % de los jugadores con vida < 30 ve el aviso con la regla vigente, y el 0 % de los jugadores con vida ≥ 30 lo ve.
- **SC-002**: Un jugador puede cambiar su título activo en 3 toques o menos desde el Perfil.
- **SC-003**: 0 títulos activados que el jugador no haya ganado.
- **SC-004**: Los 6 accesos responden al toque: ninguno lleva a una pantalla de error.
- **SC-005**: El Perfil carga el Tesoro y los títulos sin peticiones extra respecto a hoy (una sola carga de datos).

## Assumptions

- La regla de debilitado (vida < 30, −25 % de XP, Monedas iguales) ya está en el servidor desde las migraciones aplicadas; aquí solo cambia lo que se muestra y lo que se documenta.
- El Inicio tiene el mismo aviso antiguo («10 % menos»); corregirlo es otra spec, salvo que el equipo prefiera hacerlo aquí.
- Estadísticas, Vision Board e Inventario y logros todavía no tienen pantalla; mientras tanto usan el aviso de «próximamente» que ya existe en el Perfil.
- «Configuración» es la pantalla de Game Master actual; «Diario» es la pantalla actual de Bitácora.
- Hoy el catálogo de títulos está vacío (decisión abierta en CLAUDE.md §11); la función se entrega igual y muestra el estado vacío hasta que haya títulos.
- Cómo se ganan los títulos queda fuera de esta spec; solo se muestran y se eligen.
- El texto del Tesoro es provisional hasta que exista `PRODUCT.md`.
- Las secciones Notificaciones y Ayuda del Perfil no cambian; Apariencia se muda a Configuración (FR-014).
