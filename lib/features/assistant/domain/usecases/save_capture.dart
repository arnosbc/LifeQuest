import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/assistant/domain/entities/task_draft.dart';
import 'package:proyecto_movil/features/assistant/domain/repositories/assistant_repository.dart';

typedef SaveCaptureParams = ({
  TaskDraft draft,
  List<DraftStep> steps,
  bool toInbox,
  CaptureKind kind,
  SmartGoal? smart,
});

/// Crea la tarea, el proyecto o la meta (con sus pasos) o manda el texto a
/// la Bandeja.
class SaveCapture implements UseCase<Unit, SaveCaptureParams> {
  const SaveCapture(this._repository);

  final AssistantRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(SaveCaptureParams p) {
    if (p.toInbox || (p.kind == CaptureKind.task && p.draft.isNote)) {
      return _repository.saveToInbox(p.draft.title);
    }
    return switch (p.kind) {
      CaptureKind.task => _repository.createTask(p.draft, p.steps),
      CaptureKind.project => _repository.createProject(p.draft, p.steps),
      // Sin S.M.A.R.T. no hay meta: la crea solo la IA (o el formulario).
      CaptureKind.goal => _repository.createGoal(p.draft, p.smart!, p.steps),
    };
  }
}
