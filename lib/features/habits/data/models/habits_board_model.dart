import 'package:proyecto_movil/features/habits/domain/entities/habit.dart';
import 'package:proyecto_movil/features/habits/domain/entities/habits_board.dart';

/// Respuesta JSON de la RPC `habits_overview`
/// (supabase/migrations/011_habits.sql).
class HabitsBoardModel {
  const HabitsBoardModel(this.json);

  factory HabitsBoardModel.fromJson(Map<String, dynamic> json) =>
      HabitsBoardModel(json);

  final Map<String, dynamic> json;

  HabitsBoard toEntity() => HabitsBoard(
    habits: [
      for (final h in _list('habits'))
        Habit(
          id: h['id'] as String,
          name: h['name'] as String,
          type: HabitType.values.byName(h['type'] as String),
          specificDays: [
            for (final d in h['specific_days'] as List<dynamic>? ?? const [])
              (d as num).toInt(),
          ],
          skillName: h['skill_name'] as String?,
          hpPenalty: _int(h['hp_penalty']),
          currentStreak: _int(h['current_streak']),
          bestStreak: _int(h['best_streak']),
          scheduledToday: h['scheduled_today'] as bool? ?? true,
          doneToday: h['done_today'] as bool? ?? false,
          reminderMinuteOfDay: switch ((h['reminder_time'] as String?)?.split(
            ':',
          )) {
            [final hh, final mm, ...] => int.parse(hh) * 60 + int.parse(mm),
            _ => null,
          },
          todayCount: _int(h['today_count']),
          minVersion: h['min_version'] as String?,
          week: (h['week'] as List<dynamic>? ?? const []).cast<bool>(),
        ),
    ],
    weekXp: _int(json['week_xp']),
    weekDone: _int(json['week_done']),
    weekScheduled: _int(json['week_scheduled']),
    badFreeDays: _int(json['bad_free_days'], 7),
    monthDays: [
      for (final d in json['month_days'] as List<dynamic>? ?? const [])
        (d as num).toInt(),
    ],
    skills: [
      for (final s in _list('skills'))
        HabitSkill(id: s['id'] as String, name: s['name'] as String),
    ],
  );

  List<Map<String, dynamic>> _list(String key) =>
      (json[key] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();

  static int _int(Object? value, [int fallback = 0]) =>
      (value as num?)?.toInt() ?? fallback;
}
