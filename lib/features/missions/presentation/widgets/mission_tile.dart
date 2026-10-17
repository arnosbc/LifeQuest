import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/missions/domain/entities/mission.dart';

class MissionTile extends StatelessWidget {
  const MissionTile({super.key, required this.mission});

  final Mission mission;

  @override
  Widget build(BuildContext context) => LifeQuestSurface(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    child: Row(children: [
      LifeQuestIconTile(mission.started ? Icons.play_circle_outline : Icons.flag_outlined),
      const SizedBox(width: 9),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(mission.title, style: const TextStyle(color: LifeQuestColors.ink, fontSize: 11, fontWeight: FontWeight.w700)),
        Text('${mission.due} · ${mission.duration}', style: const TextStyle(color: LifeQuestColors.muted, fontSize: 9)),
      ])),
      Text('${mission.xp} XP', style: const TextStyle(color: LifeQuestColors.deepGreen, fontSize: 9, fontWeight: FontWeight.w700)),
    ]),
  );
}
