import 'package:proyecto_movil/core/entities/task_guide.dart';
import 'package:proyecto_movil/features/guided_task/domain/entities/guided_task.dart';

/// Respuesta JSON de `task_detail` (supabase/migrations/039_task_steps.sql).
class GuidedTaskModel {
  const GuidedTaskModel(this.json);

  final Map<String, dynamic> json;

  GuidedTask toEntity() {
    final guide = json['guide'] as Map<String, dynamic>?;
    final steps = (json['steps'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    final parsedSteps = [
      for (final s in steps)
        GuidedStep(
          id: s['id'] as String,
          position: _int(s['position']),
          title: s['title'] as String,
          doneAt: _date(s['done_at']),
          paidXp: _int(s['paid_xp']),
        ),
    ];
    return GuidedTask(
      id: json['id'] as String,
      title: json['title'] as String,
      description: _text(json['description']),
      xpReward: _int(json['xp_reward']),
      coinReward: _int(json['coin_reward']),
      createdAt: _date(json['created_at']) ?? DateTime.now(),
      completedAt: _date(json['completed_at']),
      paidXp: _int(json['paid_xp']),
      // Sin la 040 no llega: se asume que no hace falta el Foco.
      inFocus: json['in_focus'] as bool? ?? !json.containsKey('in_focus'),
      steps: parsedSteps,
      guide: guide == null
          ? null
          : TaskGuide(
              objective: _text(guide['objective']),
              steps: [for (final s in parsedSteps) s.title],
              hints: _texts(guide['hints']),
              search: _texts(guide['search']),
            ),
    );
  }

  static int _int(Object? v) => (v as num?)?.toInt() ?? 0;

  static DateTime? _date(Object? v) =>
      v is String ? DateTime.parse(v).toLocal() : null;

  static String? _text(Object? v) =>
      v is String && v.trim().isNotEmpty ? v.trim() : null;

  static List<String> _texts(Object? v) => v is List
      ? [
          for (final x in v)
            if (x is String && x.isNotEmpty) x,
        ]
      : const [];
}
