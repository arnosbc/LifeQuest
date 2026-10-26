import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/dungeon/domain/repositories/dungeon_repository.dart';

/// Cobra el ciclo que acaba de terminar.
class CompleteDungeonCycle
    implements UseCase<Unit, CompleteDungeonCycleParams> {
  const CompleteDungeonCycle(this._repository);

  final DungeonRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(CompleteDungeonCycleParams params) =>
      _repository.completeCycle(
        sessionId: params.sessionId,
        taskId: params.taskId,
      );
}

class CompleteDungeonCycleParams extends Equatable {
  const CompleteDungeonCycleParams({
    required this.sessionId,
    required this.taskId,
  });

  final String sessionId;
  final String taskId;

  @override
  List<Object?> get props => [sessionId, taskId];
}
