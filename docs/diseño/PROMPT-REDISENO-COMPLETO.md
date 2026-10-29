# Prompt: rediseño completo de la app (pasos 2 a 5 en una sola tarea)

Copia el bloque y pégalo en un chat nuevo de Claude Code abierto en la raíz del proyecto.
Requiere que el paso 1 ya esté hecho (tema, paleta, componentes y galería: ver `PLAN-REDISENO.md` §5 y §11).

---

```text
Vamos a aplicar el diseño Questly a TODA la app LifeQuest en una sola tarea: los pasos 2, 3,
4 y 5 de docs/diseño/PLAN-REDISENO.md §5. No lo dividas en entregas: un plan, una
aprobación y luego lo construyes todo. El paso 1 ya está hecho.

## Lectura obligatoria, antes de escribir código
1. docs/diseño/PLAN-REDISENO.md completo (sobre todo §1 regla de oro, §2 decisiones, §6
   lo que NO se construye, §7 contradicciones, §11 lo que dejó el paso 1 y §12 el
   Diagnóstico al crear). MANDA sobre
   cualquier otra instrucción de diseño.
2. CLAUDE.md (arquitectura obligatoria §8 y accesibilidad §14).
3. docs/diseño/HANDOFF.md, DESIGN.md y PRODUCT.md.
4. Lo que ya existe del sistema: lib/core/theme/ (questly_theme.dart, questly_palette.dart
   con context.q y context.motion(), questly_icons.dart) y lib/core/widgets/questly/
   (Hero, barra, tarjeta, botones, chips, segmentadas, hoja, diálogo, toast). Úsalos;
   crea componentes nuevos solo si el diseño los repite y no existen (p. ej. barra de
   progreso XP/vida/Monedas, nota de RPGenie, insignia hexagonal, campo de texto), en
   lib/core/widgets/questly/ con su prueba.
5. Para cada pantalla, su .dc.html en docs/diseño/design/pantallas/ (marcado con estilos
   en línea + bloque `class Component` al final) y la pantalla Flutter actual que la
   reemplaza. Lee la pantalla Flutter, su bloc y sus widgets antes de tocarla.
No uses Impeccable ni Spec Kit.

## Regla de oro
Solo cambia el diseño (con UNA excepción: el Diagnóstico al crear, descrito en el Alcance). Todo lo que hoy funciona con Supabase debe seguir funcionando igual:
mismos blocs, eventos, estados, usecases, repositorios, RPC y rutas. No toques SQL, Edge
Functions ni la capa data/domain (salvo lo mínimo que una pantalla necesite para mostrar un
dato que YA devuelve su RPC). No borres funcionalidades. Los elementos del diseño sin datos
se omiten (§6) y en los choques manda el código (§7). Nada de datos de ejemplo en las
pantallas reales.

## Alcance (todas las pantallas que existen hoy)
- Acceso: Login, Registro, Revisa tu correo (Auth*.dc.html). Onboarding (Onboarding.dc.html).
- Inicio (Main), Stage Hoy + Proyectos/Metas/Áreas/Recursos que hoy muestra Stage (Stage*),
  Misiones, hojas de Crear tarea/proyecto/meta/recurso (Crear*, CrearMeta), Hábitos y crear
  hábito (Habitos, CrearHabito*).
- Mazmorra: preparar, mochila y sesión (Mazmorra*, siempre oscura y respetando «reducir
  movimiento»). Perfil, Diario, Configuración (+ selector de tema del reino Bosque/Río/
  Brasa/Oro con AppearanceRealmChanged, según Configuracion*.dc.html), Apariencia, Ayuda.
- Boss Fight, Marketplace, Taverna, Misión actual (RPGenie), Estadísticas, Avisos, Brain
  Dump (+ hoja G.T.D.), Vision Board e Inventario.
- Estados vacíos y de error de cada pantalla con los textos de EstadosVacios y
  EstadosAlerta cuando apliquen a datos que ya existen.
- FUNCIONALIDAD NUEVA (única excepción a «solo diseño», ver PLAN-REDISENO.md §12):
  Diagnóstico G.T.D. al crear tareas, proyectos, metas y recursos. En la hoja «¿Qué quieres
  crear?» añade «No estoy seguro · Diagnosticar» con el flujo de Crear.dc.html (bloque
  `// Diagnóstico`): idea → preguntas de RPGenie → resultado (Referencia, Tarea rápida,
  Tarea con fecha, Tarea, Proyecto, Meta) → «Crear como …» abre el formulario que YA existe
  con el título escrito (Meta pasa por S.M.A.R.T.). Referencia ofrece «Guardar como
  Recurso» (formulario de recurso con el título). Sin SQL nuevo: usa create_task,
  create_project, create_goal y create_resource. Sin la pregunta de delegar (create_task no
  la admite; sigue solo en Brain Dump) y sin el «+20 XP». El árbol va en lib/core como Dart
  puro con pruebas de cada camino; la vista en lib/core/widgets/questly/. Ninguna feature
  importa otra: la navegación entre features va por callbacks desde app/. La hoja G.T.D.
  del Brain Dump conserva su comportamiento.
- Cada pantalla usa el Hero con el kicker, título, icono y acción de su .dc.html.

## Reglas de implementación
- Ningún color, fuente ni medida suelta: todo sale de context.q, QText, QSpace, QRadius,
  QSize y QMotion. Al migrar una pantalla deja de usar context.lq / LifeQuestColors.
- Cuando ya ninguna pantalla use la paleta vieja (context.lq, LifeQuestColors,
  LifeQuestTheme.lightOnly, core/widgets/lifequest_*), avísame antes de borrarla.
- Accesibilidad: zona táctil ≥ 44, Semantics o tooltip en botones de solo icono, contraste
  AA en claro, oscuro y los 4 temas, el color nunca como única señal (▲●▼, texto, cifra),
  y «reducir movimiento».
- Textos en español con el tono de DESIGN.md §7, tomados del .dc.html. Identificadores en
  inglés. Imports con package:proyecto_movil/...
- Respeta Clean Architecture: nada de lógica de negocio en widgets.
- Nada puede generar costos (sin servicios ni paquetes de pago).

## Forma de trabajo
1. Lee todo y muéstrame UN plan corto: pantallas en el orden en que las harás, componentes
   nuevos que crearás, archivos a modificar y cualquier choque nuevo que encuentres.
   Espera mi aprobación UNA sola vez.
2. Después constrúyelo todo sin pararte entre pantallas. Tras cada grupo (Acceso +
   Onboarding · Inicio/Stage/Crear/Hábitos · Mazmorra/Perfil/Diario/Configuración · resto)
   ejecuta `flutter analyze` y `flutter test` y corrige lo que falle antes de seguir.
   Actualiza las pruebas de widgets que busquen textos o widgets que el diseño cambió, sin
   cambiar lo que verifican (comportamiento).
3. Solo detente a preguntarme si algo obliga a cambiar comportamiento, borrar algo o tocar
   SQL. Lo demás, resuélvelo con PLAN-REDISENO.md y anótalo.
4. Al terminar: `flutter analyze` y `flutter test` completos en verde, y un resumen con lo
   hecho por pantalla, los componentes nuevos, lo que quedó omitido por falta de datos
   (§6), los choques que resolviste y cómo probarlo (recorrido manual de §9 en claro,
   oscuro y los 4 temas).
5. Actualiza PLAN-REDISENO.md (§5 estado, §11 notas) y CLAUDE.md §14 si cambió algo del
   sistema. No hagas commit hasta que yo lo pida.
```
