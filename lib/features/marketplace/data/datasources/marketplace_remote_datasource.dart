import 'dart:async';

import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/features/marketplace/data/models/market_board_model.dart';

/// RPCs del Marketplace (006 y 018). Lanza [ServerException] o
/// [NetworkException].
abstract class MarketplaceRemoteDataSource {
  Future<MarketBoardModel> getBoard();

  Future<void> purchase(String code);

  Future<void> buyBlackMarket(String code, String? habitId);

  Future<void> useRecoveryPass(String habitId);

  Future<void> upgradeRefuge(String building);

  Future<void> activateElixir();
}

class MarketplaceRemoteDataSourceImpl implements MarketplaceRemoteDataSource {
  const MarketplaceRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<MarketBoardModel> getBoard() => _guard(
    () async => MarketBoardModel.fromJson(
      await _client.rpc<Map<String, dynamic>>('market_overview'),
    ),
  );

  @override
  Future<void> purchase(String code) => _rpc('purchase', {'p_code': code});

  @override
  Future<void> buyBlackMarket(String code, String? habitId) =>
      _rpc('buy_black_market', {'p_code': code, 'p_habit_id': habitId});

  @override
  Future<void> useRecoveryPass(String habitId) =>
      _rpc('use_recovery_pass', {'p_habit_id': habitId});

  @override
  Future<void> upgradeRefuge(String building) =>
      _rpc('upgrade_refuge', {'p_building': building});

  @override
  Future<void> activateElixir() => _rpc('activate_elixir', const {});

  Future<void> _rpc(String name, Map<String, dynamic> params) =>
      _guard(() => _client.rpc<void>(name, params: params));

  /// Las funciones SQL lanzan su motivo como mensaje (p. ej.
  /// `not_enough_coins`); se pasa como [ServerException.code].
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (error) {
      throw ServerException(
        code: error.message,
        message: error.details?.toString(),
        statusCode: error.code,
      );
    } on ClientException catch (error) {
      throw NetworkException(error.message);
    } on TimeoutException catch (error) {
      throw NetworkException(error.message);
    }
  }
}
