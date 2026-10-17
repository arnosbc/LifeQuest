import 'package:flutter/material.dart';

import 'lifequest_colors.dart';

class LifeQuestStat extends StatelessWidget {
  const LifeQuestStat({super.key, required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFFF0FAF3),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: LifeQuestColors.ink,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: LifeQuestColors.muted, fontSize: 8),
        ),
      ],
    ),
  );
}
