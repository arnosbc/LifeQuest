import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/goals/domain/entities/goals_board.dart';

/// Contrato de Objetivos. La capa data lo implementa.
abstract class GoalsRepository {
  Future<Either<Failure, GoalsBoard>> getBoard();

  /// Completa la tarea o el proyecto; el servidor paga y resta la vida.
  Future<Either<Failure, Unit>> attack(BossAttack attack);

  /// Archiva la Meta (p. ej. tras "El jefe escapó").
  Future<Either<Failure, Unit>> archiveGoal(String goalId);
}
