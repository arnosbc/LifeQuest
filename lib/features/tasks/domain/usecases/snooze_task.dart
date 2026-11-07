import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/tasks/domain/repositories/tasks_repository.dart';

/// Pospone el bloque de una tarea (botón «Posponer 1 h» del aviso).
class SnoozeTask implements UseCase<Unit, ({String id, int minutes})> {
  const SnoozeTask(this._repository);

  final TasksRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(({String id, int minutes}) params) =>
      _repository.snoozeTask(params.id, params.minutes);
}
