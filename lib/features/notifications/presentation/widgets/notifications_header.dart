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
            color: context.lq.surface,
            border: Border.all(color: context.lq.line),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(
            Icons.notifications_none,
            color: context.lq.green,
            size: 17,
          ),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          'Notificaciones anti-estrés',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: context.lq.ink,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      IconButton(
        onPressed: onBack,
        tooltip: 'Volver al perfil',
        visualDensity: VisualDensity.compact,
        icon: Icon(Icons.close, size: 18, color: context.lq.muted),
      ),
    ],
  );
}
