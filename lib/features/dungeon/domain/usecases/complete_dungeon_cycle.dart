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
        itemId: params.taskId,
        isHabit: params.isHabit,
      );
}

class CompleteDungeonCycleParams extends Equatable {
  const CompleteDungeonCycleParams({
    required this.sessionId,
    required this.taskId,
    this.isHabit = false,
  });

  final String sessionId;
  /// Tarea del bloque o, con [isHabit], el hábito.
  final String taskId;
  final bool isHabit;

  @override
  List<Object?> get props => [sessionId, taskId, isHabit];
}
