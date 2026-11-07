import 'package:proyecto_movil/features/review/domain/entities/weekly_review.dart';

/// Respuesta de la RPC `weekly_review` (034; `inbox` llega con 044).
class WeeklyReviewModel {
  const WeeklyReviewModel(this.json);

  final Map<String, dynamic> json;

  WeeklyReview toEntity() => WeeklyReview(
    weekStart: DateTime.parse(json['week_start'] as String),
    done: _int(json['done']),
    focusMinutes: _int(json['focus_minutes']),
    habitDays: _int(json['habit_days']),
    inbox: _int(json['inbox']),
    pending: [
      for (final t
          in (json['pending'] as List<dynamic>? ?? const [])
              .cast<Map<String, dynamic>>())
        ReviewTask(
          id: t['id'] as String,
          title: t['title'] as String,
          due: t['due_date'] is String
              ? DateTime.parse(t['due_date'] as String).toLocal()
              : null,
          repeats: t['repeat_rule'] != null,
        ),
    ],
  );

  static int _int(Object? v) => (v as num?)?.toInt() ?? 0;
}
