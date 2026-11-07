import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/tasks/domain/entities/new_task.dart';
import 'package:proyecto_movil/features/tasks/domain/repositories/tasks_repository.dart';

/// Edita una tarea abierta.
class UpdateTask implements UseCase<Unit, ({String id, NewTask task})> {
  const UpdateTask(this._repository);

  final TasksRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(({String id, NewTask task}) p) =>
      _repository.updateTask(p.id, p.task);
}
