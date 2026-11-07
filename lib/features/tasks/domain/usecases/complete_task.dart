import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/tasks/domain/repositories/tasks_repository.dart';

/// Completa una tarea por su id.
class CompleteTask implements UseCase<Unit, String> {
  const CompleteTask(this._repository);

  final TasksRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(String params) =>
      _repository.completeTask(params);
}
