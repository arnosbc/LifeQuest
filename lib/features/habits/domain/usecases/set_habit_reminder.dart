import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/habits/domain/repositories/habits_repository.dart';

/// Cambia o quita la hora del aviso de un hábito bueno.
class SetHabitReminder
    implements UseCase<Unit, ({String id, int? minuteOfDay})> {
  const SetHabitReminder(this._repository);

  final HabitsRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(({String id, int? minuteOfDay}) p) =>
      _repository.setReminder(p.id, p.minuteOfDay);
}
