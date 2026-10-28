import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/tavern/domain/repositories/tavern_repository.dart';

/// Borra un NPC; sus misiones quedan como misiones sueltas.
class DeleteNpc implements UseCase<Unit, String> {
  const DeleteNpc(this._repository);

  final TavernRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(String params) =>
      _repository.deleteNpc(params);
}
