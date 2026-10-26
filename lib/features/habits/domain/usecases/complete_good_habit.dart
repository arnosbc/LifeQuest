import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/habits/domain/repositories/habits_repository.dart';

/// Marca un hábito bueno como cumplido hoy.
class CompleteGoodHabit implements UseCase<Unit, CompleteGoodHabitParams> {
  const CompleteGoodHabit(this._repository);

  final HabitsRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(CompleteGoodHabitParams params) =>
      _repository.completeGoodHabit(habitId: params.habitId, now: params.now);
}

class CompleteGoodHabitParams extends Equatable {
  const CompleteGoodHabitParams({required this.habitId, required this.now});

  final String habitId;
  final DateTime now;

  @override
  List<Object?> get props => [habitId, now];
}
