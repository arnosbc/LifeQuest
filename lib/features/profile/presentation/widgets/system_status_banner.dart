import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';

class SystemStatusBanner extends StatelessWidget {
  const SystemStatusBanner({super.key});

  @override
  Widget build(BuildContext context) => LifeQuestSurface(
    color: context.lq.softGreen,
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
    child: Row(
      children: [
        Icon(Icons.circle, color: context.lq.green, size: 7),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            'Todos los sistemas operativos',
            style: TextStyle(color: context.lq.ink, fontSize: 9),
          ),
        ),
        InkWell(
          onTap: () => showLifeQuestMessage(
            context,
            'Todos los sistemas están operativos.',
          ),
          child: Text(
            'Ver estado',
            style: TextStyle(
              color: context.lq.deepGreen,
              fontSize: 8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}
