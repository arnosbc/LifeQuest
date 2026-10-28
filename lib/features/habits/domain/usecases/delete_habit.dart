import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/habits/domain/repositories/habits_repository.dart';

/// Borra un hábito y sus registros; el parámetro es su id.
class DeleteHabit implements UseCase<Unit, String> {
  const DeleteHabit(this._repository);

  final HabitsRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(String params) =>
      _repository.deleteHabit(params);
}
