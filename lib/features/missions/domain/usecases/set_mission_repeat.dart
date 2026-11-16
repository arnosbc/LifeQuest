import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/missions/domain/entities/mission.dart';
import 'package:proyecto_movil/features/missions/domain/repositories/missions_repository.dart';

/// Elige cada cuánto vuelve una tarea abierta, o la deja de repetir (073).
class SetMissionRepeat implements UseCase<Unit, RepeatParams> {
  const SetMissionRepeat(this._repository);

  final MissionsRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(RepeatParams params) =>
      _repository.setMissionRepeat(params.id, params.repeat);
}

/// Id de la tarea y regla (null = no se repite).
class RepeatParams extends Equatable {
  const RepeatParams(this.id, this.repeat);

  final String id;
  final MissionRepeat? repeat;

  @override
  List<Object?> get props => [id, repeat];
}
