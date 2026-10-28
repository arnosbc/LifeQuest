import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/tavern/domain/entities/tavern_board.dart';
import 'package:proyecto_movil/features/tavern/domain/repositories/tavern_repository.dart';

/// Crea un NPC; el servidor aplica el límite (3 + Estandarte).
class CreateNpc implements UseCase<Unit, NewNpc> {
  const CreateNpc(this._repository);

  final TavernRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(NewNpc params) =>
      _repository.createNpc(params);
}
