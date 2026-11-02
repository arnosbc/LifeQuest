import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/guided_task/domain/repositories/guided_task_repository.dart';

/// Marca o desmarca un paso. True si completó la tarea.
class ToggleGuidedStep implements UseCase<bool, String> {
  const ToggleGuidedStep(this._repository);

  final GuidedTaskRepository _repository;

  @override
  Future<Either<Failure, bool>> call(String stepId) =>
      _repository.toggleStep(stepId);
}
