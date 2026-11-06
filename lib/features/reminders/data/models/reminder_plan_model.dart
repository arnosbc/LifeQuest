import 'package:proyecto_movil/features/reminders/domain/entities/reminder_plan.dart';

/// Respuesta JSON de la RPC `sync_reminders`
/// (supabase/migrations/032_scheduling.sql).
class ReminderPlanModel {
  const ReminderPlanModel(this.json);

  final Map<String, dynamic> json;

  ReminderPlan toEntity() => ReminderPlan(
    tasks: [
      for (final t in _list('tasks'))
        TaskReminder(
          id: t['id'] as String,
          title: t['title'] as String,
          startsAt: DateTime.parse(t['scheduled_at'] as String).toLocal(),
          minutesBefore: (t['reminder_minutes'] as num).toInt(),
        ),
    ],
    habits: [
      for (final h in _list('habits'))
        HabitReminder(
          id: h['id'] as String,
          name: h['name'] as String,
          minuteOfDay: _minutes(h['reminder_time'])!,
          days: [
            for (final d in h['days'] as List<dynamic>) (d as num).toInt(),
          ],
        ),
    ],
    silenceStart: _minutes(json['silence_start']),
    silenceEnd: _minutes(json['silence_end']),
  );

  List<Map<String, dynamic>> _list(String key) =>
      (json[key] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();

  /// "07:30:00" → 450.
  static int? _minutes(Object? time) {
    if (time is! String) return null;
    final [h, m, ...] = time.split(':');
    return int.parse(h) * 60 + int.parse(m);
  }
}
