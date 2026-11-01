import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/home/domain/entities/home_dashboard.dart';

/// Contrato del Home. La capa data lo implementa.
abstract class HomeRepository {
  /// [now] es la hora local del dispositivo: define qué es "hoy".
  Future<Either<Failure, HomeDashboard>> getDashboard(DateTime now);

  /// Registra el hábito bueno como cumplido hoy; el servidor da la recompensa.
  Future<Either<Failure, Unit>> completeHabit({
    required String habitId,
    required DateTime now,
  });
}
