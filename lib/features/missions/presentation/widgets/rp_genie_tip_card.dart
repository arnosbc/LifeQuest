import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';

class RpGenieTipCard extends StatelessWidget {
  const RpGenieTipCard({super.key});

  @override
  Widget build(BuildContext context) => const LifeQuestSurface(
    child: Row(children: [
      LifeQuestIconTile(Icons.auto_awesome),
      SizedBox(width: 9),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('GENIE DE RP', style: TextStyle(color: LifeQuestColors.deepGreen, fontSize: 10, fontWeight: FontWeight.w800)),
        SizedBox(height: 5),
        Text('He revisado tu campaña, objetivos y plazos. Esta es la misión más importante para ti ahora.', style: TextStyle(color: LifeQuestColors.muted, fontSize: 10, height: 1.35)),
      ])),
    ]),
  );
}
