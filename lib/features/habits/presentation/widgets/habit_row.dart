import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';

class HabitRow extends StatelessWidget {
  const HabitRow({
    super.key,
    required this.name,
    required this.icon,
    required this.progress,
    required this.complete,
    required this.onToggle,
  });

  final String name;
  final IconData icon;

  /// Formato "5/7".
  final String progress;
  final bool complete;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final progressDays = int.parse(progress[0]);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: LifeQuestSurface(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        child: Row(
          children: [
            LifeQuestIconTile(icon, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: LifeQuestColors.ink,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Row(
                    children: List.generate(
                      7,
                      (day) => Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(right: 3, top: 4),
                        decoration: BoxDecoration(
                          color: day < progressDays
                              ? LifeQuestColors.green
                              : LifeQuestColors.line,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '$progress\nDIARIO',
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: LifeQuestColors.muted,
                fontSize: 8,
                fontWeight: FontWeight.w700,
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: onToggle,
              icon: Icon(
                complete ? Icons.check_circle : Icons.circle_outlined,
                color: complete ? LifeQuestColors.green : LifeQuestColors.muted,
                size: 19,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
