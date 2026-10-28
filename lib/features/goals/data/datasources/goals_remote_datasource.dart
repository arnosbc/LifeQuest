import 'dart:async';

import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/features/goals/data/models/goals_board_model.dart';
import 'package:proyecto_movil/features/goals/domain/entities/goals_board.dart';

/// RPCs de Objetivos: `goals_overview` (021), `complete_task`,
/// `complete_project` y `archive_item`. Lanza [ServerException] o
/// [NetworkException].
abstract class GoalsRemoteDataSource {
  Future<GoalsBoardModel> getBoard();

  Future<void> attack(BossAttack attack);

  Future<void> archiveGoal(String goalId);
}

class GoalsRemoteDataSourceImpl implements GoalsRemoteDataSource {
  const GoalsRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<GoalsBoardModel> getBoard() => _guard(
    () async => GoalsBoardModel.fromJson(
      await _client.rpc<Map<String, dynamic>>('goals_overview'),
    ),
  );

  @override
  Future<void> attack(BossAttack attack) => _guard(
    () => switch (attack.kind) {
      AttackKind.task => _client.rpc<void>(
        'complete_task',
        params: {'p_task_id': attack.id},
      ),
      AttackKind.project => _client.rpc<void>(
        'complete_project',
        params: {'p_project_id': attack.id},
      ),
    },
  );

  @override
  Future<void> archiveGoal(String goalId) => _guard(
    () => _client.rpc<void>(
      'archive_item',
      params: {'p_kind': 'goal', 'p_id': goalId},
    ),
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
