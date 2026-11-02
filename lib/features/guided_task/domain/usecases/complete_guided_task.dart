import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/guided_task/domain/repositories/guided_task_repository.dart';

/// Completa la tarea (con o sin pasos hechos).
class CompleteGuidedTask implements UseCase<Unit, String> {
  const CompleteGuidedTask(this._repository);

  final GuidedTaskRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(String taskId) =>
      _repository.completeTask(taskId);
}
