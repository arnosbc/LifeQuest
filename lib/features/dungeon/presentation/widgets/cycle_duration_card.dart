import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';

/// Elige el ciclo (25, 30 o 45 min) y la duración total en pasos de 30 min.
class CycleDurationCard extends StatelessWidget {
  const CycleDurationCard({
    super.key,
    required this.cycleMinutes,
    required this.totalMinutes,
    required this.onCycleChanged,
    required this.onTotalChanged,
    required this.breaksNote,
  });

  final int cycleMinutes;
  final int totalMinutes;
  final ValueChanged<int> onCycleChanged;
  final ValueChanged<int> onTotalChanged;

  /// Descansos del jugador (Configuración), p. ej. «Descansos: 5 min, y 15
  /// min cada 4 ciclos.».
  final String breaksNote;

  static String hours(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '$m min';
    return m == 0 ? '$h h' : '$h h $m min';
  }

  @override
  Widget build(BuildContext context) => LifeQuestSurface(
    padding: const EdgeInsets.all(11),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DURACIÓN DEL CICLO',
          style: TextStyle(
            color: LifeQuestColors.muted,
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 7),
        Wrap(
          spacing: 6,
          runSpacing: 5,
          children: [
            for (final minutes in const [25, 30, 45])
              ChoiceChip(
                label: Text('$minutes min'),
                selected: cycleMinutes == minutes,
                onSelected: (_) => onCycleChanged(minutes),
              ),
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          'DURACIÓN TOTAL',
          style: TextStyle(
            color: LifeQuestColors.muted,
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
        Row(
          children: [
            IconButton(
              tooltip: 'Quitar 30 minutos',
              onPressed: totalMinutes - 30 >= cycleMinutes
                  ? () => onTotalChanged(totalMinutes - 30)
                  : null,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Expanded(
              child: Text(
                '${hours(totalMinutes)} · ${totalMinutes ~/ cycleMinutes} ciclos',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: LifeQuestColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Añadir 30 minutos',
              onPressed: totalMinutes + 30 <= 480
                  ? () => onTotalChanged(totalMinutes + 30)
                  : null,
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
        Text(
          breaksNote,
          style: TextStyle(color: LifeQuestColors.muted, fontSize: 9),
        ),
      ],
    ),
  );
}
