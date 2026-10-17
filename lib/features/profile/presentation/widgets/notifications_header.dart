import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';

class NotificationsHeader extends StatelessWidget {
  const NotificationsHeader({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      InkWell(
        onTap: onBack,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 29,
          height: 29,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: LifeQuestColors.line),
            borderRadius: BorderRadius.circular(9),
          ),
          child: const Icon(
            Icons.notifications_none,
            color: LifeQuestColors.green,
            size: 17,
          ),
        ),
      ),
      const SizedBox(width: 8),
      const Expanded(
        child: Text(
          'Notificaciones anti-estrés',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: LifeQuestColors.ink,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      IconButton(
        onPressed: onBack,
        tooltip: 'Volver al perfil',
        visualDensity: VisualDensity.compact,
        icon: const Icon(Icons.close, size: 18, color: LifeQuestColors.muted),
      ),
    ],
  );
}
