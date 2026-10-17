import 'package:flutter/material.dart';

import '../../shared/lifequest_widgets.dart';

/// Objetivos: cada Meta es un Boss. "¡Sigue así!/Éxito/Fracaso" es solo una
/// piel de UI sobre objective_status (RF-084).
class GoalsPage extends StatelessWidget {
  const GoalsPage({super.key});

  static const _smart = [
    ('Específica', 'Correr una media maratón'),
    ('Medible', '21 km en menos de 2 h 15 min'),
    ('Alcanzable', 'Hoy corro 10 km cómodos'),
    ('Relevante', 'Skill Salud'),
    ('Temporal', 'Antes del 15 de marzo'),
  ];

  @override
  Widget build(BuildContext context) => LifeQuestPage(
    title: 'Objetivos',
    subtitle: 'Cada meta es un Boss que puedes vencer.',
    children: [
      const LifeQuestSectionHeading('BOSS FIGHT'),
      const SizedBox(height: 7),
      LifeQuestSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                LifeQuestIconTile(Icons.whatshot),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Media maratón',
                    style: TextStyle(
                      color: LifeQuestColors.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '¡Sigue así!',
                  style: TextStyle(
                    color: LifeQuestColors.green,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: const LinearProgressIndicator(
                value: .62,
                minHeight: 8,
                color: Color(0xFFD9534F),
                backgroundColor: Color(0xFFF6DADA),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Vida del Boss: 62 %',
              style: TextStyle(color: LifeQuestColors.muted, fontSize: 10),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      const LifeQuestSectionHeading('GROWTH · S.M.A.R.T.'),
      const SizedBox(height: 7),
      for (final (category, answer) in _smart)
        LifeQuestListRow(
          icon: Icons.check_rounded,
          title: category,
          subtitle: answer,
        ),
    ],
  );
}
