import 'package:flutter/material.dart';

import 'package:proyecto_movil/app/config/theme.dart';

class LifeQuestStat extends StatelessWidget {
  const LifeQuestStat({super.key, required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    // Cifra como tipografía, sin recuadro (los indicadores no son tarjetas).
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Column(
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: context.lq.ink,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(color: context.lq.muted, fontSize: 12),
        ),
      ],
    ),
  );
}
