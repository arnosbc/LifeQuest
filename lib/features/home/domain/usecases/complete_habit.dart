import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/home/domain/repositories/home_repository.dart';

/// Marca un hábito bueno como cumplido hoy.
class CompleteHabit implements UseCase<Unit, CompleteHabitParams> {
  const CompleteHabit(this._repository);

  final HomeRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(CompleteHabitParams params) =>
      _repository.completeHabit(habitId: params.habitId, now: params.now);
}

class CompleteHabitParams extends Equatable {
  const CompleteHabitParams({required this.habitId, required this.now});

  final String habitId;
  final DateTime now;

  @override
  List<Object?> get props => [habitId, now];
}
