import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/rpgenie/domain/entities/current_mission.dart';

/// Contrato de RPGenie. La capa data lo implementa.
abstract class RpgenieRepository {
  /// La misión que toca ahora, sin las apartadas en [skip].
  Future<Either<Failure, RpgenieBoard>> getCurrentMission(List<String> skip);

  /// Completa la misión; el servidor paga XP, Monedas y skill.
  Future<Either<Failure, Unit>> completeMission(String taskId);
}
