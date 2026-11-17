import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/dungeon/domain/repositories/dungeon_repository.dart';

/// Marca el paso actual de una tarea sin salir de Foco; true si con él se
/// completó la tarea.
class ToggleSessionStep implements UseCase<bool, String> {
  const ToggleSessionStep(this._repository);

  final DungeonRepository _repository;

  @override
  Future<Either<Failure, bool>> call(String params) =>
      _repository.toggleStep(params);
}
