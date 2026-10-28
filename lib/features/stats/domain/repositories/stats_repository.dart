import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/stats/domain/entities/stats_board.dart';

/// Contrato de Estadísticas. La capa data lo implementa.
abstract class StatsRepository {
  /// [now] es la hora local del dispositivo: define qué es "hoy".
  Future<Either<Failure, StatsBoard>> getStats(DateTime now);
}
