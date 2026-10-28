import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/tavern/domain/entities/tavern_board.dart';

/// Contrato de la Taverna. La capa data lo implementa.
abstract class TavernRepository {
  Future<Either<Failure, TavernBoard>> getBoard();

  Future<Either<Failure, Unit>> createNpc(NewNpc npc);

  /// Crea la misión como tarea real; el servidor cobra si no es gratis.
  Future<Either<Failure, Unit>> acceptMission({
    required String npcId,
    required String title,
  });

  /// Cumple la misión; el servidor paga XP, Monedas y skill.
  Future<Either<Failure, Unit>> completeMission(String taskId);

  Future<Either<Failure, Unit>> renameNpc(String npcId, String name);

  Future<Either<Failure, Unit>> deleteNpc(String npcId);
}
