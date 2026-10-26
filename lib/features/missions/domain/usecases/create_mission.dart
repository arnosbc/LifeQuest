import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/missions/domain/entities/new_mission.dart';
import 'package:proyecto_movil/features/missions/domain/repositories/missions_repository.dart';

/// Crea una misión con sus subtareas.
class CreateMission implements UseCase<Unit, NewMission> {
  const CreateMission(this._repository);

  final MissionsRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(NewMission params) =>
      _repository.createMission(params);
}
