import 'package:proyecto_movil/features/marketplace/domain/entities/market_board.dart';

/// Respuesta JSON de la RPC `market_overview`
/// (supabase/migrations/018_marketplace.sql).
class MarketBoardModel {
  const MarketBoardModel(this.json);

  factory MarketBoardModel.fromJson(Map<String, dynamic> json) =>
      MarketBoardModel(json);

  final Map<String, dynamic> json;

  MarketBoard toEntity() => MarketBoard(
    coins: _int(json['coins']),
    treasury: _int(json['treasury']),
    hpCurrent: _int(json['hp_current'], 100),
    hpMax: _int(json['hp_max'], 100),
    items: [for (final i in _list('items')) _item(i, i['category'] as String)],
    blackMarket: [
      for (final i in _list('black_market')) _item(i, 'mercado_negro'),
    ],
    elixirsStored: _int(json['elixirs_stored']),
    elixirActive: json['elixir_active'] as bool? ?? false,
    passes: _int(json['passes']),
    brokenStreaks: [
      for (final b in _list('broken_streaks'))
        BrokenStreak(
          habitId: b['habit_id'] as String,
          name: b['name'] as String,
          streak: _int(b['streak']),
          deadline: DateTime.parse(b['deadline'] as String).toLocal(),
        ),
    ],
    refuge: [
      for (final r in _list('refuge'))
        RefugeBuilding(
          building: r['building'] as String,
          level: _int(r['level']),
          maxLevel: _int(r['max_level'], 4),
          price: (r['price'] as num?)?.toInt(),
        ),
    ],
  );

  static MarketItem _item(Map<String, dynamic> i, String category) =>
      MarketItem(
        code: i['code'] as String,
        category: category,
        name: i['name'] as String,
        description: i['description'] as String?,
        cost: _int(i['cost']),
        available: i['available'] as bool? ?? true,
      );

  List<Map<String, dynamic>> _list(String key) =>
      (json[key] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();

  static int _int(Object? value, [int fallback = 0]) =>
      (value as num?)?.toInt() ?? fallback;
}
