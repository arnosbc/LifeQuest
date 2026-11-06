import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/missions/domain/repositories/missions_repository.dart';

/// Pospone el bloque de una tarea (botón «Posponer 1 h» del aviso).
class SnoozeMission implements UseCase<Unit, ({String id, int minutes})> {
  const SnoozeMission(this._repository);

  final MissionsRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(({String id, int minutes}) params) =>
      _repository.snoozeMission(params.id, params.minutes);
}
