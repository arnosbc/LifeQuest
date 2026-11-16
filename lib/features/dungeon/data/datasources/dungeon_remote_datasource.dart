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
    List<String> habitIds = const [],
  });

  /// [itemId] es la tarea o, con [isHabit], el hábito del bloque (068).
  Future<void> completeCycle({
    required String sessionId,
    required String itemId,
    bool isHabit = false,
  });

  /// Marca el paso de una tarea de la sesión; true si con él terminó la tarea.
  Future<bool> toggleStep(String stepId);

  /// Cumple hoy un hábito de la sesión (racha incluida).
  Future<void> completeHabit(String habitId);

  Future<DungeonRewardModel> completeTask(String taskId);

  Future<void> addTask({required String sessionId, required String taskId});

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
    List<String> habitIds = const [],
  }) => _guard(
    () => _client.rpc<String>(
      'start_dungeon',
      params: {
        'p_total_minutes': totalMinutes,
        'p_cycle_minutes': cycleMinutes,
        'p_task_ids': taskIds,
        if (habitIds.isNotEmpty) 'p_habit_ids': habitIds,
      },
    ),
  );

  @override
  Future<void> completeCycle({
    required String sessionId,
    required String itemId,
    bool isHabit = false,
  }) => _guard(
    () => _client.rpc<void>(
      'complete_dungeon_cycle',
      params: {
        'p_session_id': sessionId,
        if (isHabit) 'p_habit_id': itemId else 'p_task_id': itemId,
      },
    ),
  );

  @override
  Future<bool> toggleStep(String stepId) => _guard(() async {
    final result = await _client.rpc<Map<String, dynamic>>(
      'toggle_task_step',
      params: {'p_step_id': stepId},
    );
    // 'done' es el paso; la tarea terminó si viene 'task_completed' (044).
    return result['task_completed'] == true;
  });

  // Día local del teléfono, como en Hábitos.
  @override
  Future<void> completeHabit(String habitId) => _guard(() async {
    final now = DateTime.now();
    final day =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    await _client.rpc<dynamic>(
      'complete_habit',
      params: {'p_habit_id': habitId, 'p_day': day},
    );
  });

  @override
  Future<DungeonRewardModel> completeTask(String taskId) => _guard(
    () async => DungeonRewardModel(
      await _client.rpc<Map<String, dynamic>>(
        'complete_task',
        params: {'p_task_id': taskId},
      ),
    ),
  );

  // El RLS exige que la sesión sea del usuario; el trigger de 006 revisa el
  // tope de tareas y que la tarea también lo sea.
  @override
  Future<void> addTask({required String sessionId, required String taskId}) =>
      _guard(
        () => _client.from('focus_session_tasks').upsert({
          'session_id': sessionId,
          'task_id': taskId,
        }, ignoreDuplicates: true),
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
