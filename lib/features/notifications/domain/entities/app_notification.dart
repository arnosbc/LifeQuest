import 'package:equatable/equatable.dart';

/// Nivel del aviso (CLAUDE.md §7). En pantalla siempre símbolo + texto.
enum NotificationKind {
  critical('CRÍTICA'),
  motivational('MOTIVACIONAL'),
  informative('INFORMATIVA');

  const NotificationKind(this.label);

  final String label;
}

class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.description,
    required this.createdAt,
    this.read = false,
  });

  final String id;
  final NotificationKind kind;
  final String title;
  final String description;
  final DateTime createdAt;
  final bool read;

  @override
  List<Object?> get props => [id, kind, title, description, createdAt, read];
}
