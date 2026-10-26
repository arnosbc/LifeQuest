import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/stage/domain/entities/new_goal.dart';
import 'package:proyecto_movil/features/stage/domain/entities/new_project.dart';
import 'package:proyecto_movil/features/stage/domain/entities/stage_board.dart';

/// Contrato de Stage · P.A.R.A. La capa data lo implementa.
abstract class StageRepository {
  /// [now] es la hora local del dispositivo: define qué es "hoy".
  Future<Either<Failure, StageBoard>> getBoard(DateTime now);

  Future<Either<Failure, Unit>> createProject(NewProject project);

  Future<Either<Failure, Unit>> createGoal(NewGoal goal);

  /// Completa una misión; el servidor da la recompensa y golpea al jefe.
  Future<Either<Failure, Unit>> completeTask(String taskId);

  Future<Either<Failure, Unit>> createResource({
    required String title,
    required String url,
  });

  Future<Either<Failure, Unit>> archive({
    required StageItemKind kind,
    required String id,
  });

  /// Completa el proyecto; el servidor da la recompensa y golpea al jefe.
  Future<Either<Failure, Unit>> completeProject(String projectId);
}
