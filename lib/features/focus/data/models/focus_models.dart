import 'package:proyecto_movil/features/focus/domain/entities/focus_board.dart';

/// Respuesta JSON de la RPC `dungeon_overview`
/// (012_dungeon.sql; pasos, progreso y semana desde 037_focus_progress.sql).
class FocusBoardModel {
  const FocusBoardModel(this.json);

  factory FocusBoardModel.fromJson(Map<String, dynamic> json) =>
      FocusBoardModel(json);

  final Map<String, dynamic> json;

  FocusBoard toEntity() {
    final s = json['session'] as Map<String, dynamic>?;
    final breaks = json['breaks'] as Map<String, dynamic>? ?? const {};
    // progress y week llegan desde 037; sin ella, valores neutros.
    final week = json['week'] as Map<String, dynamic>? ?? const {};
    return FocusBoard(
      session: s == null
          ? null
          : FocusSession(
              id: s['id'] as String,
              totalMinutes: _int(s['total_minutes']),
              cycleMinutes: _int(s['cycle_minutes']),
              cyclesDone: _int(s['cycles_done']),
              xpEarned: _int(s['xp_earned']),
              coinsEarned: _int(s['coins_earned']),
              tasks: [for (final t in _list(s['tasks'])) _task(t)],
            ),
      candidates: [for (final t in _list(json['candidates'])) _task(t)],
      maxTasks: _int(json['max_tasks'], 5),
      cycleXp: _int(json['cycle_xp'], 10),
      shortBreakMinutes: _int(breaks['short_minutes'], 5),
      longBreakMinutes: _int(breaks['long_minutes'], 15),
      longBreakEveryNCycles: _int(breaks['long_every_n_cycles'], 4),
      progress: switch (json['progress']) {
        final Map<String, dynamic> p => FocusProgress(
          level: _int(p['level'], 1),
          currentXp: _int(p['current_xp']),
          xpToNextLevel: _int(p['xp_to_next_level'], 100),
        ),
        _ => null,
      },
      weekMinutes: _int(week['minutes']),
      prevWeekMinutes: _int(week['prev_minutes']),
    );
  }

  static FocusTask _task(Map<String, dynamic> t) => FocusTask(
    id: t['id'] as String,
    title: t['title'] as String,
    done: t['done'] as bool? ?? false,
    cycles: _int(t['cycles']),
    steps: [
      for (final st in _list(t['steps']))
        FocusStep(
          id: st['id'] as String,
          title: st['title'] as String,
          done: st['done'] as bool? ?? false,
        ),
    ],
  );

  static List<Map<String, dynamic>> _list(Object? value) =>
      (value as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();

  static int _int(Object? value, [int fallback = 0]) =>
      (value as num?)?.toInt() ?? fallback;
}

/// Respuesta JSON de la RPC `end_dungeon`.
class FocusSummaryModel {
  const FocusSummaryModel(this.json);

  final Map<String, dynamic> json;

  FocusSummary toEntity() => FocusSummary(
    cycles: (json['cycles'] as num?)?.toInt() ?? 0,
    xp: (json['xp'] as num?)?.toInt() ?? 0,
    coins: (json['coins'] as num?)?.toInt() ?? 0,
    minutes: (json['minutes'] as num?)?.toInt() ?? 0,
  );
}
