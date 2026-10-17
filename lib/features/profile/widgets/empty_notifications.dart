import 'package:flutter/material.dart';

import '../../../shared/lifequest_widgets.dart';

class EmptyNotifications extends StatelessWidget {
  const EmptyNotifications({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 42),
    child: Column(
      children: [
        Icon(
          Icons.notifications_off_outlined,
          color: LifeQuestColors.green,
          size: 32,
        ),
        SizedBox(height: 9),
        Text(
          'No hay notificaciones en esta categoría.',
          textAlign: TextAlign.center,
          style: TextStyle(color: LifeQuestColors.muted, fontSize: 11),
        ),
      ],
    ),
  );
}
