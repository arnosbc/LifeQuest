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
  Future<Either<Failure, DayPlan>> call(PlanMode mode) async =>
      (await _repository.getOpenTasks()).map(
        (tasks) => switch (mode) {
          PlanMode.planDay => DayPlanner.planDay(tasks, _clock()),
          PlanMode.replan => DayPlanner.replan(tasks, _clock()),
        },
      );
}
