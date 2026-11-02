# Diseño de Questly: «Calendario de taco»

Cada día es una hoja de calendario de taco: un número rojo gigante y lo que toca hoy escrito debajo. Suelo de papel gris cálido, hoja blanca con el borde de arriba arrancado, tinta casi negra y **un solo rojo** para lo que importa ahora. Sin fantasía, sin tarjetas grises con chips de fecha.

Fuente de verdad: el código. `lib/core/theme/questly_theme.dart` (`QColors`, `QSpace`, `QRadius`, `QSize`, `QMotion`, `QText`, `questlyTheme`), `lib/core/theme/questly_palette.dart` (`context.q`, `context.motion`), `lib/app/config/theme.dart` (puente `context.lq` para pantallas antiguas). Contrato de dirección: `.impeccable/surfaces/ome-presentation-screens-home-screen-dart-ba4a8f7d.md`.

## Tokens de color (`context.q`)

| Rol | Token | Claro | Oscuro |
|---|---|---|---|
| Suelo (fondo, barra inferior) | `bg` | `#F1EFEA` | `#141312` |
| Hoja | `card` | `#FFFFFF` | `#1E1D1B` |
| Filete / borde | `line`, `border` | `#E4E1DA` | `#2E2C29` |
| Pista, tinte, bloque relleno | `track`, `tint` | `#ECE9E3` | `#2A2826` |
| Tinta (texto y acciones) | `text`, `ink`, `accent` | `#111111` | `#F2F0EB` |
| Texto secundario | `text2` | `#6B6862` | `#A6A29A` |
| Texto terciario | `text3` | `#3A3834` | `#D6D3CC` |
| Borde de campo | `inputBorder` | `#D3CFC6` | `#44413C` |
| **Marca** (fecha, fila actual, «ahora») | `mark` | `#D7262E` | `#FF6B70` |
| Error · mal hábito | `coralInk` / `coralTint` | `#B3261E` / `#FBE9EA` | `#FF6B70` / `#3A1517` |
| Racha · aviso | `mustardInk` / `mustardTint` | `#8A4B00` / `#FBF1DE` | `#F5C26B` / `#33270F` |
| Info | `riverInk` / `riverTint` | `#1F449A` / `#E8EEFA` | `#B9CCF5` / `#1A2440` |
| Anillo de foco de teclado | `focus` | `#2B59C3` | `#2B59C3` |
| Encuadernación (solo Hoy) | literal en `PaperSheet` | `#2A2A2A` | `#3A3834` |

Velos: hoja inferior `#111111` 50 %, diálogo 60 %. El cambio de modo no se interpola.

## Tipografía

**Archivo** empaquetada (`assets/fonts`, 400–900, OFL), sin descarga en tiempo de ejecución. Cifras tabulares en todo número.

| Estilo | Tamaño / peso | Uso |
|---|---|---|
| `numeral` | 88 en `LifeQuestPage`, 36 en la miniatura de Hoy, ~72 en el cronómetro / 900, alto 0,86, tracking −4 % | El número de la hoja. **Uno por pantalla**, en tinta |
| `display` | 32 / 800, −1 | Título de pantalla sobre el suelo |
| `title1` | 28 / 800 | Titulares internos |
| `title2` | 20 / 700 | Secciones grandes, diálogos |
| `title3` | 17 / 600 | Fecha bajo el número, AppBar |
| `body` | 15 / 400, alto 1,45 | Texto; título de fila a 16 (500, 700 si es la actual) |
| `label` | 15 / 600 | Botones y píldoras |
| `meta` | 12 / 600, +0,3 | Pies y metadatos |
| `number` | 15 (13 en hora de fila) / 600 tabular | Horas, contadores |

Encabezados de sección (`LifeQuestSectionHeading`): 15 / 700 en **tipo oración**; el widget convierte MAYÚSCULAS a oración.

## Espacio, radios y tamaños

- Espacio (`QSpace`): 4 · 8 · 12 · 16 · gutter 20 · 24 · 32. Página: 16 laterales + 4 de sangría del título; hoja con 20 de relleno; 96 abajo para la barra y el botón flotante.
- Radios (`QRadius`): chip 6 · control 8 · bloque 10 · tarjeta 12 · botón/píldora 24 · hoja inferior 20 · píldora 99. Botón flotante 16.
- Toque mínimo 44 (`QSize.minTap`), botón principal 48, check 48×48, fila 64, ítem de barra 56.

## Componentes

- **`PaperSheet`**: hoja blanca con borde superior arrancado (zigzag fijo, igual en cada pintado) y filete inferior. Con `bound: true` lleva encuadernación grafito de 18 y dos talones de hojas arrancadas: **solo en Hoy**, es la firma de la app.
- **`PaperRule`**: filete discontinuo 4/3; separa el número de la lista.
- **`LifeQuestPage`**: título y subtítulo sobre el suelo; todo el contenido dentro de una `PaperSheet`; `numeral` opcional (88) con su etiqueta en `title3` gris.
- **`SheetRow`**: check, hora tabular (o icono gris de 18) y título; subtítulo 13 gris; acción debajo alineada al título; filete inferior. `current` = barra roja de 4 a la izquierda y hora en rojo; **una sola fila actual por hoja**. `done` = gris y tachado animado.
- **`SheetCheck`**: círculo de 24 con borde de tinta 2; hecho = relleno de tinta con check en blanco; `busy` muestra progreso dentro.
- **`SheetPill`** y `QuestlyButton` primario: píldora en tinta, texto `label` en blanco, alto 48. Secundario: hoja con borde `inputBorder`; tonal: `tint`; destructivo: `coralInk`.
- **`LifeQuestEmptyState`**: ilustración de trazo (`LifeQuestIllustration`: `blank` hoja con lápiz, `done` hoja con visto y sol, `sprout` brote), título `title3`, texto gris y `SheetPill`. Colores del tema: tinta, hoja, `track` y mostaza (`mustard`) como único acento; nunca el rojo. `compact` la reduce dentro de una sección. Ningún estado vacío va sin ilustración ni acción.
- **Encabezado de Hoy**: saludo con el nombre (`body` gris), día de la semana en `display`, «1 de noviembre» en `title3` gris y, a la derecha, una hoja de calendario en miniatura (franja roja con el mes y el día en `numeral` 36). Debajo, la tira de la semana (L–D) con hoy en un círculo rojo. Sustituye al número gigante.
- **Foco**: esfera de 60 marcas y arco de 12 con brillo que se vacía, con el color de la fase: rojo `mark` en foco, `riverInk` en descanso, `text2` en pausa y `mustard` al completar. El tiempo va en `numeral` al 24 % del diámetro. Debajo van la pista de ciclos, la tarea en foco en `title2` y, al preparar, «Tu ruta»: ciclos y descansos a escala con la hora de fin.
- **Resumen del día (Hoy)**: bloque `tint` bajo la fecha con Tareas, Hábitos y Foco (`LifeQuestStat`) y la barra de nivel/XP en tinta. Después, secciones con `LifeQuestSectionHeading`: «Ahora» y «Hábitos de hoy · x/y».
- **`LifeQuestStat`**: cifra como tipografía (22/800 tabular) con su etiqueta; sin recuadro.
- **Filas de ajustes y dificultad**: filas de la hoja con filete; la opción elegida va en negrita con `SheetCheck` lleno, sin caja ni icono decorativo.
- **`LifeQuestListRow`**: el icono es opcional y solo se usa cuando distingue tipos.
- **`LifeQuestSurface`**: sin color es una sección de la hoja separada por filete (nada de tarjetas dentro de la hoja); con color es un bloque relleno de radio 10.
- **`QuestlyNavBar`**: 5 pestañas (Hoy · Tareas · Hábitos · Foco · Tú) sobre el suelo con filete superior; activa en tinta con trazo de 2 bajo el icono y etiqueta 800; resto gris 500.
- **Botón flotante**: tinta, radio 16, abre la Bandeja.
- **Toast y segmentado**: únicas sombras suaves (toast 0/10/24 al 16 %; segmento activo 0/1/3 al 10 %).
- **Foco**: siempre oscuro (`questlyTheme(dark: true)`), mismo sistema de hoja; el cronómetro usa cifras de `numeral`.

## Movimiento

| Qué | Duración | Curva |
|---|---|---|
| Presión (`QuestlyPressable`, todo lo pulsable): escala 0,97 | 160 ms | `Cubic(0.23, 1, 0.32, 1)` |
| Marcar fila: relleno del check y tachado | 200 ms | ease-out fuerte |
| Hoja inferior (salida 200 ms) | 250 ms | cajón `Cubic(0.32, 0.72, 0, 1)` (`QMotion.drawer`) |
| Toast: sube 24 y aparece | 250 ms | ease-out fuerte |
| Diálogo: de 0,95 a 1 con opacidad, centrado | 200 ms | ease-out fuerte |
| Check: el visto entra de 0,8 a 1 | 160 ms | ease-out fuerte |

- Sin salpicadura de tinta (`NoSplash`); la respuesta es la escala.
- Nada anima en acciones que se repiten cientos de veces al día más allá de la presión.
- Reducción de movimiento: toda duración pasa por `context.motion(...)` y queda en 0.

## Hacer / no hacer

- **Sí:** un rojo por pantalla y solo para fecha, fila actual o «ahora»; acciones siempre en tinta.
- **Sí:** contenido en la hoja, títulos sobre el suelo; secciones separadas por filetes, no por tarjetas.
- **Sí:** cifras tabulares en horas, contadores y el número de la hoja.
- **Sí:** tono de invitación en los textos («Nada pendiente», «Empezar foco»).
- **No:** rojo como color de botón, enlace o decoración; no un segundo número gigante en la misma pantalla.
- **No:** antetítulos en MAYÚSCULAS espaciadas, tarjetas grises dentro de la hoja (salvo un bloque de resumen `tint` por pantalla), chips de fecha, sombras fuera del toast y el segmentado.
- **No:** encuadernación ni talones fuera de Hoy.
- **No:** ambientación de fantasía (reino, héroe, mazmorra, monedas).

## Accesibilidad (WCAG 2.1 AA)

- Contraste: tinta sobre hoja y suelo > 15:1; `text2` `#6B6862` sobre blanco ≈ 5,5:1 y sobre suelo ≈ 4,8:1; rojo `#D7262E` sobre blanco ≈ 5,0:1 (en oscuro `#FF6B70` sobre `#1E1D1B`).
- Toques ≥ 44, objetivos de check y píldora a 48; `materialTapTargetSize.padded`.
- El color nunca va solo: la fila actual lleva barra, peso 700 y su píldora; lo hecho lleva check y tachado.
- `Semantics`: el bloque de fecha se lee como una frase («Hoy, domingo 1 de noviembre. 2 pendientes · racha 12 días»); el check anuncia `checked` y su etiqueta; la decoración de la hoja se excluye; títulos con `header`.
- Anillo de foco de teclado de 3 en `focus`.
