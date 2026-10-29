import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/stage/domain/entities/new_goal.dart';
import 'package:proyecto_movil/features/stage/domain/entities/new_project.dart';
import 'package:proyecto_movil/features/stage/domain/entities/new_resource.dart';
import 'package:proyecto_movil/features/stage/domain/entities/stage_board.dart';

/// Contrato de Stage · P.A.R.A. La capa data lo implementa.
abstract class StageRepository {
  /// [now] es la hora local del dispositivo: define qué es "hoy".
  Future<Either<Failure, StageBoard>> getBoard(DateTime now);

  Future<Either<Failure, Unit>> createProject(NewProject project);

  Future<Either<Failure, Unit>> createGoal(NewGoal goal);

  /// Completa una misión; el servidor da la recompensa y golpea al jefe.
  Future<Either<Failure, Unit>> completeTask(String taskId);

  /// Guarda un enlace, una nota o un documento (que se sube antes a Storage).
  Future<Either<Failure, Unit>> createResource(NewResource resource);

  /// Enlace temporal para abrir un documento del bucket privado.
  Future<Either<Failure, String>> resourceUrl(StageResource resource);

  Future<Either<Failure, Unit>> archive({
    required StageItemKind kind,
    required String id,
  });

  /// Completa el proyecto; el servidor da la recompensa y golpea al jefe.
  Future<Either<Failure, Unit>> completeProject(String projectId);
}
