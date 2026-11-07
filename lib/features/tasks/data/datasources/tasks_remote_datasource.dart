import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/features/tasks/data/models/tasks_board_model.dart';
import 'package:proyecto_movil/features/tasks/domain/entities/new_task.dart';
import 'package:proyecto_movil/core/errors/supabase_guard.dart';

/// RPCs de Tareas en Supabase. Lanza [ServerException] o [NetworkException].
abstract class TasksRemoteDataSource {
  Future<TasksBoardModel> getBoard();

  Future<void> createTask(NewTask task);

  Future<void> completeTask(String taskId);

  Future<void> renameTask(String taskId, String title);

  Future<void> deleteTask(String taskId);

  Future<void> snoozeTask(String taskId, int minutes);

  Future<void> updateTask(String taskId, NewTask task);
}

class TasksRemoteDataSourceImpl implements TasksRemoteDataSource {
  const TasksRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<TasksBoardModel> getBoard() => guardSupabase(() async {
    final json = await _client.rpc<Map<String, dynamic>>('missions_overview');
    return TasksBoardModel.fromJson(json);
  });

  @override
  Future<void> createTask(NewTask task) => guardSupabase(
    () => _client.rpc<void>(
      'create_task',
      params: {
        'p_title': task.title,
        'p_description': task.description,
        'p_priority': task.priority.name,
        'p_due_date': task.dueDate?.toUtc().toIso8601String(),
        'p_skill_id': task.skillId,
        'p_project_id': task.projectId,
        'p_goal_id': task.goalId,
        'p_subtasks': task.subtasks,
        'p_scheduled_at': task.scheduledAt?.toUtc().toIso8601String(),
        'p_estimated_minutes': task.estimatedMinutes,
        'p_reminder_minutes': task.reminderMinutes,
        'p_repeat_rule': task.repeatRule,
      },
    ),
  );

  @override
  Future<void> completeTask(String taskId) => guardSupabase(
    () => _client.rpc<void>('complete_task', params: {'p_task_id': taskId}),
  );

  /// Las funciones SQL lanzan su motivo como mensaje (p. ej. `task_not_open`);
  /// se pasa como [ServerException.code].
  @override
  Future<void> renameTask(String taskId, String title) => guardSupabase(
    () => _client.rpc<void>(
      'rename_task',
      params: {'p_task_id': taskId, 'p_title': title},
    ),
  );

  @override
  Future<void> deleteTask(String taskId) => guardSupabase(
    () => _client.rpc<void>('delete_task', params: {'p_task_id': taskId}),
  );

  @override
  Future<void> snoozeTask(String taskId, int minutes) => guardSupabase(
    () => _client.rpc<void>(
      'snooze_task',
      params: {'p_task_id': taskId, 'p_minutes': minutes},
    ),
  );

  @override
  Future<void> updateTask(String taskId, NewTask task) => guardSupabase(
    () => _client.rpc<void>(
      'update_task',
      params: {
        'p_task_id': taskId,
        'p_title': task.title,
        'p_description': task.description,
        'p_priority': task.priority.name,
        'p_due_date': task.dueDate?.toUtc().toIso8601String(),
        'p_scheduled_at': task.scheduledAt?.toUtc().toIso8601String(),
        'p_estimated_minutes': task.estimatedMinutes,
        'p_reminder_minutes': task.reminderMinutes,
        'p_repeat_rule': task.repeatRule,
      },
    ),
  );
}
