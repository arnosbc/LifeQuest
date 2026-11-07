---
version: 1
slug: "ome-presentation-screens-home-screen-dart-ba4a8f7d"
primary_target: "lib/features/home/presentation/screens/home_screen.dart"
related_targets: ["lib/app/config/app_shell.dart"]
---

# Questly · app (Hoy y pestañas)

Modo: Operate. Público: cualquier persona ordenando su día desde el celular, en momentos cortos y con una mano. Tarea principal: ver qué toca ahora y hacerlo (marcar, empezar foco, capturar). Restricciones: Material 3 para estructura y controles, español, WCAG AA, Foco siempre oscuro, sin fantasía.

## Direction contract

THESIS: Cada día es una hoja de calendario de taco: un número rojo gigante y lo que toca hoy escrito debajo. Rechaza la lista gris con chips de fecha que entrega toda app de tareas.

OWN-WORLD: Suelo papel gris cálido #F1EFEA, hoja blanca con borde superior arrancado y talones de hojas pasadas bajo una encuadernación grafito. Tinta #111111, gris #6B6862, filetes #E4E1DA y discontinuos. Un solo rojo #D7262E para la fecha, la tarea en curso y «ahora». Archivo de 400 a 900; cifras tabulares. Botones píldora en tinta.

STORY: Abre, ve la fecha y cuántas le quedan, toca la fila roja para empezar foco, marca hábitos con un toque y captura con el botón flotante.

FIRST VIEWPORT: Encuadernación y dos talones arriba; hoja con «31» rojo de ~180 sp centrado, «viernes · octubre 2026», «3 pendientes · racha 12 días»; filete discontinuo; filas de 64 dp con check, hora tabular y título; la actual con barra roja y píldora «Empezar foco»; FAB tinta; barra inferior de 5 pestañas sobre el suelo.

FORM: Calendario de taco (IMPECCABLE’S PICK de la segunda mano), posición 1 de mi lista. seed:40b2bd93d875fc1e

FINISH: unreviewed and undocumented is unfinished; the finish reviewer and the documenter run before the build is reported done.

## Movimiento (Emil Kowalski)
Presión en todo lo pulsable: escala 0,97 en 160 ms ease-out (0.23, 1, 0.32, 1). Hojas y diálogos 250 ms. Marcar una fila: relleno y tachado en 200 ms. Nada anima en acciones de cientos de veces al día. Reducción de movimiento: solo opacidad.
