import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/habits/domain/entities/habit_plan.dart';
import 'package:proyecto_movil/features/habits/domain/repositories/habits_repository.dart';

/// Plan guardado de un hábito; null si aún no tiene. Parámetro: su id.
class GetHabitPlan implements UseCase<HabitPlan?, String> {
  const GetHabitPlan(this._repository);

  final HabitsRepository _repository;

  @override
  Future<Either<Failure, HabitPlan?>> call(String params) =>
      _repository.getPlan(params);
}

/// Nevi (IA) arma y guarda el plan de un hábito. Parámetro: su id.
class GenerateHabitPlan implements UseCase<HabitPlan, String> {
  const GenerateHabitPlan(this._repository);

  final HabitsRepository _repository;

  @override
  Future<Either<Failure, HabitPlan>> call(String params) =>
      _repository.generatePlan(params);
}
