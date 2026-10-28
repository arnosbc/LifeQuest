import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/rpgenie/domain/repositories/rpgenie_repository.dart';

/// Completa la Misión actual; el parámetro es el id de la tarea.
class CompleteCurrentMission implements UseCase<Unit, String> {
  const CompleteCurrentMission(this._repository);

  final RpgenieRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(String params) =>
      _repository.completeMission(params);
}
