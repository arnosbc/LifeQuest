import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/dungeon/domain/repositories/dungeon_repository.dart';
import 'package:proyecto_movil/features/dungeon/domain/usecases/complete_dungeon_cycle.dart';

/// Lleva a la sesión abierta la tarea que se tocó en «Empezar en Foco».
/// Mismos parámetros que cobrar un ciclo: sesión y tarea.
class AddSessionTask implements UseCase<Unit, CompleteDungeonCycleParams> {
  const AddSessionTask(this._repository);

  final DungeonRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(CompleteDungeonCycleParams params) =>
      _repository.addTask(sessionId: params.sessionId, taskId: params.taskId);
}
