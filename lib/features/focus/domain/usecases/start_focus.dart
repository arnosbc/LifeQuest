import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/focus/domain/repositories/focus_repository.dart';

/// Entra a Foco con la mochila elegida.
class StartFocus implements UseCase<String, StartFocusParams> {
  const StartFocus(this._repository);

  final FocusRepository _repository;

  @override
  Future<Either<Failure, String>> call(StartFocusParams params) =>
      _repository.start(
        totalMinutes: params.totalMinutes,
        cycleMinutes: params.cycleMinutes,
        taskIds: params.taskIds,
      );
}

class StartFocusParams extends Equatable {
  const StartFocusParams({
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
