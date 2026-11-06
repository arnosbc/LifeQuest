import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/home/domain/repositories/home_repository.dart';

/// Pone una tarea en la agenda a una hora (o la quita con `at: null`).
class ScheduleTask implements UseCase<Unit, ({String taskId, DateTime? at})> {
  const ScheduleTask(this._repository);

  final HomeRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(({String taskId, DateTime? at}) params) =>
      _repository.scheduleTask(taskId: params.taskId, at: params.at);
}
