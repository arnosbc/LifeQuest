import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/review/domain/repositories/review_repository.dart';

/// Mueve la fecha de una tarea [days] días (1 = mañana, 7 = otra semana).
class PostponeTask implements UseCase<Unit, ({String taskId, int days})> {
  const PostponeTask(this._repository);

  final ReviewRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(({String taskId, int days}) p) =>
      _repository.postpone(p.taskId, days: p.days);
}
