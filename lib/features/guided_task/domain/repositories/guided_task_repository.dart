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

  /// Completa la tarea; el servidor paga lo que falte.
  Future<Either<Failure, Unit>> completeTask(String taskId);

  /// Analiza evidencias en Gemini sin guardarlas en LifeQuest.
  Future<Either<Failure, GuidedStepReview>> reviewStep(
    String stepId,
    List<GuidedStepEvidence> evidence,
  );
}
