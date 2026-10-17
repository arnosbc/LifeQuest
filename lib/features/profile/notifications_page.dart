import 'package:flutter/material.dart';

import 'models/app_notification.dart';
import 'widgets/empty_notifications.dart';
import 'widgets/notification_card.dart';
import 'widgets/notification_filter_chips.dart';
import 'widgets/notifications_header.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  NotificationKind? _filter;
  final Set<int> _readNotifications = {};

  static const _notifications = [
    AppNotification(
      id: 0,
      kind: NotificationKind.critical,
      icon: Icons.water_drop_outlined,
      title: 'Recordatorio importante',
      description: 'No olvides Beber agua · llevas 3/4 esta semana.',
      time: 'hace 2h',
    ),
    AppNotification(
      id: 1,
      kind: NotificationKind.motivational,
      icon: Icons.local_fire_department_outlined,
      title: 'Tu racha te está esperando',
      description: 'Vuelve a Leer y mantén tu progreso de hoy.',
      time: 'hace 2h',
    ),
    AppNotification(
      id: 2,
      kind: NotificationKind.informative,
      icon: Icons.dashboard_customize_outlined,
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
