import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/brain_dump/domain/entities/brain_dump_board.dart';
import 'package:proyecto_movil/features/brain_dump/domain/repositories/brain_dump_repository.dart';

/// Convierte una idea en tarea o proyecto según el G.T.D.
class ConvertThought implements UseCase<Unit, Conversion> {
  const ConvertThought(this._repository);

  final BrainDumpRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(Conversion params) =>
      _repository.convert(params);
}
