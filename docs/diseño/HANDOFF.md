# HANDOFF.md — Cómo usar este paquete con Claude Code

Este paquete es la entrega del diseño de Questly al proyecto de código.

| Archivo / carpeta | Qué es |
|---|---|
| `DESIGN.md` | Sistema de diseño: colores, temas, tipografía, componentes, movimiento, tono y accesibilidad. Formato compatible con Impeccable. |
| `PRODUCT.md` | Contexto del producto: qué es, para quién, principios, navegación y reglas del juego. Compatible con Impeccable. |
| `tokens/questly_theme.dart` | Los mismos tokens listos para Flutter (`ThemeData`, colores, radios, tipografía, animaciones). |
| `design/pantallas/*.dc.html` | Fuente de cada pantalla del lienzo: estructura, textos, estados y lógica de interacción. |
| `design/questly.css` | Animaciones y capa de modo oscuro y temas (referencia de cómo se reasignan los colores). |
| `design/canvas.json` | Índice del lienzo (orden y título de cada tablero). |
| `docs/ideas-proyecto-productividad-gamificada.md` | Documento de ideas con todas las decisiones y la economía. |

> **Importante:** los `.dc.html` son la **fuente** del diseño, no pantallas para abrir en el navegador; necesitan el motor del lienzo para verse. Para **ver** el diseño usa el lienzo en claude.ai. Para **construir**, Claude Code lee estos archivos: cada uno tiene el marcado con estilos en línea (medidas y colores exactos), los textos finales y, al final, un bloque `class Component` con los datos de ejemplo y el comportamiento.

## Cómo leer un `.dc.html`
- `{{variable}}`: valor que calcula el bloque de lógica (`renderVals()` / `rv()`).
- `<sc-for list="{{items}}" as="x">`: lista que se repite; `<sc-if value="{{cond}}">`: condición.
- `<dc-import name="Hero" ...>`: uso del componente cabecera (`Hero.dc.html`).
- `onClick="{{fn}}"`: acción; la función está en el mismo bloque de lógica.
- `data-mode` y `data-theme` en la raíz: modo oscuro y tema, que en Flutter se resuelven con `questlyTheme(realm:, dark:)`.

## Pantallas (60 tableros)
| Archivo | Pantalla |
|---|---|
| `Main.dc.html` | Inicio |
| `Stage.dc.html` | Stage · Hoy |
| `Habitos.dc.html` | Hábitos |
| `Mazmorra.dc.html` | Deep Working · Preparar incursión |
| `MazmorraSesion.dc.html` | Deep Working · Sesión en curso |
| `Perfil.dc.html` | Perfil del Personaje |
| `Diario.dc.html` | Diario · Bitácora |
| `Configuracion.dc.html` | Configuración · Game Master |
| `ConfiguracionOscuro.dc.html` | Configuración · Modo oscuro + tema Río |
| `StageCalendario.dc.html` | Stage · Calendario |
| `StageBiblioteca.dc.html` | Stage · Biblioteca |
| `StageProyectos.dc.html` | Biblioteca · Proyectos |
| `StageMetas.dc.html` | Biblioteca · Metas |
| `StageAreas.dc.html` | Biblioteca · Áreas |
| `StageRecursos.dc.html` | Biblioteca · Recursos |
| `StageEventos.dc.html` | Biblioteca · Eventos |
| `StageEventoNuevo.dc.html` | Eventos · Nuevo evento |
| `StageArchivo.dc.html` | Biblioteca · Archivo |
| `Taverna.dc.html` | Taverna · Salón |
| `TavernaNPC.dc.html` | Taverna · Ficha del NPC |
| `CrearNPC.dc.html` | Taverna · Crear NPC |
| `MazmorraMochila.dc.html` | Deep Working · Llenar la mochila |
| `Crear.dc.html` | Crear · ¿Qué quieres crear? |
| `CrearTarea.dc.html` | Crear Tarea |
| `CrearProyecto.dc.html` | Crear Proyecto |
| `CrearMeta.dc.html` | Crear Meta · S.M.A.R.T. |
| `MetaResumen.dc.html` | Meta · Resumen S.M.A.R.T. |
| `Diagnostico.dc.html` | Diagnóstico GTD |
| `MomentoNivel.dc.html` | Momento · Subida de nivel |
| `MomentoXP.dc.html` | ¿Cómo funciona? · XP |
| `MomentoHP.dc.html` | ¿Cómo funciona? · Vida (HP) |
| `Hero.dc.html` | Componente · Cabecera de página |
| `Marketplace.dc.html` | Marketplace · Tienda del héroe |
| `BossFight.dc.html` | Boss Fight · Meta en combate |
| `VisionBoard.dc.html` | Vision Board · Pilares de vida |
| `Inventario.dc.html` | Inventario y logros |
| `Estadisticas.dc.html` | Estadísticas · Semana |
| `EstadisticasMes.dc.html` | Estadísticas · Mes |
| `MisionActual.dc.html` | RPGenie · Misión actual |
| `MainOscuro.dc.html` | Inicio · Modo oscuro |
| `StageBrasa.dc.html` | Stage · Tema Brasa |
| `Onboarding.dc.html` | Onboarding · Comienza tu aventura |
| `BrainDump.dc.html` | Brain Dump · Bandeja de captura |
| `BrainDumpOrdenar.dc.html` | Brain Dump · Ordenar con RPGenie |
| `Auth.dc.html` | Acceso · Iniciar sesión |
| `AuthRegistro.dc.html` | Acceso · Registrarse |
| `AuthRecuperar.dc.html` | Acceso · Recuperar contraseña |
| `ConfiguracionSalir.dc.html` | Configuración · Cerrar sesión |
| `ProyectoDetalle.dc.html` | Proyecto · Detalle y tareas |
| `ProyectoSinArea.dc.html` | Proyecto · Aviso sin área |
| `AreaDetalle.dc.html` | Área · Detalle de la skill |
| `CrearHabito.dc.html` | Crear hábito · Bueno |
| `CrearHabitoMalo.dc.html` | Crear hábito · Malo |
| `Notificaciones.dc.html` | Avisos · Centro de notificaciones |
| `NotificacionesPush.dc.html` | Avisos · En el móvil y tono |
| `EstadosVacios.dc.html` | Estados · Vacíos |
| `EstadosAlerta.dc.html` | Estados · Errores y momentos difíciles |
| `SistemaDiseno.dc.html` | Sistema de diseño «Bosque vivo» |
| `Economia.dc.html` | Economía del reino |
| `Especificacion.dc.html` | Especificación para desarrollo |

*(Las variantes como `MainOscuro`, `StageBrasa`, `CrearTarea` o `ProyectoSinArea` reutilizan otra pantalla con un estado distinto: sirven para ver ese estado, no son pantallas nuevas. `SistemaDiseno`, `Economia` y `Especificacion` son tableros de documentación.)*

## Orden sugerido de construcción (MVP)
1. Tema y tokens (`questly_theme.dart`), componente Hero, navegación de 5 pestañas, tarjetas, botones y toasts.
2. Acceso (`Auth`) y `Onboarding`.
3. `Main` (Inicio), `Stage` (Hoy), `Crear` (Tarea) y `Habitos`.
4. `Mazmorra` (preparar, mochila y sesión), `Perfil`, `Diario` y `Configuracion`.
5. Fase 2 en adelante: Proyectos/Áreas, Metas + `BossFight`, `Marketplace` con la economía, `Taverna`, `MisionActual`, `Estadisticas` y `Notificaciones`.
