import 'package:proyecto_movil/features/journal/domain/entities/journal_board.dart';

/// Respuesta JSON de la RPC `journal_overview`
/// (supabase/migrations/020_journal.sql).
class JournalBoardModel {
  const JournalBoardModel(this.json);

  factory JournalBoardModel.fromJson(Map<String, dynamic> json) =>
      JournalBoardModel(json);

  final Map<String, dynamic> json;

  static const _sources = {
    'task': JournalSource.task,
    'npc': JournalSource.npc,
    'project': JournalSource.project,
    'goal': JournalSource.goal,
    'habit': JournalSource.habit,
    'dungeon': JournalSource.dungeon,
    'daily_chest': JournalSource.dailyChest,
    'achievement': JournalSource.achievement,
  };

  JournalBoard toEntity() {
    final s = json['summary'] as Map<String, dynamic>? ?? const {};
    return JournalBoard(
      summary: JournalSummary(
        xp: _int(s['xp']),
        xpPrev: _int(s['xp_prev']),
        missions: _int(s['missions']),
        missionsPrev: _int(s['missions_prev']),
        cycles: _int(s['cycles']),
        cyclesPrev: _int(s['cycles_prev']),
        bestStreak: _int(s['best_streak']),
      ),
      entries: [
        for (final e
            in (json['entries'] as List<dynamic>? ?? const [])
                .cast<Map<String, dynamic>>())
          if (_sources[e['source']] case final source?)
            JournalEntry(
              id: e['id'] as String,
              source: source,
              occurredAt: DateTime.parse(e['occurred_at'] as String).toLocal(),
              completed: e['result'] != 'failed',
              title: e['title'] as String?,
              xp: _int(e['xp']),
              coins: _int(e['coins']),
              hp: _int(e['hp']),
            ),
      ],
    );
  }

  static int _int(Object? value) => (value as num?)?.toInt() ?? 0;
}
