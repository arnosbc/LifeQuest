import 'package:flutter/material.dart';

import '../../../shared/lifequest_widgets.dart';

class DashboardGreeting extends StatelessWidget {
  const DashboardGreeting({
    super.key,
    required this.userName,
    required this.onOpenProfile,
  });

  final String userName;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Martes, 29 de septiembre',
              style: TextStyle(
                color: LifeQuestColors.deepGreen,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Buenos días, $userName',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: LifeQuestColors.ink,
                fontSize: 20,
                height: 1.1,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            const Text(
              'Tu siguiente avance está listo.',
              style: TextStyle(color: LifeQuestColors.muted, fontSize: 10),
            ),
          ],
        ),
      ),
      const SizedBox(width: 7),
      IconButton(
        tooltip: 'Notificaciones',
        onPressed: () =>
            showLifeQuestMessage(context, 'No tienes notificaciones nuevas.'),
        icon: const Icon(Icons.notifications_none_rounded, size: 21),
        style: IconButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: LifeQuestColors.line),
        ),
      ),
      const SizedBox(width: 4),
      InkWell(
        onTap: onOpenProfile,
        child: CircleAvatar(
          radius: 16,
          backgroundColor: LifeQuestColors.green,
          child: Text(
            userName.isEmpty ? 'A' : userName[0].toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    ],
  );
}
