import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/guided_task/domain/repositories/guided_task_repository.dart';

/// Nevi arma los pasos de una tarea o, con una nota de la persona, rehace los
/// pendientes. Devuelve la respuesta de Nevi (puede faltar).
class GenerateGuidedSteps
    implements UseCase<String?, GenerateGuidedStepsParams> {
  const GenerateGuidedSteps(this._repository);

  final GuidedTaskRepository _repository;

  @override
  Future<Either<Failure, String?>> call(GenerateGuidedStepsParams params) =>
      _repository.generateSteps(params.taskId, note: params.note);
}

class GenerateGuidedStepsParams extends Equatable {
  const GenerateGuidedStepsParams({required this.taskId, this.note});

  final String taskId;

  /// Lo que la persona le cuenta a Nevi; null al armar los pasos por primera vez.
  final String? note;

  @override
  List<Object?> get props => [taskId, note];
}
