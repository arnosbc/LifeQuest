import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';

class SystemStatusBanner extends StatelessWidget {
  const SystemStatusBanner({super.key});

  @override
  Widget build(BuildContext context) => LifeQuestSurface(
    color: const Color(0xFFEAF8EE),
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
    child: Row(
      children: [
        const Icon(Icons.circle, color: LifeQuestColors.green, size: 7),
        const SizedBox(width: 7),
        const Expanded(
          child: Text(
            'Todos los sistemas operativos',
            style: TextStyle(color: LifeQuestColors.ink, fontSize: 9),
          ),
        ),
        InkWell(
          onTap: () => showLifeQuestMessage(
            context,
            'Todos los sistemas están operativos.',
          ),
          child: const Text(
            'Ver estado',
            style: TextStyle(
              color: LifeQuestColors.deepGreen,
              fontSize: 8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}
