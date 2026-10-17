import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';

class PriorityMissionCard extends StatelessWidget {
  const PriorityMissionCard({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) => LifeQuestSurface(
    padding: const EdgeInsets.all(10),
    child: Column(
      children: [
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LifeQuestIconTile(Icons.verified_user_outlined),
            SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Preparar presentación del proyecto',
                    style: TextStyle(
                      color: LifeQuestColors.ink,
                      fontSize: 12,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Hoy · 18:00 · Alta prioridad',
                    style: TextStyle(
                      color: LifeQuestColors.green,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            const Expanded(
              child: Text(
                '⚡ 350 XP    ◉ 120',
                style: TextStyle(
                  color: LifeQuestColors.ink,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(
              height: 32,
              child: FilledButton.icon(
                onPressed: onContinue,
                icon: const Icon(Icons.play_arrow_rounded, size: 16),
                label: const Text('Continuar'),
                style: FilledButton.styleFrom(
                  backgroundColor: LifeQuestColors.green,
                  visualDensity: VisualDensity.compact,
                  textStyle: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
