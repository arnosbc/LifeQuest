import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/resources/resource.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/assistant/domain/entities/task_draft.dart';
import 'package:proyecto_movil/features/assistant/domain/repositories/assistant_repository.dart';

typedef SaveCaptureParams = ({
  TaskDraft draft,
  List<DraftStep> steps,
  bool toInbox,
  CaptureKind kind,
  SmartGoal? smart,
  List<ResourceDraft> attachments,
});

/// Crea la tarea, el proyecto o la meta (con sus pasos y recursos) o manda
/// el texto a la Bandeja. Devuelve un aviso si algún recurso no entró: lo
/// creado ya existe, así que no es un error (repetir lo duplicaría).
class SaveCapture implements UseCase<String?, SaveCaptureParams> {
  const SaveCapture(this._repository, this._resources);

  final AssistantRepository _repository;
  final ResourceRepository _resources;

  @override
  Future<Either<Failure, String?>> call(SaveCaptureParams p) async {
    if (p.toInbox || (p.kind == CaptureKind.task && p.draft.isNote)) {
      return (await _repository.saveToInbox(p.draft.title)).map((_) => null);
    }
    final created = await switch (p.kind) {
      CaptureKind.task => _repository.createTask(p.draft, p.steps),
      CaptureKind.project => _repository.createProject(p.draft, p.steps),
      // Sin S.M.A.R.T. no hay meta: la crea solo la IA (o el formulario).
      CaptureKind.goal => _repository.createGoal(p.draft, p.smart!, p.steps),
    };
    final String id;
    switch (created) {
      case Left(value: final failure):
        return Left(failure);
      case Right(value: final value):
        id = value;
    }
    final target = ResourceTarget(switch (p.kind) {
      CaptureKind.task => ResourceTargetKind.task,
      CaptureKind.project => ResourceTargetKind.project,
      CaptureKind.goal => ResourceTargetKind.goal,
    }, id);
    var failed = 0;
    for (final a in p.attachments) {
      if ((await _resources.attach(target, a)).isLeft()) failed++;
    }
    return Right(
      failed == 0
          ? null
          : 'Se guardó, pero $failed recurso(s) no entraron. '
                'Añádelos desde «Recursos».',
    );
  }
}
