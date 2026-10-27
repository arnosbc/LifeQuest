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
    final coins = HomeFormat.number(d.coins);

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
                      d.characterClass == null
                          ? 'Nivel ${d.level}'
                          : 'Nivel ${d.level} · ${d.characterClass}',
                      style: TextStyle(
                        color: context.lq.ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
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
              Semantics(
                label: '$coins monedas',
                excludeSemantics: true,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: context.lq.softGreen,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.toll_rounded,
                        size: 16,
                        color: context.lq.deepGreen,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        coins,
                        style: TextStyle(
                          color: context.lq.deepGreen,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
              minHeight: 8,
              color: context.lq.green,
              backgroundColor: context.lq.softGreen,
              borderRadius: const BorderRadius.all(Radius.circular(8)),
            ),
          ),
          if (d.isWeakened) ...[
            const SizedBox(height: 12),
            // RF-034: avisa sin culpar; nunca bloquea acciones.
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: context.lq.warning.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.favorite_border_rounded,
                    size: 18,
                    color: context.lq.warning,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tu héroe está débil por ahora: gana un 10 % menos de '
                      'XP y monedas hasta recuperar su vitalidad.',
                      style: TextStyle(color: context.lq.ink, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: LifeQuestStat(
                  value: '${d.missionsDone} / ${d.missionsTotal}',
                  label: 'Misiones',
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
