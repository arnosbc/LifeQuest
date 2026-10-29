import 'dart:async';

import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/features/stage/data/models/stage_board_model.dart';
import 'package:proyecto_movil/features/stage/domain/entities/new_goal.dart';
import 'package:proyecto_movil/features/stage/domain/entities/new_project.dart';
import 'package:proyecto_movil/features/stage/domain/entities/new_resource.dart';
import 'package:proyecto_movil/features/stage/domain/entities/stage_board.dart';

/// RPCs de Stage · P.A.R.A. en Supabase. Lanza [ServerException] o
/// [NetworkException].
abstract class StageRemoteDataSource {
  /// [day] en formato `yyyy-MM-dd`, fecha local del dispositivo.
  Future<StageBoardModel> getBoard(String day);

  Future<void> createProject(NewProject project);

  Future<void> createGoal(NewGoal goal);

  Future<void> completeTask(String taskId);

  /// Un documento se sube primero al bucket `resources`; si el servidor lo
  /// rechaza, se borra el archivo (035).
  Future<void> createResource(NewResource resource);

  /// Enlace firmado (temporal) para abrir un archivo de un bucket privado.
  Future<String> signedUrl({required String bucket, required String path});

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

  static const _contentTypes = {
    'pdf': 'application/pdf',
    'docx':
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'pptx':
        'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'md': 'text/markdown',
    'txt': 'text/plain',
    'png': 'image/png',
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
  };

  @override
  Future<void> createResource(NewResource r) => _guard(() async {
    String? path;
    if (r.kind == ResourceKind.document) {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) throw const ServerException(code: 'not_authenticated');
      // Storage no admite tildes ni espacios en la ruta.
      final safe = (r.fileName ?? 'documento').replaceAll(
        RegExp(r'[^A-Za-z0-9._-]'),
        '_',
      );
      path = '$uid/${DateTime.now().millisecondsSinceEpoch}_$safe';
      try {
        await _client.storage
            .from('resources')
            .uploadBinary(
              path,
              r.bytes!,
              fileOptions: FileOptions(contentType: _contentTypes[r.extension]),
            );
      } on StorageException catch (error) {
        throw ServerException(
          code: 'upload_failed',
          statusCode: error.statusCode,
        );
      }
    }
    try {
      await _client.rpc<void>(
        'create_resource',
        params: {
          'p_title': r.title.trim(),
          'p_kind': r.kind.name,
          'p_url': r.url?.trim(),
          'p_content': r.content?.trim(),
          'p_path': path,
          'p_project_id': r.projectId,
          'p_goal_id': r.goalId,
          'p_skill_id': r.skillId,
        },
      );
    } catch (_) {
      // Sin fila que lo use, el archivo sobra.
      if (path != null) {
        await _client.storage
            .from('resources')
            .remove([path])
            .catchError((_) => <FileObject>[]);
      }
      rethrow;
    }
  });

  @override
  Future<String> signedUrl({required String bucket, required String path}) =>
      _guard(() async {
        try {
          // 10 min: lo justo para abrirlo; el bucket sigue siendo privado.
          return await _client.storage.from(bucket).createSignedUrl(path, 600);
        } on StorageException catch (error) {
          throw ServerException(
            code: 'item_not_found',
            statusCode: error.statusCode,
          );
        }
      });

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
