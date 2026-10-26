import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/dungeon/domain/repositories/dungeon_repository.dart';

/// Entra a la Mazmorra con la mochila elegida.
class StartDungeon implements UseCase<String, StartDungeonParams> {
  const StartDungeon(this._repository);

  final DungeonRepository _repository;

  @override
  Future<Either<Failure, String>> call(StartDungeonParams params) =>
      _repository.start(
        totalMinutes: params.totalMinutes,
        cycleMinutes: params.cycleMinutes,
        taskIds: params.taskIds,
      );
}

class StartDungeonParams extends Equatable {
  const StartDungeonParams({
    required this.totalMinutes,
    required this.cycleMinutes,
    required this.taskIds,
  });

  final int totalMinutes;
  final int cycleMinutes;
  final List<String> taskIds;

  @override
  List<Object?> get props => [totalMinutes, cycleMinutes, taskIds];
}
