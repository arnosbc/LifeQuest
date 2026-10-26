import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/stage/data/datasources/stage_remote_datasource.dart';
import 'package:proyecto_movil/features/stage/domain/entities/new_goal.dart';
import 'package:proyecto_movil/features/stage/domain/entities/new_project.dart';
import 'package:proyecto_movil/features/stage/domain/entities/stage_board.dart';
import 'package:proyecto_movil/features/stage/domain/repositories/stage_repository.dart';

class StageRepositoryImpl implements StageRepository {
  const StageRepositoryImpl(this._remote);

  final StageRemoteDataSource _remote;

  @override
  Future<Either<Failure, StageBoard>> getBoard(DateTime now) =>
      _run(() async => (await _remote.getBoard(_day(now))).toEntity());

  @override
  Future<Either<Failure, Unit>> createProject(NewProject project) =>
      _run(() async {
        await _remote.createProject(project);
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> createGoal(NewGoal goal) => _run(() async {
    await _remote.createGoal(goal);
    return unit;
  });

  @override
  Future<Either<Failure, Unit>> completeTask(String taskId) => _run(() async {
    await _remote.completeTask(taskId);
    return unit;
  });

  @override
  Future<Either<Failure, Unit>> createResource({
    required String title,
    required String url,
  }) => _run(() async {
    await _remote.createResource(title: title, url: url);
    return unit;
  });

  @override
  Future<Either<Failure, Unit>> archive({
    required StageItemKind kind,
    required String id,
  }) => _run(() async {
    await _remote.archive(kind: kind, id: id);
    return unit;
  });

  @override
  Future<Either<Failure, Unit>> completeProject(String projectId) =>
      _run(() async {
        await _remote.completeProject(projectId);
        return unit;
      });

  static String _day(DateTime now) =>
      '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';

  Future<Either<Failure, T>> _run<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } on NetworkException {
      return const Left(
        NetworkFailure(
          'No hay conexión con el servidor. Revisa tu internet y reintenta.',
        ),
      );
    } on ServerException catch (error) {
      return Left(ServerFailure(_messageFor(error.code)));
    }
  }

  /// Motivos que lanzan las funciones SQL, en tono de invitación.
  static String _messageFor(String? code) => switch (code) {
    'invalid_title' => 'Dale un nombre de hasta 200 caracteres.',
    'invalid_end_date' => 'La fecha de fin no puede quedar en el pasado.',
    'invalid_due_date' => 'Elige una fecha límite de hoy en adelante.',
    'smart_incomplete' =>
      'Completa las cinco preguntas S.M.A.R.T. para darle forma a tu meta.',
    'task_not_open' => 'Esa misión ya estaba cerrada. ¡Una menos!',
    'task_not_found' => 'No encontramos esa misión. Desliza para actualizar.',
    'invalid_url' => 'Escribe un enlace que empiece por http:// o https://.',
    'skill_not_found' || 'goal_not_found' =>
      'Ese vínculo ya no está disponible. Elige otro o déjalo sin vincular.',
    'item_not_found' ||
    'project_not_found' => 'Eso ya no está aquí. Desliza para actualizar.',
    'project_has_open_tasks' =>
      'A este proyecto aún le quedan misiones abiertas. ¡Ya casi!',
    'project_has_no_completed_tasks' =>
      'Completa al menos una misión del proyecto para cerrarlo.',
    'project_no_real_work' =>
      'Las misiones de este proyecto se cerraron muy rápido. Avanza en una más y vuelve a intentarlo.',
    'project_not_open' => 'Ese proyecto ya estaba cerrado.',
    _ => 'Algo salió mal. Inténtalo de nuevo en un momento.',
  };
}
