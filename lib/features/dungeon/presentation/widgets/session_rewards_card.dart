import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';

class SessionRewardsCard extends StatelessWidget {
  const SessionRewardsCard({super.key});

  @override
  Widget build(BuildContext context) => const LifeQuestSurface(
    padding: EdgeInsets.all(11),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RECOMPENSAS ESTIMADAS',
          style: TextStyle(
            color: LifeQuestColors.muted,
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 7),
        Row(
          children: [
            Expanded(
              child: LifeQuestStat(value: '150 XP', label: 'XP ganada'),
            ),
            SizedBox(width: 7),
            Expanded(
              child: LifeQuestStat(value: '60 ◉', label: 'Monedas ganadas'),
            ),
          ],
        ),
        SizedBox(height: 7),
        Row(
          children: [
            Expanded(
              child: LifeQuestStat(value: '2 🔥', label: 'Ciclos completados'),
            ),
            SizedBox(width: 7),
            Expanded(
              child: LifeQuestStat(value: '1 h 15 m', label: 'Tiempo efectivo'),
            ),
          ],
        ),
      ],
    ),
  );
}
