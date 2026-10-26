import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/stage/domain/repositories/stage_repository.dart';

/// Completa una misión desde su proyecto.
class CompleteStageTask implements UseCase<Unit, String> {
  const CompleteStageTask(this._repository);

  final StageRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(String params) =>
      _repository.completeTask(params);
}
