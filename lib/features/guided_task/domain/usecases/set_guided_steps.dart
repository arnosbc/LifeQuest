import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/guided_task/domain/repositories/guided_task_repository.dart';

/// Divide una tarea en pasos escritos por el usuario (plan B4, sin IA).
class SetGuidedSteps implements UseCase<Unit, SetGuidedStepsParams> {
  const SetGuidedSteps(this._repository);

  final GuidedTaskRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(SetGuidedStepsParams params) =>
      _repository.setSteps(params.taskId, params.steps);
}

class SetGuidedStepsParams extends Equatable {
  const SetGuidedStepsParams({required this.taskId, required this.steps});

  final String taskId;
  final List<String> steps;

  @override
  List<Object?> get props => [taskId, steps];
}
