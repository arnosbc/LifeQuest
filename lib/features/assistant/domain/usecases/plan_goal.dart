import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/assistant/domain/entities/day_planner.dart';
import 'package:proyecto_movil/features/assistant/domain/entities/task_draft.dart';
import 'package:proyecto_movil/features/assistant/domain/repositories/assistant_repository.dart';

typedef GoalProposal = ({
  TaskDraft draft,
  SmartGoal smart,
  List<DraftStep> steps,
});

/// La IA escribe la meta S.M.A.R.T. y sus pasos; la fecha la ponen las reglas:
/// la que dijo el usuario o, si no dijo, en [defaultDays] días. Los pasos se
/// reparten hasta esa fecha.
class PlanGoal implements UseCase<GoalProposal, TaskDraft> {
  PlanGoal(this._repository, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  static const defaultDays = 90;

  final AssistantRepository _repository;
  final DateTime Function() _clock;

  @override
  Future<Either<Failure, GoalProposal>> call(TaskDraft draft) async {
    final now = _clock();
    final due = draft.dueDate ?? now.add(const Duration(days: defaultDays));
    return (await _repository.planGoal(draft.title)).map((plan) {
      final dates = DayPlanner.spreadDates(
        plan.steps.length,
        now,
        deadline: due,
      );
      return (
        draft: TaskDraft(
          title: plan.title,
          dueDate: due,
          priority: draft.priority,
        ),
        smart: plan.smart,
        steps: [
          for (var i = 0; i < plan.steps.length; i++)
            DraftStep(plan.steps[i], dates[i]),
        ],
      );
    });
  }
}
