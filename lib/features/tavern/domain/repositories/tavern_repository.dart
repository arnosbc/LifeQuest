import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/tavern/domain/entities/tavern_board.dart';

/// Contrato de la Taverna. La capa data lo implementa.
abstract class TavernRepository {
  Future<Either<Failure, TavernBoard>> getBoard();

  Future<Either<Failure, Unit>> createNpc(NewNpc npc);

  /// Misión sugerida por RPGenie (Edge Function `npc-mission`); solo texto.
  Future<Either<Failure, NpcMissionSuggestion?>> suggestMission(String npcId);

  /// Crea la misión como tarea real, con su guía si la hay; el servidor
  /// cobra si no es gratis.
  Future<Either<Failure, Unit>> acceptMission({
    required String npcId,
    required String title,
    String? description,
  });

  /// Cumple la misión; el servidor paga XP, Monedas y skill.
  Future<Either<Failure, Unit>> completeMission(String taskId);

  /// Sube el documento y espera a que RPGenie lo resuma (Edge Function
  /// `npc-context`); si no pudo resumirlo, no queda guardado.
  Future<Either<Failure, Unit>> addDocument(NewNpcDocument document);

  /// Quita el documento y su archivo.
  Future<Either<Failure, Unit>> removeDocument(String documentId);

  Future<Either<Failure, Unit>> renameNpc(String npcId, String name);

  Future<Either<Failure, Unit>> deleteNpc(String npcId);
}
