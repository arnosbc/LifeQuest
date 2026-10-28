import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/goals/data/datasources/goals_remote_datasource.dart';
import 'package:proyecto_movil/features/goals/domain/entities/goals_board.dart';
import 'package:proyecto_movil/features/goals/domain/repositories/goals_repository.dart';

class GoalsRepositoryImpl implements GoalsRepository {
  const GoalsRepositoryImpl(this._remote);

  final GoalsRemoteDataSource _remote;

  @override
  Future<Either<Failure, GoalsBoard>> getBoard() =>
      _run(() async => (await _remote.getBoard()).toEntity());

  @override
  Future<Either<Failure, Unit>> attack(BossAttack attack) => _run(() async {
    await _remote.attack(attack);
    return unit;
  });

  @override
  Future<Either<Failure, Unit>> archiveGoal(String goalId) => _run(() async {
    await _remote.archiveGoal(goalId);
    return unit;
  });

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
    'task_not_open' => 'Esa misión ya estaba cerrada. ¡Una menos!',
    'task_not_found' ||
    'project_not_found' ||
    'item_not_found' => 'Eso ya no está aquí. Desliza para actualizar.',
    'project_has_open_tasks' =>
      'A este proyecto aún le quedan misiones abiertas. ¡Ya casi!',
    'project_has_no_completed_tasks' =>
      'Completa al menos una misión del proyecto para cerrarlo.',
    'project_no_real_work' =>
      'Las misiones de este proyecto se cerraron muy rápido. '
          'Avanza en una más y vuelve a intentarlo.',
    'project_not_open' => 'Ese proyecto ya estaba cerrado.',
    _ => 'Algo salió mal. Inténtalo de nuevo en un momento.',
  };
}
