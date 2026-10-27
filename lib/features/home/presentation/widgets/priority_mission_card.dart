import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/home/domain/entities/home_dashboard.dart';
import 'package:proyecto_movil/features/home/presentation/widgets/home_format.dart';

/// La única acción primaria del Home: retomar la misión prioritaria o, si no
/// hay ninguna, crear la siguiente.
class PriorityMissionCard extends StatelessWidget {
  const PriorityMissionCard({
    super.key,
    required this.mission,
    required this.onContinue,
    required this.onCreate,
  });

  final PriorityMission? mission;
  final VoidCallback onContinue;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final mission = this.mission;
    return LifeQuestSurface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LifeQuestIconTile(
                mission == null
                    ? Icons.task_alt_rounded
                    : Icons.verified_user_outlined,
                size: 40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mission?.title ?? 'No tienes misiones pendientes',
                      style: TextStyle(
                        color: context.lq.ink,
                        fontSize: 17,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (mission == null)
                      Text(
                        'Captura una idea o crea tu próxima misión.',
                        style: TextStyle(color: context.lq.muted, fontSize: 13),
                      )
                    else
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          _Meta(
                            Icons.schedule_rounded,
                            HomeFormat.due(mission.dueDate, DateTime.now()),
                          ),
                          _Meta(
                            Icons.flag_outlined,
                            HomeFormat.priority(mission.priority),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (mission != null &&
              (mission.xpReward > 0 || mission.coinReward > 0)) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (mission.xpReward > 0)
                  _Reward(
                    Icons.bolt_rounded,
                    '+${HomeFormat.number(mission.xpReward)} XP',
                  ),
                if (mission.coinReward > 0)
                  _Reward(
                    Icons.toll_rounded,
                    '+${HomeFormat.number(mission.coinReward)} monedas',
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: mission == null ? onCreate : onContinue,
              icon: Icon(
                mission == null ? Icons.add_rounded : Icons.play_arrow_rounded,
                size: 20,
              ),
              label: Text(mission == null ? 'Crear misión' : 'Continuar'),
              style: FilledButton.styleFrom(
                backgroundColor: context.lq.deepGreen,
                foregroundColor: context.lq.onDeepGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: context.lq.deepGreen),
      const SizedBox(width: 4),
      Flexible(
        child: Text(
          label,
          style: TextStyle(
            color: context.lq.deepGreen,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}

class _Reward extends StatelessWidget {
  const _Reward(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: context.lq.softGreen,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: context.lq.deepGreen),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              color: context.lq.ink,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}
