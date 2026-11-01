# Diseño de LifeQuest

Estilo **minimal sobrio** (referencias: Things, Linear). La app es un asistente de productividad, no un juego de fantasía: nada de reinos, héroes ni ilustraciones.

## Principios
- Un solo acento (índigo) por pantalla. El resto, neutros zinc.
- Tarjetas planas con borde de 1 px. Sombra solo en toast y control segmentado (suave).
- Mucho aire: gutter de 20 px y 24 px entre bloques.
- Cada pantalla tiene una acción principal clara. Nada de bloques de texto que solo informan.
- Foco (Pomodoro) siempre en oscuro.
- WCAG 2.1 AA: contraste 4,5:1, zonas táctiles ≥ 44 px, `Semantics` en botones de icono, el color nunca va solo.

## Tokens (`lib/core/theme/questly_theme.dart`)

| Rol | Claro | Oscuro |
|---|---|---|
| Fondo | `#FAFAFA` | `#09090B` |
| Tarjeta | `#FFFFFF` | `#18181B` |
| Borde | `#E4E4E7` | `#27272A` |
| Texto | `#18181B` | `#FAFAFA` |
| Texto secundario | `#52525B` | `#A1A1AA` |
| Acento | `#4F46E5` | `#4F46E5` |
| Acento tinta / tinte | `#3730A3` / `#EEF2FF` | `#A5B4FC` / `#1E1B4B` |
| Error · mal hábito | `#B91C1C` | `#FCA5A5` |
| Aviso · racha | `#92400E` | `#FCD34D` |
| Info | `#1D4ED8` | `#BFDBFE` |

- **Tipografía:** Inter (`assets/fonts`, OFL): display 32/700, título 26/700, 20/600, 17/600; cuerpo 15; etiqueta 14/500; meta 12/500; números con cifras tabulares.
- **Radios:** chip 6 · control 8 · botón 10 · bloque 12 · tarjeta 14 · hoja 20 · píldora.
- **Movimiento:** 80 ms al pulsar (opacidad), 200 ms fundido, 250 ms hoja. Se anula si el sistema pide reducir movimiento (`context.motion`).

## Código
- Paletas: `context.q` (`QuestlyPalette`) y `context.lq` (`LifeQuestPalette`, nombres antiguos derivados de la misma paleta).
- Componentes: `lib/core/widgets/questly/` (botón, tarjeta, chip, hoja, diálogo, toast, segmentado, barra inferior) y `lib/core/widgets/lifequest_*.dart`.
- Navegación: Hoy · Tareas · Hábitos · Foco · Tú.
