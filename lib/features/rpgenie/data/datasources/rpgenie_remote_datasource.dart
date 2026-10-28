import 'dart:async';

import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/features/rpgenie/data/models/rpgenie_board_model.dart';

/// RPCs de RPGenie: `current_mission` (022) y `complete_task` (005).
/// Lanza [ServerException] o [NetworkException].
abstract class RpgenieRemoteDataSource {
  Future<RpgenieBoardModel> getCurrentMission(List<String> skip);

  Future<void> completeMission(String taskId);
}

class RpgenieRemoteDataSourceImpl implements RpgenieRemoteDataSource {
  const RpgenieRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<RpgenieBoardModel> getCurrentMission(List<String> skip) => _guard(
    () async => RpgenieBoardModel.fromJson(
      await _client.rpc<Map<String, dynamic>>(
        'current_mission',
        params: {'p_skip': skip},
      ),
    ),
  );

  @override
  Future<void> completeMission(String taskId) => _guard(
    () => _client.rpc<void>('complete_task', params: {'p_task_id': taskId}),
  );

  /// Las funciones SQL lanzan su motivo como mensaje; se pasa como
  /// [ServerException.code].
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
