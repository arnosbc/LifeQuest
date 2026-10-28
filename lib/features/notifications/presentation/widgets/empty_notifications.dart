import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';

class EmptyNotifications extends StatelessWidget {
  const EmptyNotifications({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: 42),
    child: Column(
      children: [
        Icon(
          Icons.notifications_off_outlined,
          color: context.lq.green,
          size: 32,
        ),
        SizedBox(height: 9),
        Text(
          'No hay notificaciones en esta categoría.',
          textAlign: TextAlign.center,
          style: TextStyle(color: context.lq.muted, fontSize: 11),
        ),
      ],
    ),
  );
}
