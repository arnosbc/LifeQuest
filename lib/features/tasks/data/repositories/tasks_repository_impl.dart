import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/tasks/data/datasources/tasks_remote_datasource.dart';
import 'package:proyecto_movil/features/tasks/domain/entities/tasks_board.dart';
import 'package:proyecto_movil/features/tasks/domain/entities/new_task.dart';
import 'package:proyecto_movil/features/tasks/domain/repositories/tasks_repository.dart';
import 'package:proyecto_movil/core/errors/supabase_guard.dart';

class TasksRepositoryImpl implements TasksRepository {
  const TasksRepositoryImpl(this._remote);

  final TasksRemoteDataSource _remote;

  @override
  Future<Either<Failure, TasksBoard>> getBoard() =>
      _run(() async => (await _remote.getBoard()).toEntity());

  @override
  Future<Either<Failure, Unit>> createTask(NewTask task) => _run(() async {
    await _remote.createTask(task);
    return unit;
  });

  @override
  Future<Either<Failure, Unit>> completeTask(String taskId) => _run(() async {
    await _remote.completeTask(taskId);
    return unit;
  });

  Future<Either<Failure, T>> _run<T>(Future<T> Function() action) =>
      runGuarded(action, (error) => _messageFor(error.code));

  /// Motivos que lanzan las funciones SQL, en tono de invitación.
  static String _messageFor(String? code) => switch (code) {
    'invalid_title' => 'Dale a tu tarea un nombre de hasta 200 caracteres.',
    'skill_not_found' || 'project_not_found' || 'goal_not_found' =>
      'Ese vínculo ya no está disponible. Elige otro o deja la tarea sin vincular.',
    'task_not_found' => 'No encontramos esa tarea. Desliza para actualizar.',
    'task_not_open' => 'Esa tarea ya estaba cerrada. ¡Una menos!',
    'task_in_use' =>
      'Esa tarea ya tiene sesiones de foco. Complétala en lugar de borrarla.',
    _ => 'Algo salió mal. Inténtalo de nuevo en un momento.',
  };

  @override
  Future<Either<Failure, Unit>> renameTask(String taskId, String title) =>
      _run(() async {
        await _remote.renameTask(taskId, title);
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> deleteTask(String taskId) => _run(() async {
    await _remote.deleteTask(taskId);
    return unit;
  });

  @override
  Future<Either<Failure, Unit>> snoozeTask(String taskId, int minutes) =>
      _run(() async {
        await _remote.snoozeTask(taskId, minutes);
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> updateTask(String taskId, NewTask task) =>
      _run(() async {
        await _remote.updateTask(taskId, task);
        return unit;
      });
}
