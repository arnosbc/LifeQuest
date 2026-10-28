import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/brain_dump/domain/entities/brain_dump_board.dart';

/// Contrato del Brain Dump. La capa data lo implementa.
abstract class BrainDumpRepository {
  Future<Either<Failure, BrainDumpBoard>> getBoard();

  Future<Either<Failure, Unit>> capture(String content);

  Future<Either<Failure, Unit>> file(String thoughtId, ThoughtShelf shelf);

  /// Crea la tarea o el proyecto y marca la idea como convertida.
  Future<Either<Failure, Unit>> convert(Conversion conversion);

  Future<Either<Failure, Unit>> delete(String thoughtId);
}
