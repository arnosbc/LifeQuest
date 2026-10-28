import 'package:equatable/equatable.dart';

/// Inventario del Perfil: pestañas Objetos y Logros (CLAUDE.md §13).
class InventoryBoard extends Equatable {
  const InventoryBoard({
    this.elixirs = 0,
    this.elixirActive = false,
    this.chests = 0,
    this.passes = 0,
    this.achievements = const [],
    this.titles = const [],
  });

  final int elixirs;
  final bool elixirActive;
  final int chests;

  /// Pases de Recuperación sin usar.
  final int passes;
  final List<Achievement> achievements;

  /// Títulos de prestigio ganados (no se compran).
  final List<EarnedTitle> titles;

  @override
  List<Object?> get props => [
    elixirs,
    elixirActive,
    chests,
    passes,
    achievements,
    titles,
  ];
}

class Achievement extends Equatable {
  const Achievement({
    required this.id,
    required this.name,
    this.description,
    this.rewardCoins = 0,
    this.unlockedAt,
  });

  final String id;
  final String name;
  final String? description;
  final int rewardCoins;

  /// Null si aún no se desbloquea.
  final DateTime? unlockedAt;

  @override
  List<Object?> get props => [id, name, description, rewardCoins, unlockedAt];
}

class EarnedTitle extends Equatable {
  const EarnedTitle({
    required this.id,
    required this.name,
    this.description,
    this.earnedAt,
  });

  final String id;
  final String name;
  final String? description;
  final DateTime? earnedAt;

  @override
  List<Object?> get props => [id, name, description, earnedAt];
}
