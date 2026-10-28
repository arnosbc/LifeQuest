import 'package:proyecto_movil/features/stats/domain/entities/stats_board.dart';

/// Respuesta JSON de la RPC `stats_overview`
/// (supabase/migrations/025_stats.sql).
class StatsBoardModel {
  const StatsBoardModel(this.json);

  factory StatsBoardModel.fromJson(Map<String, dynamic> json) =>
      StatsBoardModel(json);

  final Map<String, dynamic> json;

  StatsBoard toEntity() => StatsBoard(
    xp: _int(json['xp']),
    xpPrev: _int(json['xp_prev']),
    missions: _int(json['missions']),
    missionsPrev: _int(json['missions_prev']),
    focusMinutes: _int(json['focus_minutes']),
    focusMinutesPrev: _int(json['focus_minutes_prev']),
    bestStreak: _int(json['best_streak']),
    recordStreak: _int(json['record_streak']),
    xpByDay: [
      for (final d in _list('xp_by_day'))
        DayXp(DateTime.parse(d['day'] as String), _int(d['xp'])),
    ],
    xpBySkill: [
      for (final s in _list('xp_by_skill'))
        SkillXp(s['name'] as String, _int(s['xp'])),
    ],
    topHabits: [
      for (final h in _list('top_habits'))
        HabitConsistency(
          name: h['name'] as String,
          days: _int(h['days']),
          streak: _int(h['streak']),
        ),
    ],
  );

  List<Map<String, dynamic>> _list(String key) =>
      (json[key] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();

  static int _int(Object? value) => (value as num?)?.toInt() ?? 0;
}
