# Feature Specification: Onboarding de 5 pasos

**Feature Branch**: `003-onboarding`

**Created**: 2026-10-20

**Status**: Draft

**Input**: User description: "Onboarding de 5 pasos tras el primer inicio de sesión, según docs/ideas-proyecto-productividad-gamificada.md: presenta el juego, pide la identidad («¿Quién eres en este reino?»), la primera skill/Área y la dificultad (Fácil, Normal o Difícil, que después solo se cambia en Configuración), y deja al usuario en Inicio. Se muestra una sola vez y se puede saltar sin perder nada. Guarda lo elegido con las tablas y RPC existentes (profiles, skills, game_master_settings). Sin rediseño visual: DESIGN.md está pendiente; se usan los widgets de core/widgets."

## Contexto

El documento de diseño fija que, antes de entrar a la app, el jugador pasa por un Onboarding de 5 pasos y que la dificultad «se elige una vez en el Onboarding» y después solo se cambia en Configuración. Hoy la app lleva al jugador directo a Inicio tras registrarse: no sabe qué es el juego, su identidad está vacía, no tiene ninguna skill y juega en Normal sin haberlo elegido.

Los cinco pasos:

1. **Bienvenida:** qué es LifeQuest en una frase (tu progreso real hace progresar a tu personaje) y el ciclo tarea → XP y Monedas → nivel.
2. **Identidad:** «¿Quién eres en este reino?», texto libre opcional.
3. **Primera skill/Área:** nombre de un área de su vida, opcional: texto libre o una de 6 sugerencias (Salud, Estudio, Trabajo, Hogar, Creatividad, Relaciones) que rellena el campo y se puede editar.
4. **Dificultad:** Fácil, Normal o Difícil, con qué cambia cada una y el aviso de que luego solo se cambia en Configuración.
5. **Listo:** resumen de lo elegido y botón para entrar a Inicio.

## Clarifications

### Session 2026-10-20

- Q: ¿Dónde se guarda que el Onboarding ya se vio? → A: En el servidor: una marca nueva en el perfil del jugador (fecha en que terminó o saltó), que el jugador solo puede poner en «ahora» y nunca borrar.
- Q: ¿Qué ofrece el paso 3 (primera skill/Área)? → A: Campo de texto libre más 6 sugerencias tocables (Salud, Estudio, Trabajo, Hogar, Creatividad, Relaciones) que rellenan el campo y se pueden editar.
- Q: ¿Saltar deja la dificultad en Normal? → A: Saltar guarda la dificultad marcada en el paso 4 si el jugador llegó a él; si no llegó, queda Normal.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Completar el Onboarding (Priority: P1)

Como jugador nuevo, tras mi primer inicio de sesión quiero que la app me presente el juego y me deje elegir mi identidad, mi primera skill y mi dificultad, para empezar a jugar sabiendo qué hago y con reglas que elegí yo.

**Why this priority**: es el recorrido principal; sin él la dificultad nunca se elige y el jugador empieza con el Perfil vacío.

**Independent Test**: registrar una cuenta nueva, recorrer los 5 pasos con datos y comprobar en el Perfil la identidad, la skill y la dificultad elegidas, y que la app queda en Inicio.

**Acceptance Scenarios**:

1. **Given** una cuenta recién creada, **When** inicia sesión por primera vez, **Then** ve el paso 1 del Onboarding en lugar de Inicio.
2. **Given** el paso 2, **When** escribe su identidad y continúa, **Then** esa identidad aparece después en su Perfil.
3. **Given** el paso 3, **When** escribe el nombre de una skill y continúa, **Then** esa skill aparece en su Perfil con nivel 1.
3a. **Given** el paso 3, **When** toca la sugerencia «Salud», **Then** el campo se rellena con «Salud», puede editarlo antes de continuar y se crea una sola skill con el texto final.
4. **Given** el paso 4, **When** elige Difícil y continúa, **Then** su dificultad queda en Difícil.
5. **Given** el paso 5, **When** pulsa entrar, **Then** llega a Inicio y el Onboarding no vuelve a mostrarse.
6. **Given** cualquier paso del 2 al 5, **When** pulsa atrás, **Then** vuelve al paso anterior con lo que ya había escrito.

---

### User Story 2 - Saltar sin perder nada (Priority: P1)

Como jugador con prisa, quiero poder saltar el Onboarding en cualquier paso y entrar a Inicio, sin que se pierda lo que ya elegí ni me quede un perfil a medias.

**Why this priority**: obligar a completar un recorrido es fricción (Modelo de Fogg) y va contra la autonomía del usuario.

**Independent Test**: escribir la identidad en el paso 2 y saltar; comprobar que la identidad se guardó, que la dificultad es Normal y que el Onboarding no vuelve a aparecer.

**Acceptance Scenarios**:

1. **Given** cualquier paso, **When** pulsa «Saltar», **Then** llega a Inicio.
2. **Given** que escribió la identidad o la skill antes de saltar, **When** salta, **Then** lo escrito se guarda.
3. **Given** que salta antes de llegar al paso 4, **Then** juega en Normal.
3a. **Given** que en el paso 4 marcó Difícil, **When** salta sin pulsar continuar, **Then** juega en Difícil.
4. **Given** que saltó, **When** vuelve a abrir la app, **Then** no ve el Onboarding otra vez.
5. **Given** que saltó, **Then** puede poner la identidad y las skills desde Perfil, y la dificultad desde Configuración, como cualquier jugador.

---

### User Story 3 - Elegir con información (Priority: P2)

Como jugador, en el paso de dificultad quiero ver qué cambia en cada nivel antes de elegir, porque después solo podré cambiarla en Configuración.

**Why this priority**: la decisión afecta a toda la partida; sin la explicación la elección no es informada.

**Independent Test**: abrir el paso 4 y comprobar que cada opción dice cuánta XP da y cuánta vida se pierde, y que las Monedas son iguales en las tres.

**Acceptance Scenarios**:

1. **Given** el paso 4, **Then** ve las tres opciones con su efecto en XP (×1,2 / ×1 / ×0,85) y en vida perdida (×0,75 / ×1 / ×1,25), y que las Monedas no cambian.
2. **Given** el paso 4, **Then** Normal aparece preseleccionada.
3. **Given** el paso 4, **Then** ve un aviso de que la dificultad solo se cambia después en Configuración.

---

### Edge Cases

- Identidad vacía o solo espacios: se deja vacía, sin error.
- Identidad de más de 280 caracteres o skill de más de 40: no deja continuar y dice el límite.
- Skill con el mismo nombre que una que ya tiene: se avisa y no se crea otra igual.
- Sin conexión o error al guardar: se muestra un mensaje con tono de invitación y se puede reintentar; nada se pierde y el jugador no queda atrapado (puede saltar).
- La app se cierra a mitad del Onboarding: al volver, se muestra otra vez desde el paso 1, con lo ya guardado conservado.
- Un jugador que ya existía antes de esta función (ya tiene identidad o alguna skill) no ve el Onboarding.
- Cerrar sesión e iniciarla de nuevo con una cuenta que ya hizo o saltó el Onboarding: no lo vuelve a ver.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Tras el inicio de sesión, el sistema MUST mostrar el Onboarding a un jugador que nunca lo terminó ni lo saltó, antes de mostrar Inicio.
- **FR-002**: El Onboarding MUST tener 5 pasos en este orden: bienvenida, identidad, primera skill, dificultad y listo.
- **FR-003**: La identidad y la primera skill MUST ser opcionales; la dificultad MUST venir preseleccionada en Normal.
- **FR-003a**: El paso 3 MUST ofrecer 6 sugerencias tocables (Salud, Estudio, Trabajo, Hogar, Creatividad, Relaciones); tocar una rellena el campo de texto, que sigue editable. Se crea como máximo una skill.
- **FR-004**: El sistema MUST guardar la identidad, la skill y la dificultad con los mismos límites y reglas que ya aplican el Perfil y Configuración (280 caracteres de identidad, 40 de skill, máximo de skills).
- **FR-005**: El jugador MUST poder saltar el Onboarding desde cualquier paso; lo ya escrito se guarda y lo no elegido queda con su valor por defecto. Si llegó al paso 4, se guarda la dificultad marcada aunque no haya pulsado continuar; si no llegó, queda Normal.
- **FR-006**: El jugador MUST poder volver al paso anterior sin perder lo escrito.
- **FR-007**: Al terminar o saltar, el sistema MUST guardar en la cuenta del jugador la fecha en que lo hizo, llevarlo a Inicio y no volver a mostrarle el Onboarding en ningún dispositivo.
- **FR-007a**: El jugador MUST poder poner esa marca solo con la fecha actual y MUST NOT poder borrarla ni cambiarla después; la marca nueva va en una migración nueva con su prueba (incluido el aislamiento entre dos jugadores).
- **FR-008**: Un jugador que ya tiene identidad o al menos una skill MUST NOT ver el Onboarding.
- **FR-009**: Tras el Onboarding, la dificultad solo MUST poder cambiarse desde Configuración, como ya ocurre.
- **FR-010**: Todos los textos MUST estar en español, con tono de invitación, y la pantalla MUST cumplir WCAG 2.1 AA (contraste, zonas táctiles, lectores de pantalla en botones de icono).
- **FR-011**: El Onboarding MUST usar los componentes visuales que ya existen en la app; no se crean colores, fuentes ni componentes nuevos.
- **FR-012**: El Onboarding MUST NOT dar XP ni Monedas.

### Key Entities

- **Perfil del jugador**: su identidad («¿Quién eres en este reino?»).
- **Skill/Área**: área de su vida con nivel propio; la primera se puede crear aquí.
- **Reglas del juego del jugador (Game Master)**: su dificultad.
- **Marca de Onboarding visto**: fecha, guardada en el perfil del jugador, en que terminó o saltó el Onboarding; vacía hasta entonces y fija después.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Un jugador nuevo puede completar los 5 pasos en menos de 2 minutos.
- **SC-002**: El 100 % de los jugadores puede llegar a Inicio con un solo toque desde cualquier paso.
- **SC-003**: Lo que el jugador escribe antes de saltar se conserva en el 100 % de los casos.
- **SC-004**: Ningún jugador ve el Onboarding más de una vez, aunque reinstale la app o cambie de teléfono.
- **SC-005**: Ningún jugador que ya existía antes de la función ve el Onboarding.

## Assumptions

- El documento de diseño solo dice «Onboarding de 5 pasos» y que ahí se elige la dificultad; el contenido de cada paso se toma del pedido del usuario (bienvenida, identidad, skill, dificultad, listo), porque el paquete de pantallas se borró.
- Se crea a lo sumo una skill en el Onboarding; las demás se crean desde Perfil.
- Normal es el valor que ya tiene toda cuenta nueva, así que saltar antes del paso 4 no necesita guardar nada.
- Los multiplicadores mostrados en el paso 4 se leen de los valores vigentes del juego, no se escriben a mano en la pantalla.
- Los textos de la bienvenida son provisionales hasta que exista `PRODUCT.md`.
- No hay cambios de economía, RF ni casos de uso; la marca nueva del perfil (FR-007) se documenta en `Esquema_Base_de_Datos.md`.
- El pedido decía «solo tablas existentes»: se acepta una columna nueva en una tabla existente (el perfil) porque ninguna guardaba si el Onboarding se vio.
