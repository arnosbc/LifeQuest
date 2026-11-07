import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/tasks/domain/entities/tasks_board.dart';
import 'package:proyecto_movil/features/tasks/domain/entities/new_task.dart';

/// Contrato de Tareas. La capa data lo implementa.
abstract class TasksRepository {
  Future<Either<Failure, TasksBoard>> getBoard();

  Future<Either<Failure, Unit>> createTask(NewTask task);

  /// Completa la tarea; el servidor da XP y Monedas.
  Future<Either<Failure, Unit>> completeTask(String taskId);

  Future<Either<Failure, Unit>> renameTask(String taskId, String title);

  Future<Either<Failure, Unit>> deleteTask(String taskId);

  /// Mueve el bloque de la tarea [minutes] minutos más tarde.
  Future<Either<Failure, Unit>> snoozeTask(String taskId, int minutes);

  /// Cambia título, prioridad, fecha, agenda, aviso y repetición. No toca la
  /// recompensa (RF-112) ni los vínculos.
  Future<Either<Failure, Unit>> updateTask(String taskId, NewTask task);
}
