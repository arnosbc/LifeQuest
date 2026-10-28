import 'package:proyecto_movil/features/notifications/domain/entities/app_notification.dart';

/// Respuesta JSON de la RPC `notifications_overview`
/// (supabase/migrations/029_notifications.sql).
class NotificationsModel {
  const NotificationsModel(this.json);

  factory NotificationsModel.fromJson(Map<String, dynamic> json) =>
      NotificationsModel(json);

  final Map<String, dynamic> json;

  static const _kinds = {
    'critical': NotificationKind.critical,
    'motivational': NotificationKind.motivational,
    'informational': NotificationKind.informative,
  };

  List<AppNotification> toEntity() => [
    for (final n
        in (json['items'] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>())
      AppNotification(
        id: n['id'] as String,
        kind: _kinds[n['type']] ?? NotificationKind.informative,
        title: n['title'] as String,
        description: n['message'] as String,
        createdAt: DateTime.parse(n['created_at'] as String).toLocal(),
        read: n['read'] as bool? ?? false,
      ),
  ];
}
