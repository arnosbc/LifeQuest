import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/goals/domain/repositories/goals_repository.dart';

/// Archiva una Meta; el parámetro es su id.
class ArchiveGoal implements UseCase<Unit, String> {
  const ArchiveGoal(this._repository);

  final GoalsRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(String params) =>
      _repository.archiveGoal(params);
}
