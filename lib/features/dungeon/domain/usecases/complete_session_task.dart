import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/dungeon/domain/entities/dungeon_board.dart';
import 'package:proyecto_movil/features/dungeon/domain/repositories/dungeon_repository.dart';

/// Completa una misión de la mochila sin salir de la sesión y devuelve lo
/// que pagó el servidor.
class CompleteSessionTask implements UseCase<DungeonReward, String> {
  const CompleteSessionTask(this._repository);

  final DungeonRepository _repository;

  @override
  Future<Either<Failure, DungeonReward>> call(String params) =>
      _repository.completeTask(params);
}
