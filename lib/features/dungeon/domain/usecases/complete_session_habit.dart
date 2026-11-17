import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/dungeon/domain/repositories/dungeon_repository.dart';

/// Cumple hoy un hábito que está en la sesión de Foco.
class CompleteSessionHabit implements UseCase<Unit, String> {
  const CompleteSessionHabit(this._repository);

  final DungeonRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(String params) =>
      _repository.completeHabit(params);
}
