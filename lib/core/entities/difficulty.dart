import 'package:equatable/equatable.dart';

/// Dificultad de la partida (`difficulty_level` en la BD).
enum GameDifficulty { easy, normal, hard }

/// Efecto de una dificultad, leído de `difficulty_levels` (no se escribe a mano).
class DifficultyOption extends Equatable {
  const DifficultyOption({
    required this.level,
    required this.xpMultiplier,
    required this.hpPenaltyMultiplier,
    required this.coinMultiplier,
  });

  final GameDifficulty level;
  final double xpMultiplier;
  final double hpPenaltyMultiplier;
  final double coinMultiplier;

  @override
  List<Object?> get props => [
    level,
    xpMultiplier,
    hpPenaltyMultiplier,
    coinMultiplier,
  ];
}
