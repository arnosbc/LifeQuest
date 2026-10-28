import 'package:equatable/equatable.dart';

/// El Diario es la Bitácora (`quest_log_entries`) con un resumen semanal
/// arriba (CLAUDE.md §13). No guarda datos propios.
class JournalBoard extends Equatable {
  const JournalBoard({
    this.summary = const JournalSummary(),
    this.entries = const [],
  });

  final JournalSummary summary;
  final List<JournalEntry> entries;

  @override
  List<Object?> get props => [summary, entries];
}

/// Últimos 7 días comparados con los 7 anteriores.
class JournalSummary extends Equatable {
  const JournalSummary({
    this.xp = 0,
    this.xpPrev = 0,
    this.missions = 0,
    this.missionsPrev = 0,
    this.cycles = 0,
    this.cyclesPrev = 0,
    this.bestStreak = 0,
  });

  final int xp;
  final int xpPrev;
  final int missions;
  final int missionsPrev;

  /// Ciclos de Mazmorra.
  final int cycles;
  final int cyclesPrev;

  /// Racha actual más larga entre los hábitos buenos.
  final int bestStreak;

  @override
  List<Object?> get props => [
    xp,
    xpPrev,
    missions,
    missionsPrev,
    cycles,
    cyclesPrev,
    bestStreak,
  ];
}

enum JournalSource {
  task,
  npc,
  project,
  goal,
  habit,
  dungeon,
  dailyChest,
  achievement,
}

class JournalEntry extends Equatable {
  const JournalEntry({
    required this.id,
    required this.source,
    required this.occurredAt,
    this.completed = true,
    this.title,
    this.xp = 0,
    this.coins = 0,
    this.hp = 0,
  });

  final String id;
  final JournalSource source;
  final DateTime occurredAt;

  /// False si fue un fallo (plazo vencido, mal hábito).
  final bool completed;

  /// Nombre de lo que la produjo; null si ya no existe.
  final String? title;
  final int xp;
  final int coins;
  final int hp;

  @override
  List<Object?> get props => [
    id,
    source,
    occurredAt,
    completed,
    title,
    xp,
    coins,
    hp,
  ];
}
