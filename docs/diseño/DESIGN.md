# DESIGN.md — Questly · Sistema de diseño «Bosque vivo»

> Fuente de verdad visual del proyecto. Lo leen las personas del equipo, Claude Code y la skill **Impeccable**.
> Referencia visual completa: lienzo «Questly — Diseño de la app» (claude.ai) y la carpeta `design/pantallas/`.

## 1. Dirección

- **Minimalista como Notion, con alma de aventura.** El fondo es verde muy suave, con tarjetas blancas tranquilas encima.
- **El color solo aparece donde hay acción o progreso.**
- **Cabecera ilustrada (Hero):** un paisaje de colinas, sol y árboles que cambia según el tema. Es igual en todas las pantallas para que la app se sienta consistente.
- **Mascota guía: RPGenie.** Es un brote con cara, siempre amable, que explica y propone. Nunca regaña.
- **Sensación de juego:** las tarjetas y los botones llevan una sombra sólida de 4 px debajo. Al pulsarlos bajan 3 px y la sombra desaparece.
- **Prohibido:** degradados genéricos de «IA», glassmorphism, emojis como iconos, sombras difusas en las tarjetas, más de un acento por pantalla.

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
| `coral` | `#E0573F` | `#E0573F` | Vida (HP) y jefes (relleno) |
| `coralInk` | `#A8361F` | `#F5B8A8` | Error, daño, prioridad alta |
| `coralTint` | `#FBE4DF` | `#3A1F1A` | Fondo de error / vida |
| `mustard` | `#D9A21B` | `#D9A21B` | Monedas, logros, nivel (relleno) |
| `mustardInk` | `#6E4D00` | `#F5D896` | Cifras de Monedas, avisos |
| `mustardTint` | `#FBF0D3` | `#3A3016` | Fondo de Monedas |
| `river` | `#3C5BA8` | `#9FB8E8` | Proyectos, info, anillo de foco |
| `riverInk` | `#2C4580` | `#B9CBF0` | Texto informativo |
| `riverTint` | `#E3E9F7` | `#1E2A44` | Fondo informativo |
| `boss` | `#2A2020` | `#2A2020` | Arena de jefe y Mercado negro |

**Temas del reino.** El tema cambia el acento, el tinte, la tinta y el tono del Hero.

| Tema | Acento | Tinte | Tinta | Hero (fondo / colina) |
|---|---|---|---|---|
| Bosque (por defecto) | `#2E7D4F` | `#E1F0E6` | `#1F5C39` | `#1F5C39` / `#2E7D4F` |
| Río | `#3C5BA8` | `#E3E9F7` | `#2C4580` | `#24396B` / `#3C5BA8` |
| Brasa | `#A8361F` | `#FBE4DF` | `#8A2C19` | `#7A2716` / `#A8361F` |
| Oro | `#D9A21B` (texto encima `#3D2B00`) | `#FBF0D3` | `#6E4D00` | `#5C4100` / `#8A6200` |

En modo oscuro, el Hero usa siempre el tono «noche»: `#0E1B14` / `#1C2C24`.

**Modo:** Claro · Oscuro · Automático (sigue al sistema). La Mazmorra (Deep Working) es siempre oscura.

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
  - 156 px de alto, esquinas inferiores de 26 px y paisaje SVG.
  - Props: `kicker`, `heading`, `icon`, `tone` (forest/river/ember/gold/night), `backHref`, `actionHref`, `actionIcon` (plus/gear/edit/bell) y `badge`.
- **Navegación inferior:**
  - 5 pestañas: Inicio · Stage · Hábitos · Mazmorra · Perfil.
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
- **Barras:** XP (acento), vida (coral), Monedas (mostaza). Siempre muestran también la cifra.
- **Insignia hexagonal:** para niveles, logros y skills. Dorada = conseguido, verde = en curso, gris = bloqueado.
- **Nota de RPGenie:** fondo de tinte con la mascota de 32–36 px. Una idea por nota y una nota por pantalla como máximo.

## 6. Movimiento (respeta `prefers-reduced-motion`)

| Animación | Duración | Uso |
|---|---|---|
| press | 80 ms | Pulsar botones y tarjetas |
| sheet | 300 ms | Entrada de hojas y toasts |
| fade | 250 ms | Fondos de diálogo |
| pop | 450 ms | Logros, confirmaciones |
| float | 1,3 s | «+XP» que sube y desaparece |
| bob | 2,6 s ∞ | RPGenie y jefes «respirando» |
| shake | 500 ms | Jefe golpeado, error |
| confetti | 2,6 s | Subida de nivel |

## 7. Voz y tono

- Tuteo cercano, frases cortas y verbos de acción.
- Invitar, nunca amenazar: «Tu racha te espera», no «Vas a perder tu racha».
- Los fallos se cuentan sin culpa y siempre con una salida.
- Los números van con su unidad: +25 XP, 30 Monedas.

## 8. Accesibilidad (WCAG 2.1 AA)

- El texto debe tener un contraste mínimo de 4,5:1 (3:1 si es grande), en claro, en oscuro y en los 4 temas.
- El color nunca va solo: se acompaña de símbolo, texto o cifra.
- Los botones de icono llevan `aria-label` (Semantics en Flutter).
- Los diálogos tienen título, atrapan el foco y muestran un cierre visible.
- El mostaza `#D9A21B` (2,3:1 sobre blanco) solo se usa como relleno y siempre junto al valor escrito.
