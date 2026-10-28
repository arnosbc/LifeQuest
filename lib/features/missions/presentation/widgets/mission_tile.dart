import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/missions/domain/entities/mission.dart';
import 'package:proyecto_movil/features/missions/presentation/widgets/missions_format.dart';

class MissionTile extends StatelessWidget {
  const MissionTile({
    super.key,
    required this.mission,
    required this.now,
    required this.busy,
    required this.onComplete,
    this.menu,
  });

  final Mission mission;
  final DateTime now;
  final bool busy;

  /// Null mientras otra acción está en curso.
  final VoidCallback? onComplete;

  /// Menú «⋯» (renombrar, borrar).
  final Widget? menu;

  @override
  Widget build(BuildContext context) => LifeQuestSurface(
    padding: const EdgeInsets.fromLTRB(10, 4, 4, 4),
    child: Row(
      children: [
        LifeQuestIconTile(
          mission.bucket == MissionBucket.urgent
              ? Icons.priority_high
              : Icons.flag_outlined,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                mission.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.lq.ink,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${MissionsFormat.due(mission.dueDate, now)} · '
                '${MissionsFormat.origin(mission)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: context.lq.muted, fontSize: 9),
              ),
            ],
          ),
        ),
        Text(
          '${mission.xpReward} XP',
          style: TextStyle(
            color: context.lq.deepGreen,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (busy)
          SizedBox(
            width: 48,
            height: 48,
            child: Padding(
              padding: EdgeInsets.all(14),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: context.lq.deepGreen,
              ),
            ),
          )
        else
          IconButton(
            onPressed: onComplete,
            tooltip: 'Completar «${mission.title}»',
            icon: Icon(Icons.check_circle_outline, color: context.lq.deepGreen),
          ),
        ?menu,
      ],
    ),
  );
}
