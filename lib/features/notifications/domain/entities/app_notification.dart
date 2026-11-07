import 'package:equatable/equatable.dart';

/// Nivel del aviso (CLAUDE.md §7). En pantalla siempre símbolo + texto.
enum NotificationKind {
  critical('CRÍTICA'),
  motivational('MOTIVACIONAL'),
  informative('INFORMATIVA');

  const NotificationKind(this.label);

  final String label;
}

/// De qué trata el aviso, para abrir dónde se resuelve (043).
enum NotificationTopic { habit, project, task, level, other }

class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.description,
    required this.createdAt,
    this.read = false,
    this.topic = NotificationTopic.other,
  });

  final String id;
  final NotificationKind kind;
  final String title;
  final String description;
  final DateTime createdAt;
  final bool read;
  final NotificationTopic topic;

  @override
  List<Object?> get props => [
    id,
    kind,
    title,
    description,
    createdAt,
    read,
    topic,
  ];
}
