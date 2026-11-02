import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/guided_task/domain/entities/guided_task.dart';
import 'package:proyecto_movil/features/guided_task/domain/repositories/guided_task_repository.dart';

/// Lee la tarea con su guía y sus pasos.
class GetGuidedTask implements UseCase<GuidedTask, String> {
  const GetGuidedTask(this._repository);

  final GuidedTaskRepository _repository;

  @override
  Future<Either<Failure, GuidedTask>> call(String taskId) =>
      _repository.getTask(taskId);
}
