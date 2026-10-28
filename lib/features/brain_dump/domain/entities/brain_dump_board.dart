import 'package:equatable/equatable.dart';

/// Brain Dump: la bandeja de captura y lo que el G.T.D. dejó en Algún día o
/// Referencia (CLAUDE.md §5).
class BrainDumpBoard extends Equatable {
  const BrainDumpBoard({
    this.inbox = const [],
    this.someday = const [],
    this.reference = const [],
    this.convertedToday = 0,
  });

  final List<Thought> inbox;
  final List<Thought> someday;
  final List<Thought> reference;

  /// Ideas convertidas hoy en tareas o proyectos.
  final int convertedToday;

  @override
  List<Object?> get props => [inbox, someday, reference, convertedToday];
}

class Thought extends Equatable {
  const Thought({
    required this.id,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String content;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, content, createdAt];
}

/// Dónde se guarda una idea sin convertirla. `pending` la devuelve a la
/// bandeja.
enum ThoughtShelf { pending, someday, reference }

/// Resultado accionable del G.T.D.: `done` es la regla de los 2 minutos.
enum ThoughtKind { task, done, delegated, project }

enum ThoughtPriority { low, medium, high }

class Conversion extends Equatable {
  const Conversion({
    required this.thoughtId,
    required this.kind,
    required this.title,
    this.priority = ThoughtPriority.low,
    this.dueDate,
    this.delegatedTo,
  });

  final String thoughtId;
  final ThoughtKind kind;
  final String title;
  final ThoughtPriority priority;
  final DateTime? dueDate;

  /// «¿A quién?» de una tarea delegada (RF-011).
  final String? delegatedTo;

  @override
  List<Object?> get props => [
    thoughtId,
    kind,
    title,
    priority,
    dueDate,
    delegatedTo,
  ];
}
