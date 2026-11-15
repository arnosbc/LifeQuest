import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/guided_task/domain/entities/guided_task.dart';
import 'package:proyecto_movil/features/guided_task/domain/entities/guided_step_evidence.dart';
import 'package:proyecto_movil/features/guided_task/domain/entities/guided_step_review.dart';

/// Contrato de la tarea guiada. La capa data lo implementa.
abstract class GuidedTaskRepository {
  Future<Either<Failure, GuidedTask>> getTask(String taskId);

  /// Marca o desmarca un paso; el servidor paga su parte. Devuelve true si
  /// era el último y completó la tarea.
  Future<Either<Failure, bool>> toggleStep(String stepId);

  /// Divide la tarea en pasos (1–8). Solo si ningún paso cobró todavía.
  Future<Either<Failure, Unit>> setSteps(String taskId, List<String> steps);

  /// Nevi (IA) arma objetivo, pasos y pistas de la tarea y el servidor los
  /// guarda (`npc-mission` en modo tarea + `adapt_task_guide`). Con [note]
  /// («Hablar con Nevi») rehace solo los pendientes. Devuelve lo que responde.
  Future<Either<Failure, String?>> generateSteps(String taskId, {String? note});

  /// Completa la tarea; el servidor paga lo que falte.
  Future<Either<Failure, Unit>> completeTask(String taskId);

  /// Analiza evidencias en Gemini sin guardarlas en LifeQuest.
  Future<Either<Failure, GuidedStepReview>> reviewStep(
    String stepId,
    List<GuidedStepEvidence> evidence,
  );
}
