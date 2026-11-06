import 'package:proyecto_movil/features/assistant/domain/entities/plan_entities.dart';

/// Una misión de `missions_overview` vista por el planificador.
class PlanTaskModel {
  const PlanTaskModel(this.json);

  final Map<String, dynamic> json;

  static const _priority = {'low': 0, 'medium': 1, 'high': 2};

  PlanTask toEntity() => PlanTask(
    id: json['id'] as String,
    title: json['title'] as String,
    priority: _priority[json['priority']] ?? 0,
    due: _date(json['due_date']),
    scheduledAt: _date(json['scheduled_at']),
    minutes: (json['estimated_minutes'] as num?)?.toInt(),
  );

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.parse(value).toLocal() : null;
}
