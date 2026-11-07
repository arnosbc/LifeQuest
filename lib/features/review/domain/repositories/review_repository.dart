import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/review/domain/entities/weekly_review.dart';

/// Contrato de la Revisión semanal. La capa data lo implementa.
abstract class ReviewRepository {
  /// [now] es la hora local: define qué semana es.
  Future<Either<Failure, WeeklyReview>> getReview(DateTime now);

  /// Pasa la tarea a la semana siguiente.
  Future<Either<Failure, Unit>> postpone(String taskId, {int days = 7});

  /// Soltar: la tarea se borra (decidir no hacerla también es avanzar).
  Future<Either<Failure, Unit>> drop(String taskId);
}
