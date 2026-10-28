import 'package:proyecto_movil/features/inventory/domain/entities/inventory_board.dart';

/// Respuesta JSON de la RPC `inventory_overview`
/// (supabase/migrations/026_inventory.sql).
class InventoryBoardModel {
  const InventoryBoardModel(this.json);

  factory InventoryBoardModel.fromJson(Map<String, dynamic> json) =>
      InventoryBoardModel(json);

  final Map<String, dynamic> json;

  InventoryBoard toEntity() => InventoryBoard(
    elixirs: _int(json['elixirs']),
    elixirActive: json['elixir_active'] as bool? ?? false,
    chests: _int(json['chests']),
    passes: _int(json['passes']),
    achievements: [
      for (final a in _list('achievements'))
        Achievement(
          id: a['id'] as String,
          name: a['name'] as String,
          description: a['description'] as String?,
          rewardCoins: _int(a['reward_coins']),
          unlockedAt: _date(a['unlocked_at']),
        ),
    ],
    titles: [
      for (final t in _list('titles'))
        EarnedTitle(
          id: t['id'] as String,
          name: t['name'] as String,
          description: t['description'] as String?,
          earnedAt: _date(t['earned_at']),
        ),
    ],
  );

  List<Map<String, dynamic>> _list(String key) =>
      (json[key] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.parse(value).toLocal() : null;

  static int _int(Object? value) => (value as num?)?.toInt() ?? 0;
}
