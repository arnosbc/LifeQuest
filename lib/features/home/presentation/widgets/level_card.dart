import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';

class LevelCard extends StatelessWidget {
  const LevelCard({super.key});

  @override
  Widget build(BuildContext context) => LifeQuestSurface(
    padding: const EdgeInsets.all(11),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nivel 24 · Estratega',
                    style: TextStyle(
                      color: LifeQuestColors.ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '4,150 XP para subir de nivel',
                    style: TextStyle(color: LifeQuestColors.muted, fontSize: 9),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: LifeQuestColors.softGreen,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Text(
                '◉ 2,450',
                style: TextStyle(
                  color: LifeQuestColors.deepGreen,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 11),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progreso de XP',
              style: TextStyle(
                color: LifeQuestColors.ink,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '7,850 / 12,000',
              style: TextStyle(
                color: LifeQuestColors.ink,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        const LinearProgressIndicator(
          value: .65,
          minHeight: 5,
          color: LifeQuestColors.green,
          backgroundColor: Color(0xFFE3EEE7),
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        const SizedBox(height: 10),
        const Row(
          children: [
            Expanded(
              child: LifeQuestStat(value: '3 / 5', label: 'Misiones'),
            ),
            SizedBox(width: 7),
            Expanded(
              child: LifeQuestStat(value: '2 / 3', label: 'Hábitos'),
            ),
            SizedBox(width: 7),
            Expanded(
              child: LifeQuestStat(value: '45 min', label: 'En foco'),
            ),
          ],
        ),
      ],
    ),
  );
}
