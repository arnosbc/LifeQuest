# Prompt para iniciar el rediseño (paso 1)

Copia todo lo que está dentro del bloque y pégalo en un chat nuevo de Claude Code, abierto en la raíz del proyecto.
Para los pasos siguientes, usa el mismo prompt y cambia solo la línea «Paso a construir».

---

```text
Vamos a aplicar el diseño Questly a LifeQuest. Paso a construir: PASO 1.

## Lectura obligatoria, antes de escribir código
1. docs/diseño/PLAN-REDISENO.md: contexto, decisiones tomadas, especificación de
   componentes, pendientes y contradicciones. MANDA sobre cualquier otra instrucción
   de diseño.
2. CLAUDE.md (arquitectura obligatoria §8, accesibilidad §14).
3. docs/diseño/HANDOFF.md, docs/diseño/DESIGN.md y docs/diseño/tokens/questly_theme.dart.
4. Los .dc.html que nombra el plan para este paso (Hero.dc.html, SistemaDiseno.dc.html y
   la barra de navegación de Main.dc.html) y docs/diseño/design/questly.css.
No uses Impeccable ni Spec Kit. Trabaja solo con estos archivos.

## Regla de oro
Solo cambia el diseño. Todo lo que hoy funciona con Supabase debe seguir funcionando igual:
mismos blocs, usecases, RPC y rutas. No toques SQL ni Edge Functions. No borres ni
reescribas código ajeno a la tarea. Si algo choca con el diseño, avísame antes de cambiarlo.
Los elementos del diseño sin datos en el código se omiten (PLAN-REDISENO.md §6) y, en las
contradicciones, manda el código (§7).

## Alcance del PASO 1 (PLAN-REDISENO.md §2, §3, §4 y §8)
- Copiar questly_theme.dart sin cambios a lib/core/theme/ y crear QuestlyPalette (context.q)
  con los tokens que faltan (§3).
- Fuentes como assets en assets/google_fonts/ y descarga en tiempo de ejecución desactivada.
- Añadir solo google_fonts y flutter_svg.
- MaterialApp con questlyTheme(realm, dark) en claro, oscuro y automático, y los 4 temas del
  reino guardados en local en AppearanceBloc (feature profile, respetando sus 3 capas).
- LifeQuestPalette (context.lq) recalculada desde los tokens Questly para que las pantallas
  actuales sigan funcionando.
- Componentes en lib/core/widgets/questly/: Hero, barra de 5 pestañas, tarjeta, botones
  (principal, secundario, tonal, destructivo, texto, desactivado con motivo), chips,
  pestañas segmentadas, hoja inferior, diálogo y toast.
- La barra nueva reemplaza a la de app_shell.dart, sobre las pantallas REALES de cada
  pestaña (no pantallas vacías). Se conserva el botón de Brain Dump.
- La Mazmorra sigue siempre oscura.
- Galería /diseno (solo en debug) con todos los componentes, el Hero en sus 5 tonos y los
  selectores de modo y tema, con datos de ejemplo SOLO en la galería.

## Reglas de implementación
- Ningún color, fuente ni medida suelta en los widgets: todo sale del tema o de context.q.
- Accesibilidad: zona táctil ≥ 44, Semantics o tooltip en todo botón de solo icono,
  contraste AA en claro, oscuro y los 4 temas, el color nunca como única señal, y respetar
  «reducir movimiento».
- Textos en español con el tono de DESIGN.md §7. Identificadores en inglés.
- Imports con package:proyecto_movil/...

## Forma de trabajo
1. Lee los archivos y muéstrame un plan corto: archivos a crear y modificar, y cualquier
   choque nuevo que encuentres. Espera mi aprobación.
2. Construye solo el paso indicado.
3. Al terminar, ejecuta `flutter analyze` y `flutter test` y corrige lo que falle. Añade
   pruebas de widget mínimas para los componentes nuevos (PLAN-REDISENO.md §9).
4. Dame un resumen: qué creaste, qué modificaste, cómo probarlo (galería /diseno y el
   recorrido manual de §9) y qué quedó pendiente.
5. Actualiza la tabla de estado de PLAN-REDISENO.md §5 y para ahí. No hagas commit hasta
   que yo lo pida.
```
