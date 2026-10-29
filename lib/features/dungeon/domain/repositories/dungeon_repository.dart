import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/dungeon/domain/entities/dungeon_board.dart';

/// Contrato de la Mazmorra. La capa data lo implementa.
abstract class DungeonRepository {
  Future<Either<Failure, DungeonBoard>> getBoard();

  /// Crea la sesión con su mochila; devuelve el id de la sesión.
  Future<Either<Failure, String>> start({
    required int totalMinutes,
    required int cycleMinutes,
    required List<String> taskIds,
  });

  /// Cobra un ciclo terminado; el servidor valida el tiempo y paga.
  Future<Either<Failure, Unit>> completeCycle({
    required String sessionId,
    required String taskId,
  });

  /// Completa una misión de la mochila; devuelve lo que pagó el servidor.
  Future<Either<Failure, DungeonReward>> completeTask(String taskId);

  /// Cierra la sesión sin perder lo ganado.
  Future<Either<Failure, DungeonSummary>> end(String sessionId);
}
