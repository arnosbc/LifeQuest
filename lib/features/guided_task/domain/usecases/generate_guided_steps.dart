import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/guided_task/domain/repositories/guided_task_repository.dart';

/// Nevi arma los pasos de una tarea (sin mentores, 2026-11-15).
class GenerateGuidedSteps implements UseCase<Unit, String> {
  const GenerateGuidedSteps(this._repository);

  final GuidedTaskRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(String params) =>
      _repository.generateSteps(params);
}
