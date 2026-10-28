import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/missions/domain/repositories/missions_repository.dart';

/// Renombra una misión abierta; la recompensa no cambia (RF-112).
class RenameMission implements UseCase<Unit, RenameParams> {
  const RenameMission(this._repository);

  final MissionsRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(RenameParams params) =>
      _repository.renameMission(params.id, params.name);
}

/// Id y nombre nuevo.
class RenameParams extends Equatable {
  const RenameParams(this.id, this.name);

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}
