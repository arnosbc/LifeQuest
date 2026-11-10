import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/focus/domain/repositories/focus_repository.dart';

/// Saca de la cabeza lo que distrae: va a la Bandeja y se decide después.
class CaptureDistraction implements UseCase<Unit, String> {
  const CaptureDistraction(this._repository);

  final FocusRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(String text) {
    final t = text.trim();
    if (t.isEmpty || t.length > 500) {
      return Future.value(
        const Left(ServerFailure('Escribe la idea en una línea.')),
      );
    }
    return _repository.captureDistraction(t);
  }
}
