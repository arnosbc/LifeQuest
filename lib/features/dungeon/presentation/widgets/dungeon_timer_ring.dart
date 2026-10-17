import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';

class DungeonTimerRing extends StatelessWidget {
  const DungeonTimerRing({
    super.key,
    required this.remainingSeconds,
    required this.totalSeconds,
  });

  final int remainingSeconds;
  final int totalSeconds;

  @override
  Widget build(BuildContext context) {
    final minutes = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (remainingSeconds % 60).toString().padLeft(2, '0');
    return Center(
      child: SizedBox(
        width: 184,
        height: 184,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: remainingSeconds / totalSeconds,
                strokeWidth: 5,
                backgroundColor: LifeQuestColors.line,
                color: LifeQuestColors.deepGreen,
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'TIEMPO RESTANTE',
                  style: TextStyle(color: LifeQuestColors.muted, fontSize: 9),
                ),
                Text(
                  '$minutes:$seconds',
                  style: const TextStyle(
                    color: LifeQuestColors.ink,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: LifeQuestColors.softGreen,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'MAZMORRA ACTIVA',
                    style: TextStyle(
                      color: LifeQuestColors.deepGreen,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Sesión total: 1 h 45 m restante',
                  style: TextStyle(color: LifeQuestColors.muted, fontSize: 8),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
