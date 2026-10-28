import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/missions/domain/repositories/missions_repository.dart';

/// Borra una misión abierta y sus subtareas; el parámetro es su id.
class DeleteMission implements UseCase<Unit, String> {
  const DeleteMission(this._repository);

  final MissionsRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(String params) =>
      _repository.deleteMission(params);
}
