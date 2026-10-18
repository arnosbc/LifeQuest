import 'package:proyecto_movil/features/home/domain/entities/home_dashboard.dart';

/// Respuesta JSON de la RPC `home_dashboard` (supabase/migrations/001_home.sql).
class HomeDashboardModel {
  const HomeDashboardModel(this.json);

  factory HomeDashboardModel.fromJson(Map<String, dynamic> json) =>
      HomeDashboardModel(json);

  final Map<String, dynamic> json;

  HomeDashboard toEntity() {
    final mission = json['priority_mission'] as Map<String, dynamic>?;
    final habits = (json['habits'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    return HomeDashboard(
      displayName: _text(json['display_name']),
      characterClass: _text(json['character_class']),
      // Sin fila en character_stats: los valores por defecto del esquema.
      level: _int(json['level'], 1),
      currentXp: _int(json['current_xp']),
      xpToNextLevel: _int(json['xp_to_next_level'], 100),
      coins: _int(json['coins']),
      hpCurrent: _int(json['hp_current'], 100),
      hpMax: _int(json['hp_max'], 100),
      isWeakened: json['is_weakened'] as bool? ?? false,
      priorityMission: mission == null
          ? null
          : PriorityMission(
              id: mission['id'] as String,
              title: mission['title'] as String,
              priority: UrgencyLevel.values.byName(mission['priority'] as String),
              xpReward: _int(mission['xp_reward']),
              coinReward: _int(mission['coin_reward']),
              dueDate: mission['due_date'] == null
                  ? null
                  : DateTime.parse(mission['due_date'] as String).toLocal(),
            ),
      habits: [
        for (final habit in habits)
          TodayHabit(
            id: habit['id'] as String,
            name: habit['name'] as String,
            done: habit['done'] as bool,
          ),
      ],
      habitsDone: _int(json['habits_done']),
      habitsTotal: _int(json['habits_total']),
      streakDays: _int(json['streak_days']),
      missionsDone: _int(json['missions_done']),
      missionsTotal: _int(json['missions_total']),
      focusMinutes: _int(json['focus_minutes']),
    );
  }

  static int _int(Object? value, [int fallback = 0]) =>
      (value as num?)?.toInt() ?? fallback;

  static String? _text(Object? value) =>
      value is String && value.trim().isNotEmpty ? value.trim() : null;
}
