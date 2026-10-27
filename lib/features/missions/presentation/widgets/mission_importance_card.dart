import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';

class MissionImportanceCard extends StatelessWidget {
  const MissionImportanceCard({super.key});

  @override
  Widget build(BuildContext context) => LifeQuestSurface(
    color: context.lq.softGreen,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¿POR QUÉ ESTA MISIÓN ES IMPORTANTE?',
          style: TextStyle(
            color: context.lq.deepGreen,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Tiene un alto impacto en tu objetivo actual y la fecha límite se acerca. Avanzar en ella desbloqueará otras tareas importantes.',
          style: TextStyle(
            color: context.lq.muted,
            fontSize: 10,
            height: 1.4,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    ),
  );
}
