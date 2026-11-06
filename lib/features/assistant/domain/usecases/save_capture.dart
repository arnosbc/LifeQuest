import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/assistant/domain/entities/task_draft.dart';
import 'package:proyecto_movil/features/assistant/domain/repositories/assistant_repository.dart';

typedef SaveCaptureParams = ({
  TaskDraft draft,
  List<DraftStep> steps,
  bool toInbox,
});

/// Crea la tarea (con sus pasos) o manda el texto a la Bandeja.
class SaveCapture implements UseCase<Unit, SaveCaptureParams> {
  const SaveCapture(this._repository);

  final AssistantRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(SaveCaptureParams params) =>
      params.toInbox || params.draft.isNote
      ? _repository.saveToInbox(params.draft.title)
      : _repository.createTask(params.draft, params.steps);
}
