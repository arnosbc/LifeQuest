import 'package:equatable/equatable.dart';

/// Desafíos y Liga estilo Duolingo (052): metas pequeñas del día con cofre,
/// el Desafío del mes y la liga semanal con las personas de tu división (072).
class ChallengesBoard extends Equatable {
  const ChallengesBoard({
    required this.daily,
    required this.month,
    required this.league,
  });

  final List<DailyChallenge> daily;
  final MonthChallenge month;
  final League league;

  @override
  List<Object?> get props => [daily, month, league];
}

/// [key]: `xp`, `tasks` o `focus`; es lo que se envía al cobrar.
class DailyChallenge extends Equatable {
  const DailyChallenge({
    required this.key,
    required this.progress,
    required this.target,
    required this.coins,
    required this.claimed,
  });

  final String key;
  final int progress;
  final int target;
  final int coins;
  final bool claimed;

  bool get ready => !claimed && progress >= target;

  @override
  List<Object?> get props => [key, progress, target, coins, claimed];
}

class MonthChallenge extends Equatable {
  const MonthChallenge({
    required this.progress,
    required this.target,
    required this.coins,
    required this.claimed,
    required this.daysLeft,
  });

  /// Desafíos del día cobrados este mes.
  final int progress;
  final int target;
  final int coins;
  final bool claimed;
  final int daysLeft;

  bool get ready => !claimed && progress >= target;

  @override
  List<Object?> get props => [progress, target, coins, claimed, daysLeft];
}

enum LeagueResult { promoted, demoted, stayed }

class League extends Equatable {
  const League({
    required this.division,
    required this.daysLeft,
    required this.xp,
    required this.rivals,
    this.lastResult,
    this.lastRank,
    this.prizes = const [],
  });

  /// 0 (la primera) a 9 (la más alta).
  final int division;
  final int daysLeft;

  /// XP del usuario esta semana.
  final int xp;
  final List<Rival> rivals;

  /// Cómo terminó la semana pasada; null si no jugó.
  final LeagueResult? lastResult;

  /// Puesto con que cerró la semana pasada (072); null si no jugó.
  final int? lastRank;

  /// Monedas del 1.º, 2.º y 3.º al cerrar la semana (el 1.º gana también un Pase).
  final List<int> prizes;

  /// Últimos 3 bajan solo con 7 o más personas y fuera de la primera división.
  bool get hasDropZone => division > 0 && standings.length >= 7;

  /// Tabla ordenada por XP con el usuario incluido (`null` = el usuario).
  /// Ante empate, el usuario va primero.
  List<Rival?> get standings {
    final all = <Rival?>[null, ...rivals];
    int xpOf(Rival? r) => r?.xp ?? xp;
    all.sort((a, b) => xpOf(b).compareTo(xpOf(a)));
    return all;
  }

  /// Puesto del usuario (1 = primero).
  int get rank => standings.indexOf(null) + 1;

  @override
  List<Object?> get props => [
    division,
    daysLeft,
    xp,
    rivals,
    lastResult,
    lastRank,
    prizes,
  ];
}

class Rival extends Equatable {
  const Rival({required this.name, required this.xp});

  final String name;
  final int xp;

  @override
  List<Object?> get props => [name, xp];
}
