import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/profile/domain/entities/character_profile.dart';

/// Misiones cumplidas sobre las cerradas en la bitácora.
class CompletionRateCard extends StatelessWidget {
  const CompletionRateCard({super.key, required this.profile});

  final CharacterProfile profile;

  @override
  Widget build(BuildContext context) {
    final rate = profile.completionRate;
    final closed = profile.questsCompleted + profile.questsFailed;
    return LifeQuestSurface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Tasa de finalización',
                  style: TextStyle(
                    color: LifeQuestColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (rate != null)
                Text(
                  '${(rate * 100).round()} %',
                  style: const TextStyle(
                    color: LifeQuestColors.deepGreen,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            rate == null
                ? 'Tu bitácora está en blanco: tu primera misión la estrena.'
                : '${profile.questsCompleted} de $closed misiones cumplidas',
            style: const TextStyle(color: LifeQuestColors.muted, fontSize: 13),
          ),
          if (rate != null) ...[
            const SizedBox(height: 10),
            Semantics(
              label: 'Tasa de finalización',
              value: '${(rate * 100).round()} %',
              child: LinearProgressIndicator(
                value: rate,
                minHeight: 8,
                color: LifeQuestColors.green,
                backgroundColor: LifeQuestColors.softGreen,
                borderRadius: const BorderRadius.all(Radius.circular(8)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
