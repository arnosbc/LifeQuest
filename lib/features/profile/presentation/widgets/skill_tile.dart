import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';

class SkillTile extends StatelessWidget {
  const SkillTile(this.name, this.level, {super.key});

  final String name;
  final String level;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: LifeQuestColors.line),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '◈ $name',
          style: const TextStyle(
            color: LifeQuestColors.deepGreen,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          level,
          style: const TextStyle(color: LifeQuestColors.muted, fontSize: 8),
        ),
      ],
    ),
  );
}
