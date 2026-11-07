import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/focus/domain/repositories/focus_repository.dart';

/// Completa una tarea de la mochila sin salir de la sesión.
class CompleteSessionTask implements UseCase<Unit, String> {
  const CompleteSessionTask(this._repository);

  final FocusRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(String params) =>
      _repository.completeTask(params);
}
