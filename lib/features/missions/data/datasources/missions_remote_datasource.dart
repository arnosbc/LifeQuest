import 'dart:async';

import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/features/missions/data/models/missions_board_model.dart';
import 'package:proyecto_movil/features/missions/domain/entities/new_mission.dart';
import 'package:proyecto_movil/core/rewards/reward_feed.dart';

/// RPCs de Misiones en Supabase. Lanza [ServerException] o [NetworkException].
abstract class MissionsRemoteDataSource {
  Future<MissionsBoardModel> getBoard();

  Future<void> createMission(NewMission mission);

  Future<void> completeMission(String missionId);

  Future<void> renameMission(String missionId, String title);

  Future<void> deleteMission(String missionId);
}

class MissionsRemoteDataSourceImpl implements MissionsRemoteDataSource {
  const MissionsRemoteDataSourceImpl(this._client, [this._rewards]);

  final SupabaseClient _client;

  /// Recibe lo que pagó el servidor para el momento de recompensa.
  final RewardFeed? _rewards;

  @override
  Future<MissionsBoardModel> getBoard() => _guard(() async {
    final json = await _client.rpc<Map<String, dynamic>>('missions_overview');
    return MissionsBoardModel.fromJson(json);
  });

  @override
  Future<void> createMission(NewMission mission) => _guard(() async {
    await _client.rpc<void>(
      'create_task',
      params: {
        'p_title': mission.title,
        'p_description': mission.description,
        'p_priority': mission.priority.name,
        'p_due_date': mission.dueDate?.toUtc().toIso8601String(),
        'p_skill_id': mission.skillId,
        'p_project_id': mission.projectId,
        'p_goal_id': mission.goalId,
        'p_subtasks': mission.subtasks,
      },
    );
    _rewards?.announce(
      'Nueva tarea: ${mission.title}',
      'Agregada a tus pendientes. ¡Tú puedes!',
    );
  });

  @override
  Future<void> completeMission(String missionId) => _guard(
    () async => _rewards?.report(
      await _client.rpc<dynamic>(
        'complete_task',
        params: {'p_task_id': missionId},
      ),
    ),
  );

  /// Las funciones SQL lanzan su motivo como mensaje (p. ej. `task_not_open`);
  /// se pasa como [ServerException.code].
  @override
  Future<void> renameMission(String missionId, String title) => _guard(
    () => _client.rpc<void>(
      'rename_task',
      params: {'p_task_id': missionId, 'p_title': title},
    ),
  );

  @override
  Future<void> deleteMission(String missionId) => _guard(
    () => _client.rpc<void>('delete_task', params: {'p_task_id': missionId}),
  );

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
