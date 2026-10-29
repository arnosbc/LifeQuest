import 'package:proyecto_movil/features/dungeon/domain/entities/dungeon_board.dart';

/// Respuesta JSON de la RPC `dungeon_overview`
/// (supabase/migrations/012_dungeon.sql).
class DungeonBoardModel {
  const DungeonBoardModel(this.json);

  factory DungeonBoardModel.fromJson(Map<String, dynamic> json) =>
      DungeonBoardModel(json);

  final Map<String, dynamic> json;

  DungeonBoard toEntity() {
    final s = json['session'] as Map<String, dynamic>?;
    final breaks = json['breaks'] as Map<String, dynamic>? ?? const {};
    return DungeonBoard(
      session: s == null
          ? null
          : DungeonSession(
              id: s['id'] as String,
              totalMinutes: _int(s['total_minutes']),
              cycleMinutes: _int(s['cycle_minutes']),
              cyclesDone: _int(s['cycles_done']),
              xpEarned: _int(s['xp_earned']),
              coinsEarned: _int(s['coins_earned']),
              missionsDone: _int(s['missions_done']),
              tasks: [for (final t in _list(s['tasks'])) _task(t)],
            ),
      candidates: [for (final t in _list(json['candidates'])) _task(t)],
      maxTasks: _int(json['max_tasks'], 5),
      cycleXp: _int(json['cycle_xp'], 10),
      shortBreakMinutes: _int(breaks['short_minutes'], 5),
      longBreakMinutes: _int(breaks['long_minutes'], 15),
      longBreakEveryNCycles: _int(breaks['long_every_n_cycles'], 4),
    );
  }

  static DungeonTask _task(Map<String, dynamic> t) => DungeonTask(
    id: t['id'] as String,
    title: t['title'] as String,
    done: t['done'] as bool? ?? false,
    cycles: _int(t['cycles']),
  );

  static List<Map<String, dynamic>> _list(Object? value) =>
      (value as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();

  static int _int(Object? value, [int fallback = 0]) =>
      (value as num?)?.toInt() ?? fallback;
}

/// Respuesta JSON de la RPC `end_dungeon`.
class DungeonSummaryModel {
  const DungeonSummaryModel(this.json);

  final Map<String, dynamic> json;

  DungeonSummary toEntity() => DungeonSummary(
    cycles: (json['cycles'] as num?)?.toInt() ?? 0,
    xp: (json['xp'] as num?)?.toInt() ?? 0,
    coins: (json['coins'] as num?)?.toInt() ?? 0,
    minutes: (json['minutes'] as num?)?.toInt() ?? 0,
    missions: (json['missions'] as num?)?.toInt() ?? 0,
  );
}

/// Respuesta JSON de `complete_task` (005): `coins` va a la bolsa y
/// `treasury` es lo que no cupo y pasó al Tesoro.
class DungeonRewardModel {
  const DungeonRewardModel(this.json);

  final Map<String, dynamic> json;

  DungeonReward toEntity() => DungeonReward(
    xp: (json['xp'] as num?)?.toInt() ?? 0,
    coins:
        ((json['coins'] as num?)?.toInt() ?? 0) +
        ((json['treasury'] as num?)?.toInt() ?? 0),
  );
}
