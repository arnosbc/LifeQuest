import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/features/focus/data/models/focus_models.dart';
import 'package:proyecto_movil/core/errors/supabase_guard.dart';

/// RPCs de Foco en Supabase. Lanza [ServerException] o
/// [NetworkException].
abstract class FocusRemoteDataSource {
  Future<FocusBoardModel> getBoard();

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

  Future<void> addStep({required String taskId, required String title});

  Future<void> schedule({required String taskId, required DateTime at});

  Future<FocusSummaryModel> end(String sessionId);

  Future<void> setResumeNote({required String taskId, required String note});

  Future<void> captureDistraction(String text);

  Future<List<String>> recallQuestions({
    required String title,
    required List<String> notes,
  });
}

class FocusRemoteDataSourceImpl implements FocusRemoteDataSource {
  const FocusRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<FocusBoardModel> getBoard() => guardSupabase(
    () async => FocusBoardModel.fromJson(
      await _client.rpc<Map<String, dynamic>>('dungeon_overview'),
    ),
  );

  @override
  Future<String> start({
    required int totalMinutes,
    required int cycleMinutes,
    required List<String> taskIds,
  }) => guardSupabase(
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
  }) => guardSupabase(
    () => _client.rpc<void>(
      'complete_dungeon_cycle',
      params: {'p_session_id': sessionId, 'p_task_id': taskId},
    ),
  );

  @override
  Future<void> completeTask(String taskId) => guardSupabase(
    () => _client.rpc<void>('complete_task', params: {'p_task_id': taskId}),
  );

  /// Insert directo como los pasos del Asistente: RLS y grants de columna
  /// de 003; la recompensa la pone el trigger.
  @override
  Future<void> addStep({required String taskId, required String title}) =>
      guardSupabase(
        () => _client.from('tasks').insert({
          'user_id': _client.auth.currentUser?.id,
          'parent_task_id': taskId,
          'title': title,
        }),
      );

  @override
  Future<void> schedule({required String taskId, required DateTime at}) =>
      guardSupabase(
        () => _client.rpc<void>(
          'schedule_task',
          params: {'p_task_id': taskId, 'p_at': at.toUtc().toIso8601String()},
        ),
      );

  @override
  Future<FocusSummaryModel> end(String sessionId) => guardSupabase(
    () async => FocusSummaryModel(
      await _client.rpc<Map<String, dynamic>>(
        'end_dungeon',
        params: {'p_session_id': sessionId},
      ),
    ),
  );

  @override
  Future<void> setResumeNote({required String taskId, required String note}) =>
      guardSupabase(
        () => _client.rpc<void>(
          'set_resume_note',
          params: {'p_task_id': taskId, 'p_note': note},
        ),
      );

  /// La misma RPC que la Bandeja (023).
  @override
  Future<void> captureDistraction(String text) => guardSupabase(
    () => _client.rpc<void>('capture_thought', params: {'p_content': text}),
  );

  /// Edge Function `assistant`, modo `recall` (045).
  @override
  Future<List<String>> recallQuestions({
    required String title,
    required List<String> notes,
  }) => guardSupabase(() async {
    final res = await _client.functions.invoke(
      'assistant',
      body: {'mode': 'recall', 'title': title, 'notes': notes},
    );
    return [
      for (final q in (res.data as Map<String, dynamic>)['questions'] as List)
        if (q is String && q.trim().isNotEmpty) q.trim(),
    ];
  });
}
