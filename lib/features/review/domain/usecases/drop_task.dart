import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/review/domain/repositories/review_repository.dart';

/// Suelta (borra) una tarea que ya no se hará.
class DropTask implements UseCase<Unit, String> {
  const DropTask(this._repository);

  final ReviewRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(String taskId) => _repository.drop(taskId);
}
