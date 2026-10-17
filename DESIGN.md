---
name: LifeQuest
description: Productividad gamificada en un jardín sereno donde el progreso real hace crecer al héroe.
colors:
  sprout-green: "#29B951"
  forest-green: "#137A34"
  moss-ink: "#1D3B2B"
  lichen-gray: "#5E6E64"
  morning-mist: "#F4F9F6"
  dew-line: "#D5EBDD"
  control-outline: "#6F8A78"
  seedling-tint: "#E8F7EC"
  surface-white: "#FFFFFF"
  ember-red: "#B23A3A"
  rose-warning: "#E67777"
  dark-forest-green: "#5BD47E"
  dark-on-forest-green: "#0A2413"
  dark-moss-ink: "#E3EEE7"
  dark-lichen-gray: "#A3B3A9"
  dark-background: "#0F1612"
  dark-surface: "#17211B"
  dark-dew-line: "#2A3A31"
  dark-seedling-tint: "#1D3326"
  dark-control-outline: "#7E9A88"
  dark-ember-red: "#F28B82"
typography:
  display:
    fontFamily: "Roboto, sans-serif"
    fontSize: "28sp"
    fontWeight: 700
    lineHeight: 1.2
  headline:
    fontFamily: "Roboto, sans-serif"
    fontSize: "21sp"
    fontWeight: 800
  title:
    fontFamily: "Roboto, sans-serif"
    fontSize: "16sp"
    fontWeight: 700
  body:
    fontFamily: "Roboto, sans-serif"
    fontSize: "15sp"
    fontWeight: 400
  body-small:
    fontFamily: "Roboto, sans-serif"
    fontSize: "13sp"
    fontWeight: 400
  label:
    fontFamily: "Roboto, sans-serif"
    fontSize: "13sp"
    fontWeight: 500
  caption:
    fontFamily: "Roboto, sans-serif"
    fontSize: "12sp"
    fontWeight: 400
rounded:
  sm: "8px"
  md: "10px"
  card: "11px"
  lg: "14px"
  pill: "20px"
spacing:
  xs: "4px"
  sm: "8px"
  md: "16px"
  lg: "24px"
  xl: "32px"
components:
  button-primary:
    backgroundColor: "{colors.forest-green}"
    textColor: "{colors.surface-white}"
    typography: "{typography.label}"
    rounded: "{rounded.md}"
    height: "52px"
  button-text:
    textColor: "{colors.forest-green}"
    typography: "{typography.label}"
    height: "48px"
  input:
    backgroundColor: "{colors.surface-white}"
    textColor: "{colors.moss-ink}"
    typography: "{typography.body}"
    rounded: "{rounded.md}"
    padding: "14px 12px"
  card:
    backgroundColor: "{colors.surface-white}"
    rounded: "{rounded.card}"
    padding: "12px"
  icon-tile:
    backgroundColor: "{colors.seedling-tint}"
    textColor: "{colors.forest-green}"
    rounded: "{rounded.sm}"
    size: "34px"
  navigation-bar:
    backgroundColor: "{colors.surface-white}"
    height: "66px"
  navigation-indicator:
    backgroundColor: "{colors.seedling-tint}"
  snackbar:
    backgroundColor: "{colors.moss-ink}"
    textColor: "{colors.surface-white}"
---

# Design System: LifeQuest

## Overview

**Creative North Star: "El Jardín del Héroe"**

LifeQuest es un jardín, no un campo de batalla. El verde es la gramática del progreso: brota en los acentos, se oscurece en lo que se toca y se diluye en tintes de semillero detrás de los iconos. Cada pantalla es un lugar calmo donde se cultivan hábitos; la aventura RPG vive en el lenguaje (misiones, mazmorras, héroe) y en la iconografía, nunca en ornamento estridente, texturas de pergamino ni efectos de "juego".

La densidad es la de una app de Material 3 para Android: superficies blancas sobre un fondo de niebla verdosa, bordes de rocío casi imperceptibles y sombras que apenas se notan. Los componentes son suaves y serenos: una sola acción clara por pantalla, mucho aire, ningún elemento que compita por atención. El sistema está pensado para personas con TDAH: baja carga cognitiva, sin urgencia artificial y con contraste WCAG AA.

**Key Characteristics:**
- Fondo de niebla verde (`morning-mist`) con superficies blancas y bordes de 1 px.
- Un solo acento cromático (verde) en dos pesos: brote para decorar, bosque para actuar y leer.
- Iconos Material outlined dentro de baldosas de tinte suave.
- Sombras ambientales mínimas; la profundidad la dan el tono y el borde.
- Roboto, escala Material, nunca por debajo de 12 sp.

## Colors

Una paleta monocroma verde sobre neutros con matiz verde; el rojo aparece solo para errores y malos hábitos.

### Primary
- **Brote** (sprout-green): verde vivo para iconos de navegación, anillos de progreso, casillas y acentos decorativos. No lleva texto blanco encima ni sirve como texto pequeño sobre claro (contraste 2,6:1 con blanco).
- **Bosque** (forest-green): el verde que se toca y se lee. Botones primarios, enlaces, borde de foco de los campos e iconos dentro de baldosas. ≥4,5:1 sobre `morning-mist` y con texto blanco.

### Neutral
- **Tinta de Musgo** (moss-ink): títulos, texto principal y fondo de los avisos (snackbar).
- **Gris Liquen** (lichen-gray): texto secundario, subtítulos y etiquetas. ≥4,5:1 sobre el fondo.
- **Niebla Matinal** (morning-mist): fondo de todas las pantallas y de las barras del sistema.
- **Línea de Rocío** (dew-line): bordes de 1 px de tarjetas (decorativos).
- **Contorno de Control** (control-outline): borde de campos y casillas. ≥3:1 sobre blanco y sobre el fondo (WCAG 1.4.11).
- **Tinte de Semillero** (seedling-tint): fondo de baldosas de icono, indicador de la barra de navegación y estadísticas.
- **Superficie Blanca** (surface-white): tarjetas, campos y barra de navegación.

### Semantic
- **Rojo Brasa** (ember-red): borde y texto de error en formularios. ≥4,5:1 sobre el fondo.
- **Rosa Aviso** (rose-warning): hábitos malos y pérdida de HP, siempre sobre un fondo rosado muy claro (`#FFF8F7`). Nunca como texto pequeño.

### Tema oscuro
Cada rol tiene su valor oscuro (claves `dark-*`): un fondo de bosque nocturno, superficies apenas más claras y el verde Bosque aclarado para que siga leyéndose como acción. En oscuro el botón primario lleva texto oscuro sobre verde claro. La app sigue la preferencia del sistema; en código, los valores viven en `LifeQuestPalette` y se leen con `context.lq`. Hoy solo el login y el registro están migrados; el resto de pantallas se fuerzan a claro (`LifeQuestTheme.lightOnly`) hasta migrarlas.

### Named Rules
**The Two Greens Rule.** Brote decora, Bosque actúa. Todo texto verde y todo fondo verde con texto encima usa Bosque.

**The Calm Red Rule.** El rojo solo nombra un error o un mal hábito. Nunca se usa para meter prisa, marcar urgencia artificial ni culpar.

## Typography

**Body Font:** Roboto (fuente del sistema Android, con sans-serif de respaldo)

**Character:** Una sola familia, legible y neutra; la jerarquía viene del peso (700–800 en títulos) y del tamaño, no de fuentes decorativas.

### Hierarchy
- **Display** (700, 28 sp, 1.2): título de pantallas de entrada como «Crea tu Héroe».
- **Headline** (800, 21 sp): título de cada sección del menú (`LifeQuestPage`).
- **Title** (700, 16 sp): títulos de tarjetas y marca.
- **Body** (400, 15 sp): texto de campos y subtítulos de pantallas de entrada.
- **Body Small** (400, 13 sp): detalle de filas y texto secundario.
- **Label** (500–700, 13 sp): etiquetas de campo, enlaces y botones (los botones primarios usan 15 sp, 600).
- **Caption** (400, 12 sp): errores de validación y metadatos. Es el mínimo absoluto.

### Named Rules
**The 12 sp Floor Rule.** Ningún texto baja de 12 sp. Hoy muchas pantallas usan 7–10 sp; se corrigen al tocarlas.

**The Scaling Rule.** Los tamaños se expresan en sp y los diseños deben aguantar una escala de texto de 1,3 sin cortar ni desbordar.

## Layout

Una columna por pantalla con margen lateral de 19–24 dp (`LifeQuestPage` usa 19/17/19/22). El ritmo vertical se agrupa en pasos de 4/8/16/24/32 dp: 16 entre campos de un formulario, 24–32 entre bloques. Las pantallas de entrada anclan la acción principal abajo con un `Spacer` y se desplazan cuando el teclado no deja sitio. La navegación principal es una `NavigationBar` inferior de 5 destinos (Inicio, Misiones, Dungeon, Hábitos, Perfil); las subpáginas de Perfil se apilan sobre ella.

## Elevation & Depth

El sistema es casi plano. La profundidad la dan el contraste blanco/niebla y el borde de rocío; la única sombra de superficie es ambiental y apenas visible. El botón primario es plano: lo distingue el color Bosque, no la sombra (una sombra verde se leía como halo).

### Shadow Vocabulary
- **Rocío ambiental** (`BoxShadow(color: 0x08000000, blurRadius: 7, offset: (0, 2))`): todas las tarjetas (`LifeQuestSurface`).

### Named Rules
**The Whisper Shadow Rule.** Si una sombra se nota antes que el contenido, sobra. Nada de sombras duras, halos de color ni elevaciones altas.

## Shapes

Esquinas suavemente redondeadas y consistentes: 8 dp para piezas pequeñas (baldosas de icono, estadísticas), 10 dp para campos y botones, 11 dp para tarjetas y 14 dp para la baldosa de marca. Las tarjetas llevan 1 px de Línea de Rocío; los campos y casillas, 1 px de Contorno de Control, que pasa a 1,5 px de Bosque con foco.

## Components

### Buttons
- **Shape:** esquinas suaves (10 dp).
- **Primary:** fondo Bosque, texto blanco 15 sp/600, 52 dp de alto, icono Material a la izquierda, sin sombra. Uno por pantalla.
- **Text / Link:** texto Bosque 13 sp, objetivo táctil mínimo de 48×48 dp aunque el texto sea pequeño.
- **Outlined (social):** borde de rocío, texto Tinta de Musgo.

### Cards / Containers
- **Corner Style:** 11 dp.
- **Background:** Superficie Blanca sobre Niebla Matinal.
- **Shadow Strategy:** Rocío ambiental (ver Elevation & Depth).
- **Border:** 1 px Línea de Rocío.
- **Internal Padding:** 12 dp.

### Inputs / Fields
- **Style:** fondo blanco, borde de 1 px en Contorno de Control, radio de 10 dp, icono outlined de 20 dp a la izquierda, etiqueta visible encima (13 sp, 500), al menos 48 dp de alto.
- **Focus:** borde Bosque de 1,5 px y cursor Bosque.
- **Error:** borde Rojo Brasa y mensaje de 12 sp debajo que dice cómo corregirlo. El campo crece; nunca se aplasta.
- **Accesibilidad:** TalkBack lee la etiqueta en el propio campo y el botón de ver contraseña como nodo aparte; pistas de autocompletado y acción de teclado («siguiente» / «listo»). Al fallar la validación se anuncia el primer error y se lleva a la vista.

### Navigation
- **Style:** `NavigationBar` de Material 3, blanca, 66 dp, etiquetas siempre visibles. Indicador en Tinte de Semillero; icono outlined en reposo y rounded cuando está seleccionado.

### Baldosa de icono (signature)
Icono Material outlined en Bosque dentro de un cuadrado de 34 dp con fondo Tinte de Semillero y radio de 8–9 dp. Es la firma visual de las filas de lista, ajustes y tarjetas.

### Snackbar
Fondo Tinta de Musgo, texto blanco, flotante. Es el único canal de avisos transitorios; el éxito no usa verde chillón.

## Do's and Don'ts

### Do:
- **Do** usar Bosque para todo texto verde, enlaces, foco y botones con texto blanco.
- **Do** mantener una sola acción primaria por pantalla.
- **Do** dar a todo control un objetivo táctil de 48×48 dp como mínimo.
- **Do** escribir los mensajes de error diciendo cómo corregirlo, en tono de invitación.
- **Do** leer los colores con `context.lq` en código nuevo o migrado, para que respete el tema oscuro.
- **Do** reutilizar `LifeQuestSurface`, `LifeQuestIconTile`, `LifeQuestListRow` y `LifeQuestColors` antes de crear estilos nuevos.

### Don't:
- **Don't** usar texto por debajo de 12 sp.
- **Don't** poner texto blanco sobre Brote ni usar Brote como texto pequeño.
- **Don't** usar colores hex sueltos en las pantallas cuando existe un token en `LifeQuestColors`.
- **Don't** añadir sombras marcadas, degradados, texturas de pergamino ni efectos "gamer" estridentes.
- **Don't** usar rojo, cuentas atrás o parpadeos para crear urgencia o culpa.
