import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/assistant/domain/entities/interpretation.dart';
import 'package:proyecto_movil/features/assistant/domain/entities/plan_entities.dart';
import 'package:proyecto_movil/features/assistant/domain/entities/task_draft.dart';

/// Contrato del Asistente. La capa data lo implementa.
abstract class AssistantRepository {
  /// Tareas abiertas (sin subtareas) con su agenda.
  Future<Either<Failure, List<PlanTask>>> getOpenTasks();

  /// Pone cada bloque en la agenda (`schedule_task`).
  Future<Either<Failure, Unit>> applyBlocks(List<ProposedBlock> blocks);

  /// Eventos del calendario del teléfono entre [from] y [to] (vacío sin permiso).
  Future<List<Busy>> getBusy(DateTime from, DateTime to);

  Future<Either<Failure, AiStatus>> getAiStatus();

  /// La IA convierte el texto en tarea (Edge Function `assistant`).
  Future<Either<Failure, TaskDraft>> parseWithAi(String text, DateTime now);

  /// La IA propone 2–7 pasos para la tarea.
  Future<Either<Failure, List<String>>> breakdown(String title);

  /// Crea la tarea y sus pasos (subtareas con fecha).
  Future<Either<Failure, Unit>> createTask(
    TaskDraft draft,
    List<DraftStep> steps,
  );

  /// La IA convierte la idea en meta S.M.A.R.T. con 3–7 pasos.
  Future<Either<Failure, ({String title, SmartGoal smart, List<String> steps})>>
  planGoal(String text);

  /// Crea el proyecto y sus pasos como tareas del proyecto.
  Future<Either<Failure, Unit>> createProject(
    TaskDraft draft,
    List<DraftStep> steps,
  );

  /// Crea la meta (vence en `draft.dueDate`) y sus pasos como tareas.
  Future<Either<Failure, Unit>> createGoal(
    TaskDraft draft,
    SmartGoal smart,
    List<DraftStep> steps,
  );

  /// Guarda el texto en la Bandeja.
  Future<Either<Failure, Unit>> saveToInbox(String text);
}
