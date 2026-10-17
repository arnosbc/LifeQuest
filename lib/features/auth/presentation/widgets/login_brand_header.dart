import 'package:flutter/material.dart';

import '../../../../shared/lifequest_widgets.dart';

class LoginBrandHeader extends StatelessWidget {
  const LoginBrandHeader({super.key});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFEDF8F0),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: LifeQuestColors.line),
        ),
        child: const Icon(
          Icons.auto_awesome,
          size: 22,
          color: LifeQuestColors.green,
        ),
      ),
      const SizedBox(height: 7),
      const Text(
        'LifeQuest',
        style: TextStyle(
          color: LifeQuestColors.ink,
          fontSize: 19,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 2),
      const Text(
        'AVANZA CON RITMO Y PROGRESO REAL',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Color(0xFF63796B),
          fontSize: 8,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}
