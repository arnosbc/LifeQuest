import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/home/domain/repositories/home_repository.dart';

/// «Hecho» de un recordatorio desde la agenda de Hoy.
class CompleteReminder implements UseCase<Unit, String> {
  const CompleteReminder(this._repository);

  final HomeRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(String params) =>
      _repository.completeReminder(params);
}
