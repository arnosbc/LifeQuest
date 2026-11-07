import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/focus/domain/repositories/focus_repository.dart';

/// Agenda lo que quedó pendiente de la sesión (p. ej. para mañana).
class ScheduleFocusTask
    implements UseCase<Unit, ({String taskId, DateTime at})> {
  const ScheduleFocusTask(this._repository);

  final FocusRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(({String taskId, DateTime at}) params) =>
      _repository.schedule(taskId: params.taskId, at: params.at);
}
