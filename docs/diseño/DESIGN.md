# DESIGN.md — Sistema de diseño «Bosque vivo» (v2 · moderno, sin fantasía)

> Fuente de verdad visual del proyecto. Lo leen las personas del equipo, Claude Code y la skill **Impeccable**.
> Referencia visual: lienzo «Questly — Diseño de la app» (claude.ai) y la carpeta `design/pantallas/`.
>
> **v2 (2026-10-29):** se quita la fantasía (decisión del usuario). Se conservan los colores, la
> tipografía, las formas y los componentes. Cambian el Hero (formas geométricas en lugar del paisaje),
> los iconos, la mascota, los nombres de los temas y la voz. **Las pantallas `.dc.html` siguen siendo la
> referencia de estructura, medidas y estilo; sus textos, iconos e ilustraciones de fantasía se reemplazan
> según §7 y `docs/plan-funcionalidades-asistente.md` §3.1.**

## 1. Dirección

- **Minimalista como Notion, con la energía de una app de hábitos moderna** (Duolingo, Strava, Things).
  El fondo es verde muy suave y encima van tarjetas blancas tranquilas.
- **El color solo aparece donde hay acción o progreso.**
- **Cabecera (Hero):** una banda de color con formas geométricas suaves (arcos y círculos) que cambia
  según el tema. Es igual en todas las pantallas para que la app se sienta consistente. Sin paisajes ni ilustraciones.
- **El Asistente:** no tiene mascota ni cara. Se representa con el icono `spark` dentro de un círculo de
  tinte. Es amable, explica y propone, y nunca regaña.
- **Sensación táctil:** las tarjetas y los botones llevan una sombra sólida de 4 px debajo. Al pulsarlos
  bajan 3 px y la sombra desaparece.
- **Prohibido:**
  - degradados genéricos de «IA», glassmorphism, emojis como iconos, sombras difusas en las tarjetas y
    más de un acento por pantalla;
  - **toda imaginería de fantasía o RPG:** espadas, escudos, castillos, coronas, pociones, cofres,
    pergaminos, jefes, monstruos, tabernas, mapas del tesoro.

## 2. Color (tokens)

| Token | Claro | Oscuro | Uso |
|---|---|---|---|
| `bg` | `#F3F6EF` | `#13201A` | Fondo de pantalla |
| `card` | `#FFFFFF` | `#1C2C24` | Tarjetas, hojas, navegación |
| `border` | `#DCE4D4` | `#2C4036` | Bordes y sombra sólida de tarjeta |
| `track` | `#E7EDE1` | `#24362C` | Fondo de barras y segmentos |
| `line` | `#EEF2EA` | `#24362C` | Separadores de lista |
| `text` | `#1E2A22` | `#EEF3EC` | Texto principal |
| `text2` | `#4E5C52` | `#A9B8AD` | Texto secundario |
| `text3` | `#3E4A42` | `#CFDACF` | Texto de apoyo sobre tintes |
| `inputBorder` | `#C9D3C2` | `#3A5446` | Inputs, botón secundario |
| `disabled` | `#7D8A80` | `#7D8A80` | Botones y pistas apagadas |
| `accent` | `#2E7D4F` | `#2E7D4F` | Acción principal, progreso de XP |
| `accentInk` | `#1F5C39` | `#9FDCB4` | Texto de acento, sombra de botón |
| `accentTint` | `#E1F0E6` | `#1F3A2C` | Selección, chips, notas |
| `coral` | `#E0573F` | `#E0573F` | Constancia (relleno) |
| `coralInk` | `#A8361F` | `#F5B8A8` | Error, prioridad alta |
| `coralTint` | `#FBE4DF` | `#3A1F1A` | Fondo de error / constancia baja |
| `mustard` | `#D9A21B` | `#D9A21B` | Monedas, logros, nivel (relleno) |
| `mustardInk` | `#6E4D00` | `#F5D896` | Cifras de Monedas, avisos |
| `mustardTint` | `#FBF0D3` | `#3A3016` | Fondo de Monedas |
| `river` | `#3C5BA8` | `#9FB8E8` | Proyectos, metas, info, anillo de foco |
| `riverInk` | `#2C4580` | `#B9CBF0` | Texto informativo |
| `riverTint` | `#E3E9F7` | `#1E2A44` | Fondo informativo |

*(v2: se quita el token `boss`, que era el fondo de la arena del jefe y del Mercado negro.)*

**Temas de color.** El tema cambia el acento, el tinte, la tinta y el tono del Hero. Los nombres son de
color, no de lugares.

| Tema (UI) | En el código | Acento | Tinte | Tinta | Hero (fondo / forma) |
|---|---|---|---|---|---|
| Verde (por defecto) | `bosque` · `forest` | `#2E7D4F` | `#E1F0E6` | `#1F5C39` | `#1F5C39` / `#2E7D4F` |
| Azul | `rio` · `river` | `#3C5BA8` | `#E3E9F7` | `#2C4580` | `#24396B` / `#3C5BA8` |
| Coral | `brasa` · `ember` | `#A8361F` | `#FBE4DF` | `#8A2C19` | `#7A2716` / `#A8361F` |
| Ámbar | `oro` · `gold` | `#D9A21B` (texto encima `#3D2B00`) | `#FBF0D3` | `#6E4D00` | `#5C4100` / `#8A6200` |

En modo oscuro, el Hero usa siempre el tono «noche»: `#0E1B14` / `#1C2C24`.

**Modo:** Claro · Oscuro · Automático (sigue al sistema). El Modo Foco es siempre oscuro.

## 3. Tipografía

| Token | Fuente | Tamaño / interlineado · peso |
|---|---|---|
| display | Bricolage Grotesque | 34/1.1 · 800 |
| title1 | Bricolage Grotesque | 30/1.1 · 800 (título del Hero) |
| title2 | Bricolage Grotesque | 22/1.2 · 800 (hojas, diálogos) |
| title3 | Bricolage Grotesque | 18/1.25 · 800 (secciones) |
| body | DM Sans | 15/1.45 · 400 |
| label | DM Sans | 14/1.3 · 700 (botones, campos) |
| meta | DM Sans | 12 · 700 · mayúsculas · +8 % de espaciado |
| number | DM Mono | 13–15 · 500 (XP, Monedas, tiempos) |

El tamaño mínimo es 11 px. Los números que cambian van en DM Mono para que no «bailen».

## 4. Espacio, forma y elevación

- **Pantalla:** 390 × 844 de referencia, fluida entre 360 y 430. Márgenes laterales de 20 px. Separación entre bloques de 16 px.
- **Escala de espacio:** 4 · 8 · 12 · 16 · 20 · 24 · 32.
- **Radios:**
  - chip 6;
  - control 12;
  - botón 14;
  - bloque 16;
  - tarjeta 20;
  - hoja y diálogo 24;
  - píldora 99.
- **Sombras:**
  - tarjeta: borde de 1 px `border` + sólida `0 4px 0 border`;
  - botón: `0 4px 0 accentInk`;
  - flotante (toast): `0 10px 24px rgba(30,42,34,.22)`.
- **Zona táctil mínima:** 44 × 44 px. Los botones principales miden 52–56 px.

## 5. Componentes

- **Hero:**
  - 156 px de alto, esquinas inferiores de 26 px y formas geométricas en SVG: un círculo grande que
    sale por la derecha, un arco y dos puntos, en los 3 tonos del tema (`shape1`, `shape2`, `shape3`)
    más el punto claro (`dot`).
  - Props: `kicker`, `heading`, `icon`, `tone` (forest/river/ember/gold/night), `backHref`, `actionHref`,
    `actionIcon` (plus/gear/edit/bell) y `badge`.
- **Navegación inferior:**
  - 5 pestañas: **Inicio · Planificador · Hábitos · Foco · Perfil**.
  - La activa lleva una píldora de tinte y texto en tinta.
- **Botones:**
  - principal, secundario (borde), tonal, destructivo (coral) y de texto;
  - el desactivado es gris `#7D8A80` y su texto explica por qué.
- **Pestañas segmentadas:** fondo `track`; la pestaña activa es blanca con una sombra suave.
- **Chips y filtros:** el filtro activo se ve con fondo `text`; las etiquetas de prioridad llevan símbolo ▲ ● ▼.
- **Tarjeta, hoja inferior y diálogo:**
  - hoja: tirador de 40 × 5 y altura máxima del 80–90 %;
  - fondo del diálogo: `rgba(18,34,24,.55–.7)`.
- **Toast:** fondo `text`, `role=status`, dura 2,2 s y puede llevar «Deshacer».
- **Barras:** XP (acento), Constancia (coral), Monedas (mostaza) y avance de meta (río). Siempre muestran también la cifra.
- **Insignia hexagonal:** para niveles, logros y áreas. Dorada = conseguida, verde = en curso, gris = bloqueada.
- **Nota del Asistente:** fondo de tinte con el icono `spark` en un círculo de 32–36 px. Una idea por nota
  y una nota por pantalla como máximo.

### Iconos (trazo, 24 × 24)

| Uso | Icono | Reemplaza a (v1) |
|---|---|---|
| Tareas, Modo Foco, pestaña Foco | `focus` (círculos concéntricos) | `sword` |
| Metas | `flag` | `boss` |
| Logros, insignias | `trophy` | `crown` |
| Mentores | `users` | `mug` |
| Asistente | `spark` | mascota RPGenie |

Se quedan: `home`, `board`, `stage`, `habits`, `profile`, `leaf`, `user`, `book`, `gear`, `flame`,
`coin`, `star`, `inbox`, `calendar`, `archive`, `plus`, `edit`, `bell`, `back`, `close`.

## 6. Movimiento (respeta `prefers-reduced-motion`)

| Animación | Duración | Uso |
|---|---|---|
| press | 80 ms | Pulsar botones y tarjetas |
| sheet | 300 ms | Entrada de hojas y toasts |
| fade | 250 ms | Fondos de diálogo |
| pop | 450 ms | Logros, confirmaciones |
| float | 1,3 s | «+XP» que sube y desaparece |
| fill | 600 ms | Barras de XP, Constancia y meta que se llenan desde el valor anterior |
| shake | 500 ms | Error en un campo |
| confetti | 2,6 s | Subida de nivel y meta cumplida |

*(v2: se quita `bob`, el «respirar» de la mascota y de los jefes.)*

## 7. Voz y tono

- Tuteo cercano, frases cortas y verbos de acción. Tono de app profesional y amable, no de juego.
- Invitar, nunca amenazar: «Tu racha te espera», no «Vas a perder tu racha».
- Los fallos se cuentan sin culpa y siempre con una salida.
- Los números van con su unidad: +25 XP, 30 Monedas.
- **Vocabulario:** se usa la tabla aprobada de `docs/plan-funcionalidades-asistente.md` §3.1 (Tarea,
  Siguiente paso, Asistente, Mentores, Modo Foco, Meta y avance, Constancia, Actividad, Planificador,
  Bandeja de ideas, Recompensas, Ajustes).
- **Palabras prohibidas en la UI:** reino, héroe, personaje, aventura, misión, incursión, mazmorra,
  taverna, NPC, jefe, boss, botín, elixir, cofre, posada, banquete, tesoro, mercado negro, gremio,
  hechizo, Game Master, RPGenie.
- XP, nivel, racha, Monedas y logros **sí** se usan (lenguaje común de apps de hábitos).

## 8. Accesibilidad (WCAG 2.1 AA)

- El texto debe tener un contraste mínimo de 4,5:1 (3:1 si es grande), en claro, en oscuro y en los 4 temas.
- El color nunca va solo: se acompaña de símbolo, texto o cifra.
- Los botones de icono llevan `aria-label` (Semantics en Flutter).
- Los diálogos tienen título, atrapan el foco y muestran un cierre visible.
- El mostaza `#D9A21B` (2,3:1 sobre blanco) solo se usa como relleno y siempre junto al valor escrito.
