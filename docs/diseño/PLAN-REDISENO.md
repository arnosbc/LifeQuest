# PLAN-REDISENO.md — Aplicar el diseño Questly a LifeQuest

> Documento de contexto para el rediseño. Léelo completo antes de tocar código.
> Fecha: 2026-10-28. Rama de trabajo: `jhon_cambios`.
> Fuentes: `docs/diseño/HANDOFF.md`, `DESIGN.md`, `PRODUCT.md`, `tokens/questly_theme.dart`,
> `design/pantallas/*.dc.html`, `design/questly.css` y `CLAUDE.md` del proyecto.

---

## 1. Objetivo y regla de oro

Aplicar el diseño final «Bosque vivo» (Questly) a la app que **ya funciona** con Supabase.

**Regla de oro: solo cambia el diseño. Toda funcionalidad que hoy funciona debe seguir funcionando igual.**

1. **Se reviste lo que existe.** Cada pantalla toma el estilo Questly y conserva su bloc, sus usecases, sus RPC y sus rutas.
2. **Si un elemento del diseño no tiene datos en el código, no se inventa.** Se omite y se anota en la sección 6 (pendientes). Nada de datos de ejemplo en las pantallas reales.
3. **Si el diseño choca con una regla del código, manda el código** (economía, `game_rules`, RF). El texto se ajusta al valor real. Ver sección 7.
4. **No se toca SQL ni Edge Functions** en la fase visual. Las pruebas de `supabase/tests` no cambian.
5. **No se borra ni se reescribe código ajeno a la tarea.** Si algo choca con el diseño, se avisa antes de cambiarlo.
6. Se respeta la arquitectura de `CLAUDE.md` §8: Clean Architecture con Bloc, get_it, go_router, fpdart y equatable; nada de lógica en widgets; los textos van en español.

---

## 2. Decisiones ya tomadas (no volver a preguntar)

| Tema | Decisión |
|---|---|
| Integración | **Convivir.** `MaterialApp` usa el tema Questly. La paleta vieja (`LifeQuestPalette`, `context.lq`) se **recalcula desde los tokens Questly**, así las ~91 pantallas actuales toman los colores nuevos sin romperse. Se migran a los componentes nuevos una por una. |
| Navegación | La barra nueva de 5 pestañas (Inicio · Stage · Hábitos · Mazmorra · Perfil) **reemplaza** a la `NavigationBar` de `lib/app/config/app_shell.dart`. Cada pestaña sigue mostrando **su pantalla real**, no una vacía. Se conservan el botón de Brain Dump y el comportamiento `goBranch(initialLocation: true)`. |
| Carpetas | Tema en `lib/core/theme/`. Componentes en `lib/core/widgets/questly/`. Lo compartido vive en `core/` (CLAUDE.md §8). |
| Fuentes | Bricolage Grotesque, DM Sans y DM Mono **incluidas como assets** en `assets/google_fonts/` (licencia OFL). `GoogleFonts.config.allowRuntimeFetching = false`. Así funcionan sin internet y en las pruebas. |
| Paquetes nuevos | `google_fonts` (lo exige `questly_theme.dart`) y `flutter_svg` (los iconos y el paisaje del Hero son trazos SVG exactos del diseño). Ninguno más sin preguntar. |
| Modo y tema del reino | Claro / Oscuro / Automático + Bosque / Río / Brasa / Oro. Se guardan **en local**, igual que hoy el modo: se amplía `ThemePreference` / `AppearanceBloc` / datasource local de `lib/features/profile`. Sin columnas nuevas en Supabase. |
| Mazmorra | Siempre oscura (hoy se fuerza con `LifeQuestTheme.dark`; pasa a `questlyTheme(realm, dark: true)`). |
| Galería | Ruta `/diseno` (solo en modo debug) con todos los componentes, el Hero en sus 5 tonos y los selectores de modo y tema. Sirve para revisar el paso 1. |
| Marca | El código y el título de la app siguen como **LifeQuest**. «Questly» es solo el nombre del sistema visual. |
| Costos | Nada de lo que se haga en esta fase puede generar cobros (sin servicios pagos nuevos). |

---

## 3. Tokens: lo que trae `questly_theme.dart` y lo que falta

`tokens/questly_theme.dart` se copia **sin cambios** a `lib/core/theme/questly_theme.dart`. Le faltan tokens que sí están en `DESIGN.md` y `questly.css`. Van en una `ThemeExtension` aparte (`lib/core/theme/questly_palette.dart`, con acceso `context.q`), con un valor por modo y por tema:

| Token | Claro | Oscuro |
|---|---|---|
| `line` | `#EEF2EA` | `#24362C` |
| `text3` | `#3E4A42` | `#CFDACF` |
| `coralInk` | `#A8361F` | `#F5B8A8` |
| `coralTint` | `#FBE4DF` | `#3A1F1A` |
| `mustardInk` | `#6E4D00` | `#F5D896` |
| `mustardTint` | `#FBF0D3` | `#3A3016` |
| `river` | `#3C5BA8` | `#9FB8E8` |
| `riverInk` | `#2C4580` | `#B9CBF0` |
| `riverTint` | `#E3E9F7` | `#1E2A44` |
| Sombra de tarjeta | borde 1 px `#DCE4D4` + `0 4px 0 #DCE4D4` | borde 1 px `#2C4036` + `0 4px 0 #0B140F` |

**Sombra del botón principal por tema** (`questly.css`): Bosque `#1F5C39` · Río `#24396B` · Brasa `#7A2716` · Oro `#8A6200`.
**Botón destructivo:** fondo `#A8361F`, sombra `#7A2716`. **Borde del tonal en Oro:** `#B9890F`.
**Texto sobre el acento en Oro:** `#3D2B00` (ya está como `onAccent`).

**Tonos del Hero** (`Hero.dc.html`):

| Tono | Fondo | Sol | Colina 1 | Colina 2 | Árboles | Kicker |
|---|---|---|---|---|---|---|
| forest (Bosque) | `#1F5C39` | `#F2C66B` | `#2E7D4F` | `#276B44` | `#174A2E` | `#CFE8D7` |
| river (Río) | `#24396B` | `#F2C66B` | `#3C5BA8` | `#31498A` | `#1A2A52` | `#D3DDF4` |
| ember (Brasa) | `#7A2716` | `#F2C66B` | `#A8361F` | `#922F1B` | `#5A1C10` | `#F7D5CC` |
| gold (Oro) | `#5C4100` | `#FBF0D3` | `#8A6200` | `#765400` | `#3F2D00` | `#F5E3B0` |
| night (modo oscuro) | `#0E1B14` | `#E9EFE6` | `#1C2C24` | `#16241D` | `#0B140F` | `#9FDCB4` |

En modo oscuro el Hero usa siempre `night`. El texto del título es `#F3F6EF`. El badge es `#F2C66B` con texto `#1A1F1B`.

**Paleta vieja recalculada** (para que las pantallas sin migrar sigan legibles): `green` → acento · `deepGreen` → tinta del tema (en el modo actual) · `onDeepGreen` → blanco en claro, `bg` en oscuro · `ink` → `text` · `muted` → `text2` · `background` → `bg` · `surface` → `card` · `line` → `border` · `softGreen` → tinte · `outline` → `inputBorder` · `error` → `coralInk` · `warning` → `coral`.

---

## 4. Componentes del paso 1 (especificación)

Las medidas salen de `SistemaDiseno.dc.html`, `Hero.dc.html` y `Main.dc.html`. Todos leen colores y medidas del tema: **nada de colores sueltos en los widgets**.

| Componente | Especificación |
|---|---|
| **Hero** | 156 px de alto, esquinas inferiores de 26, paisaje SVG (sol, colinas y árboles). Props: `kicker`, `heading` (title1, máx. 260 px de ancho), `icon` (sword, home, board, leaf, user, book, gear, mug, flame, coin, crown, star, boss, inbox, calendar, archive), `tone`, volver (44×44, `Semantics` «Volver»), acción (44×44, radio 14, fondo `rgba(243,246,239,.14)`, icono plus/gear/edit/bell, `Semantics` obligatorio) y `badge`. Padding 10/12/0/20. |
| **Barra de navegación** | Fondo `card`, borde superior 1 px `border`, padding 4/4/10. Cada ítem tiene alto mínimo 56. La pestaña activa lleva una píldora de 44×28 con el tinte y texto e icono en tinta, 12 px y peso 700; la inactiva va en `text2`. Iconos SVG de `Main.dc.html`. `Semantics(selected:)` en cada ítem. |
| **Tarjeta** | Radio 20, fondo `card`, borde 1 px + sombra sólida de 4 px. Si se puede pulsar, baja 3 px y pierde la sombra durante 80 ms. |
| **Botones** | Principal (alto 52, radio 14, acento + sombra de 4 px del tema, texto 16/700) · Secundario (borde 1,5 `inputBorder`, fondo `card`) · Tonal (alto 48, borde 1,5 acento, fondo tinte, texto tinta 15/700) · Destructivo (coral + sombra) · Texto (alto 44, tinta 14/700) · Desactivado (`#7D8A80`, y **el texto explica por qué**). Al pulsar bajan 3 px. Alto mínimo 44. |
| **Chips** | Filtro activo: píldora, fondo `text`, texto blanco 13/700, alto 44. Filtro inactivo: borde 1,5 `inputBorder`. Chip de Área: tinte y tinta, 12/700, padding 3/9. Prioridad: radio 6 con símbolo ▲ Alta / ● Media / ▼ Baja (el color nunca va solo). |
| **Pestañas segmentadas** | Fondo `track`, radio 14, padding 4, separación 4. La activa es `card` con sombra `0 1px 3px rgba(30,42,34,.12)` y radio 11. Alto 44, texto 14/700. Llevan `Semantics` de pestaña seleccionada. |
| **Hoja inferior** | Radio superior 24, tirador de 40×5 en `border`, altura máxima del 82–90 %, padding 10/22/26 y separación 14. Título en title2 con botón cerrar de 44×44 (`Semantics` «Cerrar»). Fondo `rgba(18,34,24,.5)`. Entra en 300 ms. |
| **Diálogo** | Radio 24, título obligatorio, cierre visible, foco atrapado. Fondo `rgba(18,34,24,.55–.7)` con aparición de 250 ms. |
| **Toast** | Fondo `text`, texto `bg`, radio 14, padding 12/14, sombra `0 10px 24px rgba(30,42,34,.22)`. Se anuncia como estado (`Semantics(liveRegion: true)`), dura 2,2 s y puede llevar «Deshacer». |
| **Movimiento** | press 80 ms · sheet 300 ms · fade 250 ms (`QMotion`). Con «reducir movimiento» del sistema (`MediaQuery.disableAnimations`) se usan duraciones de 0. |

**Accesibilidad (obligatoria):** zona táctil ≥ 44×44, `Semantics`/`tooltip` en todo botón de solo icono, contraste AA en claro, en oscuro y en los 4 temas, el color nunca como única señal y el mostaza `#D9A21B` solo como relleno junto a su cifra.

---

## 5. Orden de construcción

| Paso | Contenido | Estado |
|---|---|---|
| **1** | Tema y tokens + paleta, fuentes, Hero, barra de 5 pestañas sobre las pantallas reales, tarjeta, botones, chips, segmentadas, hoja, diálogo, toast y galería `/diseno` (`/settings/diseno`, se abre desde Configuración → Apariencia en debug). Modo y tema del reino guardados. | **Hecho (2026-10-28)** |
| 2 | Revestir Acceso (Login, Registro) y Onboarding. | **Siguiente** |
| 3 | Revestir Inicio, Stage (Hoy), Crear (tarea, proyecto, meta) y Hábitos. | Pendiente |
| 4 | Revestir la Mazmorra (preparar, mochila, sesión), Perfil, Diario y Configuración (selector de tema del reino aquí). | Pendiente |
| 5 | Revestir Proyectos y Áreas, Boss Fight, Marketplace, Taverna, Misión actual, Estadísticas, Avisos, Brain Dump, Vision Board e Inventario. | Pendiente |
| 6 | Funcionalidades nuevas de la sección 6, **una por una y con aprobación**. Primero las de IA de §13 (documentos de contexto del NPC). | Pendiente |

Después de cada paso: `flutter analyze`, `flutter test`, resumen, y **parar** hasta la revisión.

---

## 6. Funcionalidades que el diseño pide y el código NO tiene (no construir en la fase visual)

Cada una necesita RPC, columna o lógica nueva. En la fase visual **se omiten**. Se construyen después, con su migración, su RF y sus pruebas.

**Inicio / Stage / Crear**
- Inicio: lista «más tarde» marcable, «Boss del momento», captura rápida y nombre de rango por nivel («Explorador», «Guardabosques»).
- Stage Hoy: filtro Hoy/Mañana/7 días, desmarcar una tarea y estado «En progreso».
- **Calendario** (tareas por rango de fechas, incluidas las hechas y las vencidas).
- **Eventos**: `calendar_events` existe en `schema.sql`, pero sin RPC ni pantalla; falta «Asistí, +10 XP».
- **Archivo**: lista, motivo, restaurar y borrar (hoy solo hay contadores).
- **Detalle de Proyecto**: cambiar el área, fecha por tarea y modal de proyecto terminado.
- **Detalle de Área**: XP semanal por skill, proyectos y metas con su porcentaje.
- Recursos: favorito, grupo (Bandeja / Por revisar / Revisados) y área.
- Crear proyecto con fecha de inicio y tareas iniciales. Meta con «probabilidad %» y letras «sin verificar».
- Brain Dump: pestaña «Ordenadas» con destino.
- ~~Diagnóstico G.T.D. suelto desde Crear~~ → **pasó al alcance del rediseño** (ver §12). Queda fuera solo el «+20 XP · paso de bienvenida» (sin regla ni RPC).
- Misión actual: varias razones, cola de 2 siguientes, motivos de «Ahora no» (cansado, poco tiempo, ya no quiero).
- Boss Fight: consejo de RPGenie según los ataques y título al vencer.

**Hábitos / Mazmorra / Perfil y subpáginas**
- Hábitos: mapa de calor con 4 intensidades, meses anteriores, totales del mes y del año, frecuencia «X veces por semana», recordatorio con hora e «N veces este mes» en los malos.
- Mazmorra: buscador y filtros de la mochila con XP, prioridad, proyecto o meta y plazo; botín por tarea; ajustar la sesión en curso.
- **Estadísticas mensuales** (hoy `stats_overview` solo trae 7 + 7 días), vencidas, 7 puntos por día en hábitos, selector de rango.
- Diario: barras de XP por día y conteo de fallos.
- Vision Board: **Pilares** (tabla nueva) y «Crear meta en este pilar».
- Inventario: progreso de los logros, bloqueados y secretos, títulos bloqueados con su condición, «Usar» objetos (el catálogo de logros está vacío).
- Marketplace: **carrito** (compra múltiple), **Cofre** (abrir y premios), historial de compras, «Monedas de hoy» y tope de la bolsa.
- Configuración: «Resumen diario» (`digest_*` existe, falta exponerlo), aviso de racha en riesgo, **cambiar contraseña** y estado «Sincronizado».
- **Momentos**: modal de subida de nivel con confetti (el servidor ya devuelve `level_up` en `_award`, pero la app no lo lee) y hojas «¿Cómo funciona?» de XP y vida.

**Acceso / Onboarding / Taverna / Avisos / Estados**
- **Recuperar contraseña**: no hay usecase, pantalla ni ruta; falta también la pantalla de contraseña nueva.
- «Recordarme». Google y Apple siguen como «disponible pronto».
- Onboarding: emblema (Explorador / Guerrero / Sabio / Soñador, columna nueva), hasta 3 skills más una propia y primera misión creada al terminar.
- Taverna: **ficha del NPC** con historial, editar NPC, forma, color y papel del NPC, asistente de 4 pasos, «por qué» y Monedas de cada misión, misiones programadas por frecuencia y caducidad.
- Avisos: botón de acción (falta devolver `entity_type` y `entity_id`), pestañas Todos / Importantes, nuevos tipos (evento mañana, jefe herido, NPC listo, resumen del día, logro).
- **Notificaciones push** (FCM, resumen de las 21:00, silencio de noche): sin paquete hoy.
- Estados: **modo sin conexión** con cola local, esqueletos de carga (RPGenie si tarda más de 3 s) y búsqueda global.

---

## 7. Contradicciones diseño ↔ código (en la fase visual manda el código)

| Tema | Diseño | Código hoy | En la fase visual |
|---|---|---|---|
| Debilitado | vida < 30, −25 % XP | `game_rules` dice < 30; `001_home.sql` calcula ≤ 20 % | **Error real del código.** Corregir antes de rediseñar el estado de vida baja (requiere migración y aprobación). |
| Contraseña | ≥ 8, número, mayúsc./minúsc., barra de fuerza | ≥ 6 | Se mantiene ≥ 6. |
| Registro | sin «confirmar», va directo a Onboarding | confirmar + verificar correo | Se mantiene el flujo actual. |
| Daño al jefe | 6/8/12 por tarea, 28 por proyecto | daño = XP (mín. 10), proyecto 30 | Mostrar los valores reales. |
| Cofre del día | al terminar todas las tareas | con 3 misiones con Monedas | Texto según la regla real. |
| «Pendiente» en Hoy | tareas sin prioridad | tareas delegadas (decisión abierta, CLAUDE.md §11) | Se mantiene «delegadas». |
| XP de hábito | 5–13 variable, +2 por día limpio | fijo 10 | Mostrar 10. |
| Brain Dump | +2 XP por idea, +12 bandeja vacía, «Hazla ya» +5 | sin XP; «Hazla ya» 10 | Sin XP inventada. |
| Momento XP / vida | Monedas 40 %, Hotel +20, vida nunca 0 | 30 %, Hotel 10/25/total, la vida puede llegar a 0 | Valores reales. |
| Nivel | XP acumulada, +50 Monedas al subir | XP por nivel (100 × n^1,5), sin bonus | XP por nivel. |
| Mazmorra | tope 360 min, otra fórmula de ciclos | 480 min, `floor(total/ciclo)` | Lo del servidor. |
| Dificultad | «Fácil: más Monedas» | Monedas iguales (§13) | Sin ese texto. |
| Taverna | enfoque Meta / Proyectos / Hábitos | skill obligatoria; «Pedir misión» crea sola con IA (Gemini) | Se mantiene skill + IA. |
| Mapa de calor | colores Bosque / Mostaza / Río | — | Usa los colores del tema del reino. |
| Marca | Questly | LifeQuest | LifeQuest. |

---

## 8. Archivos del paso 1

**Nuevos**
```
assets/google_fonts/                  .ttf de Bricolage Grotesque, DM Sans, DM Mono (+ OFL.txt)
lib/core/theme/questly_theme.dart     copia exacta de docs/diseño/tokens/questly_theme.dart
lib/core/theme/questly_palette.dart   ThemeExtension con la sección 3 + context.q
lib/core/theme/questly_icons.dart     trazos SVG del diseño + widget QIcon
lib/core/widgets/questly/questly_hero.dart
lib/core/widgets/questly/questly_nav_bar.dart
lib/core/widgets/questly/questly_card.dart
lib/core/widgets/questly/questly_button.dart
lib/core/widgets/questly/questly_chip.dart
lib/core/widgets/questly/questly_segmented.dart
lib/core/widgets/questly/questly_sheet.dart
lib/core/widgets/questly/questly_dialog.dart
lib/core/widgets/questly/questly_toast.dart
lib/core/widgets/questly/questly.dart          barrel
lib/app/config/design_preview_screen.dart      galería /diseno (solo debug)
test/core/widgets/questly/questly_widgets_test.dart
```

**Se modifican**
- `pubspec.yaml`: añadir `google_fonts`, `flutter_svg` y los assets de fuentes.
- `lib/main.dart`: `GoogleFonts.config.allowRuntimeFetching = false`.
- `lib/app/app.dart`: `theme` y `darkTheme` = `questlyTheme(realm:, dark:)` + extensiones (`QuestlyPalette` y la `LifeQuestPalette` recalculada).
- `lib/app/config/theme.dart`: `LifeQuestPalette` construida desde los tokens Questly; `LifeQuestTheme.light/dark/lightOnly` siguen existiendo para no romper a quienes los usan.
- `lib/app/config/app_shell.dart`: `QuestlyNavBar` en lugar de `NavigationBar`.
- `lib/app/config/app_router.dart` y `route_paths.dart`: ruta `/diseno` (solo debug) y la Mazmorra en oscuro con el tema actual.
- `lib/features/profile/…`: `ThemePreference` (o una entidad hermana) con el tema del reino; `AppearanceBloc`, repositorio, usecases y datasource local; registro en `injection_container.dart`.
- Pruebas que se rompan por esos cambios (`test/app_test.dart`, `appearance_*`, mocks).

---

## 9. Verificación de cada paso

- `flutter analyze` sin errores ni avisos nuevos.
- `flutter test` completo en verde. Las pruebas de bloc y de usecases **no deben cambiar de resultado**.
- Pruebas nuevas: los componentes del paso tienen una prueba de widget mínima (se pintan en claro y oscuro, `Semantics` en los botones de icono, zona táctil ≥ 44, el toast desaparece a los 2,2 s).
- La galería `/diseno` se revisa en claro, oscuro, automático y en los 4 temas.
- Recorrido manual de la app: iniciar sesión, cambiar de pestaña, crear y completar una misión, registrar un hábito, entrar a la Mazmorra (siempre oscura), pedir una misión en la Taverna y comprar en el Marketplace. **Todo debe funcionar como antes.**
- `supabase/tests` (`npm test`) sin cambios: la fase visual no toca SQL.

---

## 10. Riesgos conocidos

- Al recalcular la paleta vieja, las pantallas sin migrar cambian de color de golpe. Algunas pueden verse raras hasta revestirlas, pero no se rompen.
- Las fuentes incluidas suman unos 1–2 MB a la app.
- `flutter_svg` es una dependencia nueva. Si se prefiere evitarla, la alternativa es dibujar los iconos con `CustomPainter`, con más código.
- La Edge Function `npc-mission` usa Gemini en capa gratis. No se toca en esta fase.
- **`dependency_overrides: path_provider_foundation: 2.4.1`** (`pubspec.yaml`): `google_fonts` trae `path_provider`, y desde la 2.5 `path_provider_foundation` compila un hook nativo (`objective_c`) que falla con espacios en la ruta del usuario de Windows («Jhon Bermudez») y rompe `flutter test`. Quitarlo cuando Dart lo corrija o el proyecto viva en una ruta sin espacios.
- El botón desactivado (blanco sobre `#7D8A80`) da unos 3,6:1, por debajo del 4,5:1 de texto normal. Es el valor del diseño; revisarlo con quien diseña.
- Zona táctil: se valida la regla del diseño (44 px, como iOS). La guía de Android pide 48 px.

## 12. Diagnóstico al crear (entra en el rediseño, 2026-10-28)

Pedido del usuario: el diagnóstico G.T.D. también al crear tareas, proyectos, metas y recursos.
Es lógica de la app (CLAUDE.md §5, RF-014): **no necesita SQL**; termina en los formularios
y RPC que ya existen (`create_task`, `create_project`, `create_goal`, `create_resource`).

- **Entrada:** en la hoja «¿Qué quieres crear?» (hoy `stage/presentation/widgets/quick_add_sheets.dart`
  y `missions/presentation/widgets/create_mission_sheet.dart`), el botón del diseño
  «No estoy seguro · Diagnosticar» (`Crear.dc.html`: borde discontinuo río, icono de ayuda).
- **Flujo** (`Crear.dc.html`, bloque `// Diagnóstico`): campo «¿Qué tienes en mente?»,
  conversación con RPGenie y respuestas en botones:
  1. ¿Es accionable? → No: **Referencia**.
  2. ¿Un solo paso o varios? → Varios: 3b.
  3. ¿Lo haces en 2 minutos? → Sí: **Tarea rápida** («¡Hazla ya!»).
  4. ¿Tiene fecha? → Sí: **Tarea con fecha** / No: **Tarea**.
  3b. ¿Semanas o meses? → **Proyecto** / **Meta** (pasa por S.M.A.R.T.).
  Resultado con «Es una …», su texto, «Crear como …» (abre el formulario con el título ya
  escrito) y «Empezar de nuevo».
- **Recursos:** el resultado **Referencia** ofrece «Guardar como Recurso» (abre el formulario
  de recurso con el título; `create_resource` sigue pidiendo su URL) y explica la opción del
  Brain Dump (Referencia / «Algún día»). Si se ofrece ir al Brain Dump, solo navega con un
  callback desde `app/` (ninguna feature importa otra).
- **Sin delegar:** la pregunta «¿Soy la persona correcta?» (RF-011) no está en este flujo
  porque `create_task` no crea tareas delegadas; sigue solo en el Brain Dump.
- **Arquitectura:** el árbol de preguntas es lógica compartida y pura (sin Flutter) en
  `lib/core/` (p. ej. `core/gtd/gtd_diagnosis.dart`, con prueba de cada camino) y la vista en
  `core/widgets/questly/`. La hoja G.T.D. del Brain Dump conserva su comportamiento
  (incluido delegar); puede reutilizar el árbol si no cambia lo que hace.
- **Fuera:** el «+20 XP · paso de bienvenida».

## 13. Funcionalidades con IA (después del rediseño, 2026-10-28)

No entran en el prompt del rediseño. Se construyen después, una por una y con aprobación.
Proveedor actual: Gemini capa gratis vía Edge Function (`supabase/functions/npc-mission`,
secrets `GEMINI_API_KEY` / `GEMINI_MODEL`).

**Reglas para toda función con IA**
- La IA solo **escribe y sugiere**; nunca decide XP, Monedas ni vida (anti-trampa, CLAUDE.md §8).
- El usuario confirma lo que propone. Si la IA falla, la app sigue con sus reglas y avisa sin culpa.
- Una llamada por acción del usuario; nada en segundo plano ni reintentos en bucle.
- **Sin costos:** solo capa gratis sin facturación (si se agota, responde 429 y se avisa).
- **Privacidad:** en la capa gratis Google puede usar el texto para entrenar → enviar solo lo
  necesario (nunca correo, id ni datos personales) y avisarlo en la UI.

**Prioridad 1 · Documentos de contexto del NPC** (p. ej. el plan de la asignatura para un NPC de programación móvil)
- El esquema ya lo prevé: `resources.npc_id` + `file_url` (CLAUDE.md glosario: «documento de contexto en `resources`»).
- Subida: PDF o texto, máx. 10 MB, a un bucket privado de **Supabase Storage** con RLS por usuario
  (ruta `<user_id>/<npc_id>/…`). Fila en `resources` con `npc_id`.
- Al subir, **una sola vez**, una Edge Function pide a Gemini un resumen útil (temas, unidades,
  fechas, entregas, ~1–2 k tokens) y lo guarda (columna nueva, p. ej. `resources.ai_summary`).
- `npc-mission` añade ese resumen al prompt junto a la noble misión y las últimas 5 misiones,
  para proponer misiones en el orden de la asignatura.
- UI: «Adjuntar documento» en la ficha / creación del NPC, lista de documentos con quitar, y el
  aviso «No subas documentos personales».
- Necesita: migración (bucket + políticas de Storage + columna), Edge Function nueva o ampliada,
  datasource/usecase en `tavern`, RF/UC nuevos y pruebas SQL de aislamiento entre usuarios.

**Prioridad 2 · Otras funciones (elegidas por el usuario)**
| Función | Dónde | Qué hace la IA |
|---|---|---|
| Ordenar Brain Dump | Brain Dump (`BrainDumpOrdenar.dc.html`) | Propone si cada idea es tarea, proyecto, meta o referencia; el usuario confirma con el G.T.D. de siempre |
| Dividir proyecto | Crear proyecto | Propone la lista de tareas iniciales a partir del título y la descripción |
| Revisar S.M.A.R.T. | Crear meta / Resumen | Marca cada letra «verificada» o «por mejorar» y sugiere cómo reescribirla |
| Observaciones y consejos | Estadísticas, Boss Fight, Misión actual, Taverna | Las 3 observaciones de la semana, el consejo contra el jefe, el «Ahora no» que propone algo más ligero y el «por qué» de cada misión de NPC |

## 11. Notas del paso 1 (2026-10-28)

- Tokens que faltaban: `lib/core/theme/questly_palette.dart` (`context.q`, `QHeroTone`, `context.motion()` para «reducir movimiento»). `questly_theme.dart` es copia exacta.
- Iconos: `lib/core/theme/questly_icons.dart` (`QIcons` + `QIcon`, trazos SVG del diseño).
- Componentes: `lib/core/widgets/questly/` (barrel `questly.dart`).
- Tema: `LifeQuestTheme.build(realm, dark:)` arma el tema Questly con las dos paletas; `LifeQuestColors` y `LifeQuestPalette` ya salen de los tokens (Bosque). `questlyRealmOf()` traduce `ThemeRealm` (dominio) a `QuestlyRealm`.
- Tema del reino: `ThemeRealm` + `GetThemeRealm` / `SaveThemeRealm`, clave local `theme_realm`, evento `AppearanceRealmChanged`. Aún sin selector visible: va en Configuración (paso 4); hoy se elige en la galería.
- Pruebas: `test/core/widgets/questly/questly_widgets_test.dart` y los casos del tema del reino en `appearance_bloc_test.dart`.
