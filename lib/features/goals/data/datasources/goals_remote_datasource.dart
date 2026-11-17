import 'dart:async';

import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/features/goals/data/models/goals_board_model.dart';
import 'package:proyecto_movil/features/goals/domain/entities/goals_board.dart';
import 'package:proyecto_movil/core/rewards/reward_feed.dart';

/// RPCs de Objetivos: `goals_overview` (021), `complete_task`,
/// `complete_project` y `archive_item`. Lanza [ServerException] o
/// [NetworkException].
abstract class GoalsRemoteDataSource {
  Future<GoalsBoardModel> getBoard();

  Future<void> attack(BossAttack attack);

  Future<void> archiveGoal(String goalId);
}

class GoalsRemoteDataSourceImpl implements GoalsRemoteDataSource {
  const GoalsRemoteDataSourceImpl(this._client, [this._rewards]);

  final SupabaseClient _client;

  /// Recibe lo que pagó el servidor para el momento de recompensa.
  final RewardFeed? _rewards;

  @override
  Future<GoalsBoardModel> getBoard() => _guard(
    () async => GoalsBoardModel.fromJson(
      await _client.rpc<Map<String, dynamic>>('goals_overview'),
    ),
  );

  @override
  Future<void> attack(BossAttack attack) => _guard(
    () async => _rewards?.report(await switch (attack.kind) {
      AttackKind.task => _client.rpc<dynamic>(
        'complete_task',
        params: {'p_task_id': attack.id},
      ),
      AttackKind.project => _client.rpc<dynamic>(
        'complete_project',
        params: {'p_project_id': attack.id},
      ),
    }),
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
