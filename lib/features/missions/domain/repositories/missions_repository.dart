import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/missions/domain/entities/missions_board.dart';
import 'package:proyecto_movil/features/missions/domain/entities/new_mission.dart';

/// Contrato de Misiones. La capa data lo implementa.
abstract class MissionsRepository {
  Future<Either<Failure, MissionsBoard>> getBoard();

  Future<Either<Failure, Unit>> createMission(NewMission mission);

  /// Completa la misión; el servidor da XP y Monedas.
  Future<Either<Failure, Unit>> completeMission(String missionId);

  Future<Either<Failure, Unit>> renameMission(String missionId, String title);

  Future<Either<Failure, Unit>> deleteMission(String missionId);
}
