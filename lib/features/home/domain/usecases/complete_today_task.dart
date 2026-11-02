import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/home/domain/repositories/home_repository.dart';

/// Completa una tarea desde el Inicio (Siguiente paso o lista «Hoy»).
class CompleteTodayTask implements UseCase<Unit, String> {
  const CompleteTodayTask(this._repository);

  final HomeRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(String taskId) =>
      _repository.completeTask(taskId);
}
