import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/habits/domain/entities/new_habit.dart';
import 'package:proyecto_movil/features/habits/domain/repositories/habits_repository.dart';

/// Crea un hábito bueno o malo.
class CreateHabit implements UseCase<Unit, NewHabit> {
  const CreateHabit(this._repository);

  final HabitsRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(NewHabit params) =>
      _repository.createHabit(params);
}
