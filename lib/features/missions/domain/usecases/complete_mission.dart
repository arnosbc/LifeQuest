import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/missions/domain/repositories/missions_repository.dart';

/// Completa una misión por su id.
class CompleteMission implements UseCase<Unit, String> {
  const CompleteMission(this._repository);

  final MissionsRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(String params) =>
      _repository.completeMission(params);
}
