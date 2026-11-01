import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/home/domain/entities/home_dashboard.dart';
import 'package:proyecto_movil/features/home/presentation/widgets/home_format.dart';

class LevelCard extends StatelessWidget {
  const LevelCard({super.key, required this.dashboard});

  final HomeDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final d = dashboard;
    final xpLeft = (d.xpToNextLevel - d.currentXp).clamp(0, d.xpToNextLevel);
    final progress = d.xpToNextLevel == 0
        ? 0.0
        : (d.currentXp / d.xpToNextLevel).clamp(0.0, 1.0);

    return LifeQuestSurface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nivel ${d.level}',
                      style: TextStyle(
                        color: context.lq.ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Te faltan ${HomeFormat.number(xpLeft)} XP para el '
                      'nivel ${d.level + 1}',
                      style: TextStyle(color: context.lq.muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _Streak(days: d.streakDays),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Progreso de XP',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.lq.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${HomeFormat.number(d.currentXp)} / '
                '${HomeFormat.number(d.xpToNextLevel)}',
                style: TextStyle(
                  color: context.lq.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Semantics(
            label: 'Progreso de XP',
            value: '${(progress * 100).round()} %',
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              color: context.lq.green,
              backgroundColor: context.lq.softGreen,
              borderRadius: const BorderRadius.all(Radius.circular(8)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: LifeQuestStat(
                  value: '${d.missionsDone} / ${d.missionsTotal}',
                  label: 'Tareas',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: LifeQuestStat(
                  value: '${d.habitsDone} / ${d.habitsTotal}',
                  label: 'Hábitos',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: LifeQuestStat(
                  value: HomeFormat.minutes(d.focusMinutes),
                  label: 'En foco',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Racha de hábitos: ámbar con número y texto, nunca solo color.
class _Streak extends StatelessWidget {
  const _Streak({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Racha de ${days == 1 ? '1 día' : '$days días'}',
    excludeSemantics: true,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: context.q.mustardTint,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department_outlined,
            size: 16,
            color: context.q.mustardInk,
          ),
          const SizedBox(width: 4),
          Text(
            days == 1 ? '1 día' : '$days días',
            style: TextStyle(
              color: context.q.mustardInk,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}
