import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/habits/domain/repositories/habits_repository.dart';

/// Registra un evento de un hábito malo.
class RegisterBadHabit implements UseCase<Unit, String> {
  const RegisterBadHabit(this._repository);

  final HabitsRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(String params) =>
      _repository.registerBadHabit(params);
}
