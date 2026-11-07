import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/tasks/domain/entities/new_task.dart';
import 'package:proyecto_movil/features/tasks/domain/repositories/tasks_repository.dart';

/// Crea una tarea con sus subtareas.
class CreateTask implements UseCase<Unit, NewTask> {
  const CreateTask(this._repository);

  final TasksRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(NewTask params) =>
      _repository.createTask(params);
}
