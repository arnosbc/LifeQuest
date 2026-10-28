import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/tavern/domain/repositories/tavern_repository.dart';

/// Cumple la misión abierta de un NPC; el parámetro es el id de la tarea.
class CompleteNpcMission implements UseCase<Unit, String> {
  const CompleteNpcMission(this._repository);

  final TavernRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(String params) =>
      _repository.completeMission(params);
}
