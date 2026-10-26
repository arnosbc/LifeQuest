import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/missions/domain/entities/mission.dart';
import 'package:proyecto_movil/features/missions/presentation/widgets/missions_format.dart';

/// La primera misión del Daily Highlight (RF-089).
class PrioritizedMissionCard extends StatelessWidget {
  const PrioritizedMissionCard({
    super.key,
    required this.mission,
    required this.now,
    required this.busy,
    required this.onComplete,
  });

  final Mission mission;
  final DateTime now;
  final bool busy;

  /// Null mientras otra acción está en curso.
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) => LifeQuestSurface(
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'MISIÓN PRIORIZADA',
              style: TextStyle(
                color: LifeQuestColors.deepGreen,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
            Icon(Icons.shield_outlined, color: LifeQuestColors.green, size: 19),
          ],
        ),
        const SizedBox(height: 11),
        Text(
          mission.title,
          style: const TextStyle(
            color: LifeQuestColors.ink,
            fontSize: 20,
            height: 1.2,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (mission.description case final description?) ...[
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(color: LifeQuestColors.muted, fontSize: 12),
          ),
        ],
        const SizedBox(height: 13),
        _detail('Origen', MissionsFormat.origin(mission)),
        _detail('Urgencia', MissionsFormat.bucket(mission.bucket)),
        _detail('Fecha límite', MissionsFormat.due(mission.dueDate, now)),
        if (mission.subtasksTotal > 0)
          _detail(
            'Subtareas',
            '${mission.subtasksDone} de ${mission.subtasksTotal}',
          ),
        const Divider(height: 20),
        _detail(
          'Recompensa',
          '${mission.xpReward} XP    ·    ${mission.coinReward} monedas',
        ),
        const SizedBox(height: 9),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton.icon(
            onPressed: busy ? null : onComplete,
            icon: busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded),
            label: Text(busy ? 'Completando…' : 'Completar misión'),
            style: FilledButton.styleFrom(
              backgroundColor: LifeQuestColors.green,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _detail(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: LifeQuestColors.muted, fontSize: 11),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: LifeQuestColors.deepGreen,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}
