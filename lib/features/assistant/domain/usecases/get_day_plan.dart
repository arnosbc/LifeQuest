import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/assistant/domain/entities/day_planner.dart';
import 'package:proyecto_movil/features/assistant/domain/entities/plan_entities.dart';
import 'package:proyecto_movil/features/assistant/domain/repositories/assistant_repository.dart';

/// Propuesta de agenda: armar el día o replanificar lo atrasado.
class GetDayPlan implements UseCase<DayPlan, PlanMode> {
  GetDayPlan(this._repository, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final AssistantRepository _repository;
  final DateTime Function() _clock;

  @override
  Future<Either<Failure, DayPlan>> call(PlanMode mode) async {
    final now = _clock();
    final today = DateTime(now.year, now.month, now.day);
    // Hoy y mañana: replan puede pasar lo atrasado al día siguiente.
    final (tasks, events) = await (
      _repository.getOpenTasks(),
      _repository.getBusy(today, today.add(const Duration(days: 2))),
    ).wait;
    return tasks.map(
      (tasks) => switch (mode) {
        PlanMode.planDay => DayPlanner.planDay(tasks, now, events: events),
        PlanMode.replan => DayPlanner.replan(tasks, now, events: events),
      },
    );
  }
}
