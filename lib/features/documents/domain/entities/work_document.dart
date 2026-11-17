import 'package:equatable/equatable.dart';

/// Documento del Taller (RF-117…RF-122). El contenido es Markdown.
class WorkDocument extends Equatable {
  const WorkDocument({
    required this.id,
    required this.title,
    required this.content,
    required this.updatedAt,
    this.taskId,
    this.template,
    this.deletedAt,
  });

  final String id;
  final String title;
  final String content;

  /// Hora del último cambio; en la sincronización gana la más reciente.
  final DateTime updatedAt;

  /// Tarea a la que pertenece, si la hay.
  final String? taskId;

  /// Plantilla con la que se creó (solo informativo).
  final String? template;

  /// Marca de borrado: se conserva para que el borrado se sincronice.
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  /// Palabras del texto, sin contar la sintaxis de Markdown.
  int get wordCount => _word.allMatches(content).length;

  static final _word = RegExp(
    r"[\p{L}\p{N}]+(?:['’-][\p{L}\p{N}]+)*",
    unicode: true,
  );

  WorkDocument copyWith({
    String? title,
    String? content,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) => WorkDocument(
    id: id,
    title: title ?? this.title,
    content: content ?? this.content,
    updatedAt: updatedAt ?? this.updatedAt,
    taskId: taskId,
    template: template,
    deletedAt: deletedAt ?? this.deletedAt,
  );

  @override
  List<Object?> get props => [
    id,
    title,
    content,
    updatedAt,
    taskId,
    template,
    deletedAt,
  ];
}
