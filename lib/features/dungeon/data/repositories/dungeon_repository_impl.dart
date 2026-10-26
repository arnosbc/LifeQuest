import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/dungeon/data/datasources/dungeon_remote_datasource.dart';
import 'package:proyecto_movil/features/dungeon/domain/entities/dungeon_board.dart';
import 'package:proyecto_movil/features/dungeon/domain/repositories/dungeon_repository.dart';

class DungeonRepositoryImpl implements DungeonRepository {
  const DungeonRepositoryImpl(this._remote);

  final DungeonRemoteDataSource _remote;

  @override
  Future<Either<Failure, DungeonBoard>> getBoard() =>
      _run(() async => (await _remote.getBoard()).toEntity());

  @override
  Future<Either<Failure, String>> start({
    required int totalMinutes,
    required int cycleMinutes,
    required List<String> taskIds,
  }) => _run(
    () => _remote.start(
      totalMinutes: totalMinutes,
      cycleMinutes: cycleMinutes,
      taskIds: taskIds,
    ),
  );

  @override
  Future<Either<Failure, Unit>> completeCycle({
    required String sessionId,
    required String taskId,
  }) => _run(() async {
    await _remote.completeCycle(sessionId: sessionId, taskId: taskId);
    return unit;
  });

  @override
  Future<Either<Failure, Unit>> completeTask(String taskId) => _run(() async {
    await _remote.completeTask(taskId);
    return unit;
  });

  @override
  Future<Either<Failure, DungeonSummary>> end(String sessionId) =>
      _run(() async => (await _remote.end(sessionId)).toEntity());

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
    'session_already_open' =>
      'Ya tienes una Mazmorra en curso. Desliza para retomarla.',
    'invalid_duration' =>
      'La sesión dura de 30 min a 8 h, en pasos de 30, y cabe al menos un ciclo.',
    'no_tasks' => 'Elige al menos una misión para tu mochila.',
    'session_task_limit' => 'Tu mochila admite hasta 5 misiones.',
    'task_not_found' =>
      'Alguna misión ya no está abierta. Desliza para actualizar.',
    'cycle_not_finished' => 'Al ciclo aún le falta un poco. Sigue concentrado.',
    'session_cycles_exhausted' =>
      'Completaste todos los ciclos de esta sesión. ¡Gran trabajo!',
    'session_not_found' || 'session_not_active' =>
      'Esta sesión ya terminó. Puedes empezar otra cuando quieras.',
    'task_not_open' => 'Esa misión ya estaba cerrada. ¡Una menos!',
    _ => 'Algo salió mal. Inténtalo de nuevo en un momento.',
  };
}
