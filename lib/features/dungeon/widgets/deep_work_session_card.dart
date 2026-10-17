import 'package:flutter/material.dart';

import '../../../shared/lifequest_widgets.dart';

class DeepWorkSessionCard extends StatelessWidget {
  const DeepWorkSessionCard({super.key});

  @override
  Widget build(BuildContext context) => LifeQuestSurface(
    padding: const EdgeInsets.all(11),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SESIÓN DEEP WORKING',
          style: TextStyle(
            color: LifeQuestColors.muted,
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Estudiar para el parcial de Ingeniería de Software',
          style: TextStyle(
            color: LifeQuestColors.ink,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        const Row(
          children: [
            Expanded(
              child: LifeQuestStat(value: '3 h', label: 'Duración total'),
            ),
            SizedBox(width: 7),
            Expanded(
              child: LifeQuestStat(value: '1 h 15 m', label: 'Completado'),
            ),
          ],
        ),
        const SizedBox(height: 11),
        const Text(
          'TAREAS ASIGNADAS · 3 tareas · 2 avanzadas',
          style: TextStyle(
            color: LifeQuestColors.muted,
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
        _task('Revisar casos de uso y diagramas de secuencia', .75),
        _task('Resolver ejercicios de patrones de diseño', .4),
        _task('Repasar conceptos de testing y refactor', .2),
      ],
    ),
  );

  Widget _task(String title, double progress) => Container(
    margin: const EdgeInsets.only(top: 7),
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: LifeQuestColors.background,
      border: Border.all(color: LifeQuestColors.line),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: LifeQuestColors.ink,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                color: LifeQuestColors.deepGreen,
                backgroundColor: LifeQuestColors.line,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              '${(progress * 4).ceil()}/4',
              style: const TextStyle(color: LifeQuestColors.muted, fontSize: 9),
            ),
          ],
        ),
      ],
    ),
  );
}
