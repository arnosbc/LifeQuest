import 'package:proyecto_movil/features/assistant/domain/entities/task_draft.dart';

/// Respuesta de `parse` de la Edge Function `assistant` (ya validada allí
/// con sanitize.ts; aquí se vuelve a leer con tipos estrictos).
class TaskDraftModel {
  const TaskDraftModel(this.json, this.fallbackTitle);

  final Map<String, dynamic> json;
  final String fallbackTitle;

  TaskDraft toEntity() {
    final title = json['title'];
    final at = _date(json['scheduled_at']);
    return TaskDraft(
      title: title is String && title.trim().isNotEmpty
          ? title.trim()
          : fallbackTitle,
      isNote: json['kind'] == 'note',
      scheduledAt: at,
      dueDate:
          _date(json['due_date']) ??
          (at == null ? null : DateTime(at.year, at.month, at.day, 23, 59)),
      estimatedMinutes: _int(json['estimated_minutes']),
      reminderMinutes: at == null ? null : _int(json['reminder_minutes']) ?? 10,
      repeatRule: json['repeat_rule'] as String?,
      priority: switch (json['priority']) {
        'high' => 2,
        'medium' => 1,
        _ => 0,
      },
    );
  }

  static int? _int(Object? v) => v is num ? v.toInt() : null;

  static DateTime? _date(Object? v) =>
      v is String ? DateTime.tryParse(v)?.toLocal() : null;

  /// Fila de `create_task` (010 + 032).
  static Map<String, Object?> toParams(TaskDraft d) => {
    'p_title': d.title,
    'p_priority': const ['low', 'medium', 'high'][d.priority.clamp(0, 2)],
    'p_due_date': d.dueDate?.toUtc().toIso8601String(),
    'p_scheduled_at': d.scheduledAt?.toUtc().toIso8601String(),
    'p_estimated_minutes': d.estimatedMinutes,
    'p_reminder_minutes': d.scheduledAt == null ? null : d.reminderMinutes,
    'p_repeat_rule': d.repeatRule,
  };

  /// Hora local con su desfase (`2026-11-05T14:00:00-05:00`) para que la IA
  /// entienda «mañana» en la zona del usuario.
  static String localIso(DateTime t) {
    final o = t.timeZoneOffset;
    String two(int n) => n.abs().toString().padLeft(2, '0');
    final base = t.toIso8601String().split('.').first;
    return '$base${o.isNegative ? '-' : '+'}${two(o.inHours)}:${two(o.inMinutes % 60)}';
  }
}
