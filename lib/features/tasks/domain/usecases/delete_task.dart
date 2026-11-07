import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/tasks/domain/repositories/tasks_repository.dart';

/// Borra una tarea abierta y sus subtareas; el parámetro es su id.
class DeleteTask implements UseCase<Unit, String> {
  const DeleteTask(this._repository);

  final TasksRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(String params) =>
      _repository.deleteTask(params);
}
