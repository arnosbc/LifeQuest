import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/resources/resource.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/assistant/domain/entities/day_planner.dart';
import 'package:proyecto_movil/features/assistant/domain/entities/step_templates.dart';
import 'package:proyecto_movil/features/assistant/domain/entities/task_draft.dart';
import 'package:proyecto_movil/features/assistant/domain/repositories/assistant_repository.dart';

/// La IA propone los pasos y, si está apagada o falla, las plantillas
/// ([StepTemplates]): siempre hay propuesta. Las fechas las reparten las
/// reglas hasta la fecha límite de la tarea. Con recursos, la IA los lee.
class BreakDownTask implements UseCase<List<DraftStep>, TaskDraft> {
  BreakDownTask(this._repository, this._resources, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final AssistantRepository _repository;
  final ResourceRepository _resources;
  final DateTime Function() _clock;

  @override
  Future<Either<Failure, List<DraftStep>>> call(TaskDraft draft) =>
      withAttachments(draft, const []);

  /// Con lo que el usuario adjuntó al crear (aún sin guardar).
  Future<Either<Failure, List<DraftStep>>> withAttachments(
    TaskDraft draft,
    List<ResourceDraft> attachments,
  ) async {
    // Si la subida falla, se piden los pasos sin el material.
    final ai = attachments.isEmpty
        ? const AiContext()
        : (await _resources.prepareForAi(attachments)).getOrElse(
            (_) => const AiContext(),
          );
    final steps = await _steps(draft.title, ai);
    final dates = DayPlanner.spreadDates(
      steps.length,
      _clock(),
      deadline: draft.dueDate,
    );
    return Right([
      for (var i = 0; i < steps.length; i++) DraftStep(steps[i], dates[i]),
    ]);
  }

  /// Solo los títulos, para los formularios que no ponen fecha a cada paso.
  /// [taskId]: tarea ya guardada cuyos recursos se mandan como contexto.
  Future<Either<Failure, List<String>>> titles(
    String title, {
    String? taskId,
  }) async {
    final ai = taskId == null
        ? const AiContext()
        : (await _resources.list(ResourceTarget.task(taskId))).match(
            (_) => const AiContext(),
            AiContext.of,
          );
    return Right(await _steps(title, ai));
  }

  Future<List<String>> _steps(String title, AiContext ai) async =>
      (await _repository.breakdown(title, ai: ai))
          .toOption()
          .filter((s) => s.isNotEmpty)
          .getOrElse(() => StepTemplates.forTitle(title));
}
