enum NotificationKind {
  critical('CRÍTICA'),
  motivational('MOTIVACIONAL'),
  informative('INFORMATIVA');

  const NotificationKind(this.label);

  final String label;
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.description,
    required this.time,
  });

  final int id;
  final NotificationKind kind;
  final String title;
  final String description;
  final String time;
}
