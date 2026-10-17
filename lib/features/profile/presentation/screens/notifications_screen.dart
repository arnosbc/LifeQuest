import 'package:flutter/material.dart';

import 'package:proyecto_movil/features/profile/domain/entities/app_notification.dart';
import 'package:proyecto_movil/features/profile/presentation/widgets/empty_notifications.dart';
import 'package:proyecto_movil/features/profile/presentation/widgets/notification_card.dart';
import 'package:proyecto_movil/features/profile/presentation/widgets/notification_filter_chips.dart';
import 'package:proyecto_movil/features/profile/presentation/widgets/notifications_header.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  NotificationKind? _filter;
  final Set<int> _readNotifications = {};

  static const _notifications = [
    AppNotification(
      id: 0,
      kind: NotificationKind.critical,
      title: 'Recordatorio importante',
      description: 'No olvides Beber agua · llevas 3/4 esta semana.',
      time: 'hace 2h',
    ),
    AppNotification(
      id: 1,
      kind: NotificationKind.motivational,
      title: 'Tu racha te está esperando',
      description: 'Vuelve a Leer y mantén tu progreso de hoy.',
      time: 'hace 2h',
    ),
    AppNotification(
      id: 2,
      kind: NotificationKind.informative,
      title: 'Digest informativo',
      description:
          '• 2 hábitos completados hoy\n• 1 recordatorio importante\n• 1 invitación para retomar tu racha',
      time: 'hoy',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Agrupadas por categoría en el orden del enum.
    final visible = [
      for (final kind in NotificationKind.values)
        if (_filter == null || _filter == kind)
          ..._notifications.where((item) => item.kind == kind),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      children: [
        NotificationsHeader(onBack: widget.onBack),
        const SizedBox(height: 11),
        NotificationFilterChips(
          selected: _filter,
          onSelected: (filter) => setState(() => _filter = filter),
        ),
        const SizedBox(height: 13),
        if (visible.isEmpty)
          const EmptyNotifications()
        else
          for (final item in visible)
            NotificationCard(
              item: item,
              isRead: _readNotifications.contains(item.id),
              onTap: () => setState(() => _readNotifications.add(item.id)),
            ),
      ],
    );
  }
}
