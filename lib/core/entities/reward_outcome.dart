import 'package:equatable/equatable.dart';

/// Lo que el servidor pagó o quitó por una acción (respuesta de `_award`,
/// migración 037). La app solo lo muestra; nunca lo calcula (CLAUDE.md §8).
class RewardOutcome extends Equatable {
  const RewardOutcome({
    this.xp = 0,
    this.coins = 0,
    this.constancyChange = 0,
    this.level,
    this.levelUp = false,
    this.currentXp,
    this.xpToNextLevel,
    this.areaName,
    this.areaLevel,
    this.areaLevelUp = false,
    this.streak,
    this.bestStreak,
  });

  final int xp;
  final int coins;

  /// Cambio de Constancia (antes HP): negativo con un mal hábito.
  final int constancyChange;
  final int? level;
  final bool levelUp;
  final int? currentXp;
  final int? xpToNextLevel;
  final String? areaName;
  final int? areaLevel;
  final bool areaLevelUp;

  /// Solo al registrar un hábito bueno.
  final int? streak;
  final int? bestStreak;

  /// Hay algo que contar: si no, no se muestra nada.
  bool get isVisible =>
      xp != 0 || coins != 0 || constancyChange != 0 || levelUp || areaLevelUp;

  @override
  List<Object?> get props => [
    xp,
    coins,
    constancyChange,
    level,
    levelUp,
    currentXp,
    xpToNextLevel,
    areaName,
    areaLevel,
    areaLevelUp,
    streak,
    bestStreak,
  ];
}
