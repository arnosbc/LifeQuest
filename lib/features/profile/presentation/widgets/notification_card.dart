import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/profile/domain/entities/app_notification.dart';

/// Etiqueta de categoría + tarjeta de la notificación.
class NotificationCard extends StatelessWidget {
  const NotificationCard({
    super.key,
    required this.item,
    required this.isRead,
    required this.onTap,
  });

  final AppNotification item;
  final bool isRead;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDigest = item.kind == NotificationKind.informative;
    final accent = item.kind == NotificationKind.critical
        ? context.lq.green
        : context.lq.line;

    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 5),
            child: Text(
              item.kind.label,
              style: TextStyle(
                color: context.lq.muted,
                fontSize: 8,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(11),
              child: Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: context.lq.surface,
                  border: Border.all(
                    color: isDigest ? context.lq.green : context.lq.line,
                  ),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LifeQuestIconTile(_iconFor(item.kind), size: 27),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: TextStyle(
                              color: context.lq.ink,
                              fontSize: 9,
                              fontWeight: isRead
                                  ? FontWeight.w600
                                  : FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.description,
                            style: TextStyle(
                              color: context.lq.muted,
                              fontSize: 8,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 5),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          item.time,
                          style: TextStyle(
                            color: context.lq.muted,
                            fontSize: 7,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (!isRead && !isDigest)
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// El icono es presentación: se deriva del tipo de notificación.
  static IconData _iconFor(NotificationKind kind) => switch (kind) {
    NotificationKind.critical => Icons.water_drop_outlined,
    NotificationKind.motivational => Icons.local_fire_department_outlined,
    NotificationKind.informative => Icons.dashboard_customize_outlined,
  };
}
