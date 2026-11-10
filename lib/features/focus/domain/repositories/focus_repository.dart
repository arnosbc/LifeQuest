import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/focus/domain/entities/focus_board.dart';

/// Contrato de Foco. La capa data lo implementa.
abstract class FocusRepository {
  Future<Either<Failure, FocusBoard>> getBoard();

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

  /// Completa una tarea de la mochila o uno de sus pasos.
  Future<Either<Failure, Unit>> completeTask(String taskId);

  /// Añade un paso (subtarea) a una tarea de la sesión.
  Future<Either<Failure, Unit>> addStep({
    required String taskId,
    required String title,
  });

  /// Pone la tarea en la agenda a [at].
  Future<Either<Failure, Unit>> schedule({
    required String taskId,
    required DateTime at,
  });

  /// Cierra la sesión sin perder lo ganado.
  Future<Either<Failure, FocusSummary>> end(String sessionId);

  /// «Dónde lo dejé»; vacío la borra (`set_resume_note`, 045).
  Future<Either<Failure, Unit>> setResumeNote({
    required String taskId,
    required String note,
  });

  /// Una idea que distrae va a la Bandeja sin salir del ciclo.
  Future<Either<Failure, Unit>> captureDistraction(String text);

  /// La IA hace 1–3 preguntas de repaso con las notas del usuario.
  Future<Either<Failure, List<String>>> recallQuestions({
    required String title,
    required List<String> notes,
  });
}
