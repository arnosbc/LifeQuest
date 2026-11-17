import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/dungeon/presentation/widgets/cycle_duration_card.dart';

/// Lo ganado en la sesión al cerrarla. [minutes] es el tiempo efectivo,
/// sin descansos ni pausas.
class SessionRewardsCard extends StatelessWidget {
  const SessionRewardsCard({
    super.key,
    required this.title,
    required this.xp,
    required this.coins,
    required this.cycles,
    required this.minutes,
    this.missions = 0,
  });

  final String title;
  final int xp;
  final int coins;
  final int cycles;
  final int minutes;
  final int missions;

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
              child: LifeQuestStat(
                value: '$coins Monedas',
                label: 'Monedas ganadas',
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            Expanded(
              child: LifeQuestStat(
                value: '$cycles',
                label: 'Bloques completados',
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
        const SizedBox(height: 7),
        Text(
          [
            if (missions > 0)
              '$missions ${missions == 1 ? 'tarea completada' : 'tareas completadas'}',
            'Tiempo efectivo: solo los ciclos de concentración superados, '
                'sin descansos ni pausas.',
          ].join(' · '),
          style: TextStyle(color: context.lq.muted, fontSize: 10),
        ),
      ],
    ),
  );
}
