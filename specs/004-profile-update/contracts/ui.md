# Contrato: pantalla de Perfil

Componentes existentes (`core/widgets`, widgets de `profile`) y colores de `context.lq`; nada nuevo.

## Tarjeta del personaje (`CharacterCard`)

- Bajo el nombre: el nombre del título activo, una línea con elipsis; **nada** si no hay título (sin texto vacío).
- Entrada «Elegir título» siempre visible (botón de texto ≥ 48 px de alto, `Semantics` de botón). Abre la hoja de títulos.

## Hoja de títulos (`profile_sheets.dart`)

- Con títulos ganados: «Sin título» + un renglón por título ganado (nombre y descripción); el activo marcado con icono **y** `Semantics(selected: true)`. Tocar uno cierra la hoja y dispara `ProfileActiveTitleChanged`.
- Sin títulos: estado vacío, sin botones de compra: «Aún no tienes títulos. Se ganan con logros, subiendo de nivel y llenando tu Tesoro del reino.»

## Estado del héroe (`HeroStatusCard`)

| Fila | Valor | Detalle |
|---|---|---|
| Vitalidad (HP) | `hp_current / hp_max` | Si `is_weakened`: «Vitalidad baja: ganas un 25 % menos de XP hasta recuperarte. Tus Monedas no cambian.» (icono de corazón roto + texto) |
| Monedas | `formatNumber(coins)` | «Para canjear en el Marketplace» (existente) |
| **Tesoro del reino** (nueva) | `formatNumber(treasury)` (ej. 12.500), también 0 | «Lo que no cabe en tu bolsa. No se gasta: es tu prestigio.» (provisional hasta `PRODUCT.md`) |
| Tasa de finalización | existente | existente |

## Accesos rápidos

Dos filas de 3 `ProfileQuickLink`, en este orden:

| # | Etiqueta | Acción |
|---|---|---|
| 1 | Diario | `onOpenJournal` → `/journal` |
| 2 | Estadísticas | `soon('Las Estadísticas')` |
| 3 | Vision Board | `soon('El Vision Board')` |
| 4 | Inventario y logros | `soon('El Inventario y los logros')` |
| 5 | Marketplace | `onOpenMarketplace` → `/marketplace` |
| 6 | Configuración | `onOpenSettings` → `/settings` |

Se quitan «Historial», «Game Master» y la fila «Apariencia» de CUENTA (quedan Notificaciones y Ayuda).

## Configuración

- `GameMasterCard` añade un `SettingLink` «Apariencia» («Modo claro, oscuro o del sistema.») que llama `onOpenAppearance` → `/settings/appearance` (la pantalla `AppearanceScreen` actual).
