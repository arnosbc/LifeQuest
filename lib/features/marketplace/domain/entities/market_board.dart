import 'package:equatable/equatable.dart';

/// Todo lo que muestra el Marketplace: bolsa, catálogo cerrado (RF-043),
/// consumibles guardados, rachas por salvar y Refugio.
class MarketBoard extends Equatable {
  const MarketBoard({
    this.coins = 0,
    this.treasury = 0,
    this.hpCurrent = 100,
    this.hpMax = 100,
    this.items = const [],
    this.blackMarket = const [],
    this.elixirsStored = 0,
    this.elixirActive = false,
    this.passes = 0,
    this.brokenStreaks = const [],
    this.refuge = const [],
  });

  final int coins;

  /// Monedas que no cupieron en la bolsa; no se gastan.
  final int treasury;
  final int hpCurrent;
  final int hpMax;

  /// Hotel y Mercado.
  final List<MarketItem> items;
  final List<MarketItem> blackMarket;
  final int elixirsStored;
  final bool elixirActive;

  /// Pases de Recuperación sin usar.
  final int passes;
  final List<BrokenStreak> brokenStreaks;
  final List<RefugeBuilding> refuge;

  @override
  List<Object?> get props => [
    coins,
    treasury,
    hpCurrent,
    hpMax,
    items,
    blackMarket,
    elixirsStored,
    elixirActive,
    passes,
    brokenStreaks,
    refuge,
  ];
}

class MarketItem extends Equatable {
  const MarketItem({
    required this.code,
    required this.category,
    required this.name,
    required this.cost,
    this.description,
    this.available = true,
  });

  final String code;

  /// `hotel`, `mercado` o `mercado_negro`.
  final String category;
  final String name;
  final String? description;
  final int cost;

  /// False si ya se alcanzó su límite (diario, activo o mensual).
  final bool available;

  @override
  List<Object?> get props => [
    code,
    category,
    name,
    description,
    cost,
    available,
  ];
}

/// Racha rota que aún se puede salvar (48 h).
class BrokenStreak extends Equatable {
  const BrokenStreak({
    required this.habitId,
    required this.name,
    required this.streak,
    required this.deadline,
  });

  final String habitId;
  final String name;
  final int streak;
  final DateTime deadline;

  @override
  List<Object?> get props => [habitId, name, streak, deadline];
}

class RefugeBuilding extends Equatable {
  const RefugeBuilding({
    required this.building,
    required this.level,
    required this.maxLevel,
    this.price,
  });

  /// `huerto`, `biblioteca` o `estandarte`.
  final String building;
  final int level;
  final int maxLevel;

  /// Precio del siguiente nivel; null si ya está al máximo.
  final int? price;

  @override
  List<Object?> get props => [building, level, maxLevel, price];
}
