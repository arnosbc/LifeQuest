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
    List<String> habitIds = const [],
  });

  /// Cobra un ciclo terminado; el servidor valida el tiempo y paga. El
  /// bloque es de la tarea [itemId] o, con [isHabit], del hábito.
  Future<Either<Failure, Unit>> completeCycle({
    required String sessionId,
    required String itemId,
    bool isHabit = false,
  });

  /// Marca el paso actual de una tarea; true si con él se completó la tarea.
  Future<Either<Failure, bool>> toggleStep(String stepId);

  /// Cumple hoy un hábito de la sesión.
  Future<Either<Failure, Unit>> completeHabit(String habitId);

  /// Completa una misión de la mochila; devuelve lo que pagó el servidor.
  Future<Either<Failure, DungeonReward>> completeTask(String taskId);

  /// Suma una tarea abierta a la sesión en curso (tope de 5, trigger de 006).
  Future<Either<Failure, Unit>> addTask({
    required String sessionId,
    required String taskId,
  });

  /// Cierra la sesión sin perder lo ganado.
  Future<Either<Failure, DungeonSummary>> end(String sessionId);
}
