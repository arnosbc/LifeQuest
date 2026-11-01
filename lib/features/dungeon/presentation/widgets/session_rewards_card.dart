import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/dungeon/presentation/widgets/cycle_duration_card.dart';

/// Lo ganado en la sesión (o el resumen al cerrarla).
class SessionRewardsCard extends StatelessWidget {
  const SessionRewardsCard({
    super.key,
    required this.title,
    required this.xp,
    required this.coins,
    required this.cycles,
    required this.minutes,
  });

  final String title;
  final int xp;
  final int coins;
  final int cycles;
  final int minutes;

  @override
  Widget build(BuildContext context) => LifeQuestSurface(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LifeQuestSectionHeading(title),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: LifeQuestStat(value: '$xp', label: 'XP ganada'),
            ),
            Expanded(
              child: LifeQuestStat(value: '$cycles', label: 'Ciclos'),
            ),
            Expanded(
              child: LifeQuestStat(
                value: CycleDurationCard.hours(minutes),
                label: 'En foco',
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
