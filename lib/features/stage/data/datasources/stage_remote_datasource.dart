import 'dart:async';

import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/features/stage/data/models/stage_board_model.dart';
import 'package:proyecto_movil/features/stage/domain/entities/new_goal.dart';
import 'package:proyecto_movil/features/stage/domain/entities/new_project.dart';
import 'package:proyecto_movil/features/stage/domain/entities/stage_board.dart';

/// RPCs de Stage · P.A.R.A. en Supabase. Lanza [ServerException] o
/// [NetworkException].
abstract class StageRemoteDataSource {
  /// [day] en formato `yyyy-MM-dd`, fecha local del dispositivo.
  Future<StageBoardModel> getBoard(String day);

  Future<void> createProject(NewProject project);

  Future<void> createGoal(NewGoal goal);

  Future<void> completeTask(String taskId);

  Future<void> createResource({required String title, required String url});

  Future<void> archive({required StageItemKind kind, required String id});

  Future<void> completeProject(String projectId);
}

class StageRemoteDataSourceImpl implements StageRemoteDataSource {
  const StageRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<StageBoardModel> getBoard(String day) => _guard(
    () async => StageBoardModel.fromJson(
      await _client.rpc<Map<String, dynamic>>(
        'stage_overview',
        params: {'p_day': day},
      ),
    ),
  );

  @override
  Future<void> createProject(NewProject project) => _guard(
    () => _client.rpc<void>(
      'create_project',
      params: {
        'p_title': project.title,
        'p_description': project.description,
        'p_end_date': switch (project.endDate) {
          null => null,
          final d => _date(d),
        },
        'p_skill_id': project.skillId,
        'p_goal_id': project.goalId,
      },
    ),
  );

  @override
  Future<void> createGoal(NewGoal goal) => _guard(
    () => _client.rpc<void>(
      'create_goal',
      params: {
        'p_title': goal.title,
        'p_specific': goal.specific,
        'p_measurable': goal.measurable,
        'p_achievable': goal.achievable,
        'p_relevant': goal.relevant,
        'p_due_date': _date(goal.dueDate),
        'p_timebound': goal.timebound,
        'p_skill_id': goal.skillId,
      },
    ),
  );

  @override
  Future<void> completeTask(String taskId) => _guard(
    () => _client.rpc<void>('complete_task', params: {'p_task_id': taskId}),
  );

  /// Fecha local como `yyyy-MM-dd` (columnas `date`).
  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  @override
  Future<void> createResource({required String title, required String url}) =>
      _guard(
        () => _client.rpc<void>(
          'create_resource',
          params: {'p_title': title, 'p_url': url},
        ),
      );

  @override
  Future<void> archive({required StageItemKind kind, required String id}) =>
      _guard(
        () => _client.rpc<void>(
          'archive_item',
          params: {'p_kind': kind.name, 'p_id': id},
        ),
      );

  @override
  Future<void> completeProject(String projectId) => _guard(
    () => _client.rpc<void>(
      'complete_project',
      params: {'p_project_id': projectId},
    ),
  );

  /// Las funciones SQL lanzan su motivo como mensaje (p. ej. `invalid_url`);
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
    } on ClientException catch (error) {
      throw NetworkException(error.message);
    } on TimeoutException catch (error) {
      throw NetworkException(error.message);
    }
  }
}
