import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/dungeon/domain/repositories/dungeon_repository.dart';

/// Completa una misión de la mochila sin salir de la sesión.
class CompleteSessionTask implements UseCase<Unit, String> {
  const CompleteSessionTask(this._repository);

  final DungeonRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(String params) =>
      _repository.completeTask(params);
}
