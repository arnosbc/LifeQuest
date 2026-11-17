import 'package:proyecto_movil/features/documents/domain/entities/work_document.dart';

/// El mismo JSON sirve para el archivo del teléfono y para la tabla
/// `documents` de Supabase (046).
abstract final class WorkDocumentModel {
  static WorkDocument fromJson(Map<String, dynamic> json) => WorkDocument(
    id: json['id'] as String,
    title: json['title'] as String? ?? 'Sin título',
    content: json['content'] as String? ?? '',
    updatedAt: DateTime.parse(json['updated_at'] as String).toUtc(),
    taskId: json['task_id'] as String?,
    template: json['template'] as String?,
    deletedAt: switch (json['deleted_at']) {
      final String d => DateTime.parse(d).toUtc(),
      _ => null,
    },
  );

  static Map<String, dynamic> toJson(WorkDocument d) => {
    'id': d.id,
    'title': d.title,
    'content': d.content,
    'updated_at': d.updatedAt.toUtc().toIso8601String(),
    'task_id': d.taskId,
    'template': d.template,
    'deleted_at': d.deletedAt?.toUtc().toIso8601String(),
  };
}
