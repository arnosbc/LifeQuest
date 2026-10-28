import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/tavern/domain/repositories/tavern_repository.dart';

/// Renombra un NPC.
class RenameNpc implements UseCase<Unit, RenameParams> {
  const RenameNpc(this._repository);

  final TavernRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(RenameParams params) =>
      _repository.renameNpc(params.id, params.name);
}

/// Id y nombre nuevo.
class RenameParams extends Equatable {
  const RenameParams(this.id, this.name);

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}
