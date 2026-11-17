import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/habits/domain/repositories/habits_repository.dart';

/// Pone o quita la hora de un hábito; a esa hora Nevi avisa si falta (071).
class SetHabitTime implements UseCase<Unit, HabitTimeParams> {
  const SetHabitTime(this._repository);

  final HabitsRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(HabitTimeParams params) =>
      _repository.setHabitTime(params.id, params.time);
}

/// Id del hábito y hora «HH:MM»; null la quita.
class HabitTimeParams extends Equatable {
  const HabitTimeParams(this.id, this.time);

  final String id;
  final String? time;

  @override
  List<Object?> get props => [id, time];
}
