import 'dart:async';

import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/features/dungeon/data/models/dungeon_models.dart';

/// RPCs de la Mazmorra en Supabase. Lanza [ServerException] o
/// [NetworkException].
abstract class DungeonRemoteDataSource {
  Future<DungeonBoardModel> getBoard();

  Future<String> start({
    required int totalMinutes,
    required int cycleMinutes,
    required List<String> taskIds,
  });

  Future<void> completeCycle({
    required String sessionId,
    required String taskId,
  });

  Future<void> completeTask(String taskId);

  Future<DungeonSummaryModel> end(String sessionId);
}

class DungeonRemoteDataSourceImpl implements DungeonRemoteDataSource {
  const DungeonRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<DungeonBoardModel> getBoard() => _guard(
    () async => DungeonBoardModel.fromJson(
      await _client.rpc<Map<String, dynamic>>('dungeon_overview'),
    ),
  );

  @override
  Future<String> start({
    required int totalMinutes,
    required int cycleMinutes,
    required List<String> taskIds,
  }) => _guard(
    () => _client.rpc<String>(
      'start_dungeon',
      params: {
        'p_total_minutes': totalMinutes,
        'p_cycle_minutes': cycleMinutes,
        'p_task_ids': taskIds,
      },
    ),
  );

  @override
  Future<void> completeCycle({
    required String sessionId,
    required String taskId,
  }) => _guard(
    () => _client.rpc<void>(
      'complete_dungeon_cycle',
      params: {'p_session_id': sessionId, 'p_task_id': taskId},
    ),
  );

  @override
  Future<void> completeTask(String taskId) => _guard(
    () => _client.rpc<void>('complete_task', params: {'p_task_id': taskId}),
  );

  @override
  Future<DungeonSummaryModel> end(String sessionId) => _guard(
    () async => DungeonSummaryModel(
      await _client.rpc<Map<String, dynamic>>(
        'end_dungeon',
        params: {'p_session_id': sessionId},
      ),
    ),
  );

  /// Las funciones SQL lanzan su motivo como mensaje (p. ej.
  /// `cycle_not_finished`); se pasa como [ServerException.code].
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
