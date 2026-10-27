import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/dungeon/presentation/widgets/cycle_duration_card.dart';

/// Lo ganado en la sesión (o el botín final al cerrarla).
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
    padding: const EdgeInsets.all(11),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: context.lq.muted,
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            Expanded(
              child: LifeQuestStat(value: '$xp XP', label: 'XP ganada'),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: LifeQuestStat(value: '$coins ◉', label: 'Monedas ganadas'),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            Expanded(
              child: LifeQuestStat(
                value: '$cycles 🔥',
                label: 'Ciclos completados',
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: LifeQuestStat(
                value: CycleDurationCard.hours(minutes),
                label: 'Tiempo efectivo',
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
