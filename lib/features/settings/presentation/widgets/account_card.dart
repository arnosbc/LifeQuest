import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/settings/domain/entities/game_settings.dart';

/// Nombre, nivel y progreso de XP. Sin [overview] (cargando o sin conexión)
/// muestra solo el nombre.
class AccountCard extends StatelessWidget {
  const AccountCard({super.key, required this.userName, this.overview});

  final String userName;
  final SettingsOverview? overview;

  @override
  Widget build(BuildContext context) {
    final lq = context.lq;
    final data = overview;
    return LifeQuestSurface(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: lq.softGreen,
                child: Text(
                  userName.isEmpty ? 'H' : userName[0].toUpperCase(),
                  style: TextStyle(
                    color: lq.deepGreen,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: lq.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (data != null)
                      Text(
                        'Nivel ${data.level}',
                        style: TextStyle(
                          color: lq.deepGreen,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (data != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Progreso de XP',
                    style: TextStyle(color: lq.muted, fontSize: 12),
                  ),
                ),
                Text(
                  '${data.currentXp} / ${data.xpToNextLevel} XP',
                  style: TextStyle(
                    color: lq.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ExcludeSemantics(
              child: LinearProgressIndicator(
                value: data.xpToNextLevel <= 0
                    ? 0
                    : (data.currentXp / data.xpToNextLevel).clamp(0, 1),
                minHeight: 6,
                borderRadius: BorderRadius.circular(4),
                color: lq.deepGreen,
                backgroundColor: lq.line,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
