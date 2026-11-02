import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/core/rewards/reward_feed.dart';
import 'package:proyecto_movil/features/guided_task/data/models/guided_step_review_model.dart';
import 'package:proyecto_movil/features/guided_task/data/models/guided_task_model.dart';
import 'package:proyecto_movil/features/guided_task/domain/entities/guided_step_evidence.dart';

/// RPCs de la tarea guiada (039). Lanza [ServerException] o [NetworkException].
abstract class GuidedTaskRemoteDataSource {
  Future<GuidedTaskModel> getTask(String taskId);

  /// True si el paso era el último y completó la tarea.
  Future<bool> toggleStep(String stepId);

  Future<void> completeTask(String taskId);

  /// `attach_task_guide` (039) solo con los pasos.
  Future<void> setSteps(String taskId, List<String> steps);

  Future<GuidedStepReviewModel> reviewStep(
    String stepId,
    List<GuidedStepEvidence> evidence,
  );
}

class GuidedTaskRemoteDataSourceImpl implements GuidedTaskRemoteDataSource {
  const GuidedTaskRemoteDataSourceImpl(this._client, [this._rewards]);

  final SupabaseClient _client;

  /// Recibe lo que pagó el servidor para el momento de recompensa.
  final RewardFeed? _rewards;

  @override
  Future<GuidedTaskModel> getTask(String taskId) => _guard(() async {
    final json = await _client.rpc<Map<String, dynamic>?>(
      'task_detail',
      params: {'p_task_id': taskId},
    );
    if (json == null) throw const ServerException(code: 'task_not_found');
    return GuidedTaskModel(json);
  });

  @override
  Future<bool> toggleStep(String stepId) => _guard(() async {
    final result = await _client.rpc<dynamic>(
      'toggle_task_step',
      params: {'p_step_id': stepId},
    );
    _rewards?.report(result);
    return result is Map && result['task_completed'] == true;
  });

  @override
  Future<void> completeTask(String taskId) => _guard(
    () async => _rewards?.report(
      await _client.rpc<dynamic>(
        'complete_task',
        params: {'p_task_id': taskId},
      ),
    ),
  );

  @override
  Future<void> setSteps(String taskId, List<String> steps) => _guard(
    () => _client.rpc<dynamic>(
      'attach_task_guide',
      params: {
        'p_task_id': taskId,
        'p_guide': {'steps': steps},
      },
    ),
  );

  @override
  Future<GuidedStepReviewModel> reviewStep(
    String stepId,
    List<GuidedStepEvidence> evidence,
  ) => _guard(() async {
    final response = await _client.functions.invoke(
      'verify-task-step',
      body: {
        'step_id': stepId,
        'evidence': [
          for (final file in evidence)
            {
              'name': file.name,
              'mime_type': file.mimeType,
              'data': base64Encode(file.bytes),
            },
        ],
      },
    );
    if (response.data is! Map<String, dynamic>) {
      throw const ServerException(code: 'verification_unavailable');
    }
    return GuidedStepReviewModel(response.data as Map<String, dynamic>);
  });

  /// Las funciones SQL lanzan su motivo como mensaje (p. ej. `task_not_open`);
  /// se pasa como [ServerException.code].
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (error) {
      throw ServerException(
        code: error.message,
        message: error.details?.toString(),
        statusCode: error.code,
      );
    } on FunctionException catch (error) {
      throw ServerException(
        code: 'verification_unavailable',
        statusCode: '${error.status}',
      );
    } on ClientException catch (error) {
      throw NetworkException(error.message);
    } on TimeoutException catch (error) {
      throw NetworkException(error.message);
    }
  }
}
