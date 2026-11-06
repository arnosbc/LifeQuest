import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/home/domain/repositories/home_repository.dart';

/// Pide leer el calendario del teléfono. Negarlo no rompe nada.
class ConnectCalendar implements UseCase<Unit, NoParams> {
  const ConnectCalendar(this._repository);

  final HomeRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) =>
      _repository.connectCalendar();
}
