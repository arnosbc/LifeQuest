import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';

class CycleDurationCard extends StatelessWidget {
  const CycleDurationCard({super.key});

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
            _duration('25 min', selected: true),
            _duration('30 min'),
            _duration('45 min'),
            _duration('5 min descanso'),
          ],
        ),
      ],
    ),
  );

  Widget _duration(String label, {bool selected = false}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: selected ? LifeQuestColors.softGreen : const Color(0xFFF6FAF7),
      border: Border.all(
        color: selected ? LifeQuestColors.deepGreen : LifeQuestColors.line,
      ),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: LifeQuestColors.deepGreen,
        fontSize: 9,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
