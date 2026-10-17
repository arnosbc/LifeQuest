import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';

class LoginBrandHeader extends StatelessWidget {
  const LoginBrandHeader({super.key});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: context.lq.softGreen,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.lq.line),
        ),
        child: Icon(Icons.auto_awesome, size: 22, color: context.lq.green),
      ),
      const SizedBox(height: 7),
      Text(
        'LifeQuest',
        style: TextStyle(
          color: context.lq.ink,
          fontSize: 19,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        'AVANZA CON RITMO Y PROGRESO REAL',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: context.lq.muted,
          fontSize: 8,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}
