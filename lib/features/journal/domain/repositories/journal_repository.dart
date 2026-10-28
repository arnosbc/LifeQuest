import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/journal/domain/entities/journal_board.dart';

/// Contrato del Diario. La capa data lo implementa.
abstract class JournalRepository {
  /// [now] es la hora local del dispositivo: define qué es "hoy".
  Future<Either<Failure, JournalBoard>> getJournal(DateTime now);
}
