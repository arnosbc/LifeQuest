import 'dart:async';

import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/features/assistant/data/models/plan_task_model.dart';
import 'package:proyecto_movil/features/assistant/data/models/task_draft_model.dart';
import 'package:proyecto_movil/features/assistant/domain/entities/interpretation.dart';
import 'package:proyecto_movil/features/assistant/domain/entities/plan_entities.dart';
import 'package:proyecto_movil/features/assistant/domain/entities/task_draft.dart';

/// RPCs que usa el Asistente. Lanza [ServerException] o [NetworkException].
abstract class AssistantRemoteDataSource {
  Future<List<PlanTaskModel>> getOpenTasks();

  Future<void> schedule(ProposedBlock block);

  Future<AiStatus> aiStatus();

  Future<TaskDraftModel> parse(String text, DateTime now);

  Future<List<String>> breakdown(String title);

  Future<void> createTask(TaskDraft draft, List<DraftStep> steps);

  Future<void> saveToInbox(String text);
}

class AssistantRemoteDataSourceImpl implements AssistantRemoteDataSource {
  const AssistantRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  /// `missions_overview` (010, agenda en 032) ya trae las tareas abiertas.
  @override
  Future<List<PlanTaskModel>> getOpenTasks() => _guard(() async {
    final json = await _client.rpc<Map<String, dynamic>>('missions_overview');
    return [
      for (final m in json['missions'] as List<dynamic>? ?? const [])
        PlanTaskModel(m as Map<String, dynamic>),
    ];
  });

  @override
  Future<void> schedule(ProposedBlock block) => _guard(
    () => _client.rpc<void>(
      'schedule_task',
      params: {
        'p_task_id': block.taskId,
        'p_at': block.start.toUtc().toIso8601String(),
        'p_minutes': block.minutes,
      },
    ),
  );

  @override
  Future<AiStatus> aiStatus() => _guard(() async {
    final json = await _client.rpc<Map<String, dynamic>>('assistant_status');
    return AiStatus(
      enabled: json['ai_enabled'] as bool? ?? false,
      callsLeft: (json['calls_left'] as num?)?.toInt() ?? 0,
    );
  });

  @override
  Future<TaskDraftModel> parse(String text, DateTime now) => _guard(() async {
    final res = await _client.functions.invoke(
      'assistant',
      body: {
        'mode': 'parse',
        'text': text,
        'now': TaskDraftModel.localIso(now),
      },
    );
    return TaskDraftModel(res.data as Map<String, dynamic>, text.trim());
  });

  @override
  Future<List<String>> breakdown(String title) => _guard(() async {
    final res = await _client.functions.invoke(
      'assistant',
      body: {'mode': 'breakdown', 'title': title},
    );
    return [
      for (final s in (res.data as Map<String, dynamic>)['steps'] as List)
        if (s is String && s.trim().isNotEmpty) s.trim(),
    ];
  });

  /// La tarea con `create_task`; los pasos, como subtareas con fecha (insert
  /// directo: RLS y grants de columna de 003; la recompensa la pone el trigger).
  @override
  Future<void> createTask(TaskDraft draft, List<DraftStep> steps) =>
      _guard(() async {
        final res = await _client.rpc<Map<String, dynamic>>(
          'create_task',
          params: TaskDraftModel.toParams(draft),
        );
        if (steps.isEmpty) return;
        final uid = _client.auth.currentUser?.id;
        await _client.from('tasks').insert([
          for (final s in steps)
            {
              'user_id': uid,
              'parent_task_id': res['id'],
              'title': s.title,
              'due_date': s.due.toUtc().toIso8601String(),
            },
        ]);
      });

  @override
  Future<void> saveToInbox(String text) => _guard(
    () => _client.rpc<void>('capture_thought', params: {'p_content': text}),
  );

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FunctionException catch (error) {
      final details = error.details;
      throw ServerException(
        code: details is Map ? details['error']?.toString() : null,
        statusCode: '${error.status}',
      );
    } on PostgrestException catch (error) {
      throw ServerException(code: error.message, statusCode: error.code);
    } on ClientException catch (error) {
      throw NetworkException(error.message);
    } on TimeoutException catch (error) {
      throw NetworkException(error.message);
    }
  }
}
