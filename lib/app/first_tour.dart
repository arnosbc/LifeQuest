import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/questly/questly.dart';

/// Guía de primera vez (al terminar el Onboarding): Nevi muestra en 3 pasos
/// el camino, la barra de arriba y el botón de ideas. Tocar fuera la cierra.
Future<void> showFirstTour(BuildContext context) async {
  const steps = [
    (
      'corriendo',
      'Tu camino de hoy',
      'En el Inicio cada tarea es una parada del camino. Tócala, empiézala '
          'en Foco y ganarás XP y Monedas.',
    ),
    (
      'corona',
      'La barra de arriba',
      'Ahí ves tu nivel, tu meta diaria de XP, tu racha 🔥, tus Monedas y '
          'tu Constancia.',
    ),
    (
      'pensando',
      'El botón de ideas',
      '¿Se te ocurre algo? Toca el bombillo y anótalo. Después decides qué '
          'hacer con eso.',
    ),
  ];
  for (final (i, (pose, title, message)) in steps.indexed) {
    final last = i == steps.length - 1;
    if (!context.mounted) return;
    final next = await showQuestlyDialog<bool>(
      context,
      title: i == 0 ? 'Hola, soy Nevi 👋 · $title' : title,
      message: message,
      content: Padding(
        padding: const EdgeInsets.only(bottom: QSpace.s),
        child: Column(
          children: [
            MascotPose(pose: pose, size: 110),
            const SizedBox(height: QSpace.xs),
            Text(
              '${i + 1} de ${steps.length}',
              style: QText.label(context.q.text3),
            ),
          ],
        ),
      ),
      actions: [
        Builder(
          builder: (context) => QuestlyButton(
            label: last ? '¡Vamos!' : 'Siguiente',
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ),
      ],
    );
    if (next != true) return;
  }
}
