import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/focus/domain/repositories/focus_repository.dart';

/// Cobra el ciclo que acaba de terminar.
class CompleteFocusCycle implements UseCase<Unit, CompleteFocusCycleParams> {
  const CompleteFocusCycle(this._repository);

  final FocusRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(CompleteFocusCycleParams params) =>
      _repository.completeCycle(
        sessionId: params.sessionId,
        taskId: params.taskId,
      );
}

class CompleteFocusCycleParams extends Equatable {
  const CompleteFocusCycleParams({
    required this.sessionId,
    required this.taskId,
  });

  final String sessionId;
  final String taskId;

  @override
  List<Object?> get props => [sessionId, taskId];
}
