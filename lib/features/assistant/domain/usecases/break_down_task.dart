import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/assistant/domain/entities/day_planner.dart';
import 'package:proyecto_movil/features/assistant/domain/entities/step_templates.dart';
import 'package:proyecto_movil/features/assistant/domain/entities/task_draft.dart';
import 'package:proyecto_movil/features/assistant/domain/repositories/assistant_repository.dart';

/// La IA propone los pasos y, si está apagada o falla, las plantillas
/// ([StepTemplates]): siempre hay propuesta. Las fechas las reparten las
/// reglas hasta la fecha límite de la tarea.
class BreakDownTask implements UseCase<List<DraftStep>, TaskDraft> {
  BreakDownTask(this._repository, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final AssistantRepository _repository;
  final DateTime Function() _clock;

  @override
  Future<Either<Failure, List<DraftStep>>> call(TaskDraft draft) async {
    final steps = await _steps(draft.title);
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
  Future<Either<Failure, List<String>>> titles(String title) async =>
      Right(await _steps(title));

  Future<List<String>> _steps(String title) async =>
      (await _repository.breakdown(title))
          .toOption()
          .filter((s) => s.isNotEmpty)
          .getOrElse(() => StepTemplates.forTitle(title));
}
