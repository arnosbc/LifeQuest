import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/tasks/domain/entities/tasks_board.dart';
import 'package:proyecto_movil/features/tasks/domain/repositories/tasks_repository.dart';

/// Lee las tareas abiertas y las opciones para vincular.
class GetTasksBoard implements UseCase<TasksBoard, NoParams> {
  const GetTasksBoard(this._repository);

  final TasksRepository _repository;

  @override
  Future<Either<Failure, TasksBoard>> call(NoParams params) =>
      _repository.getBoard();
}
