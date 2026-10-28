import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/brain_dump/domain/repositories/brain_dump_repository.dart';

/// Captura una idea en la bandeja.
class CaptureThought implements UseCase<Unit, String> {
  const CaptureThought(this._repository);

  final BrainDumpRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(String params) =>
      _repository.capture(params);
}
