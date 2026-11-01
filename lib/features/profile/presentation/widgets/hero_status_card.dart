import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/profile/domain/entities/character_profile.dart';

/// Cuántas de tus tareas cerradas cumpliste.
class HeroStatusCard extends StatelessWidget {
  const HeroStatusCard({super.key, required this.profile});

  final CharacterProfile profile;

  @override
  Widget build(BuildContext context) {
    final p = profile;
    final rate = p.completionRate;
    final closed = p.questsCompleted + p.questsFailed;

    return LifeQuestSurface(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _StatusRow(
            icon: Icons.task_alt_rounded,
            label: 'Tasa de finalización',
            value: rate == null ? null : '${(rate * 100).round()} %',
            detail: _detail(
              context,
              rate == null
                  ? 'Aún no cierras tareas: la primera estrena tu historial.'
                  : '${p.questsCompleted} de $closed tareas cumplidas',
            ),
          ),
        ],
      ),
    );
  }

  static Widget _detail(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(top: 2),
    child: Text(text, style: TextStyle(color: context.lq.muted, fontSize: 13)),
  );
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.icon,
    required this.label,
    required this.detail,
    this.value,
  });

  final IconData icon;
  final String label;
  final Widget detail;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final lq = context.lq;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LifeQuestIconTile(icon, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: lq.ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (value != null) ...[
                      const SizedBox(width: 12),
                      Text(
                        value!,
                        style: TextStyle(
                          color: lq.ink,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ],
                ),
                detail,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
