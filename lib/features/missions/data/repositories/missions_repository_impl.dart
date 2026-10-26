import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/missions/data/datasources/missions_remote_datasource.dart';
import 'package:proyecto_movil/features/missions/domain/entities/missions_board.dart';
import 'package:proyecto_movil/features/missions/domain/entities/new_mission.dart';
import 'package:proyecto_movil/features/missions/domain/repositories/missions_repository.dart';

class MissionsRepositoryImpl implements MissionsRepository {
  const MissionsRepositoryImpl(this._remote);

  final MissionsRemoteDataSource _remote;

  @override
  Future<Either<Failure, MissionsBoard>> getBoard() =>
      _run(() async => (await _remote.getBoard()).toEntity());

  @override
  Future<Either<Failure, Unit>> createMission(NewMission mission) =>
      _run(() async {
        await _remote.createMission(mission);
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> completeMission(String missionId) =>
      _run(() async {
        await _remote.completeMission(missionId);
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
    'invalid_title' => 'Dale a tu misión un nombre de hasta 200 caracteres.',
    'skill_not_found' || 'project_not_found' || 'goal_not_found' =>
      'Ese vínculo ya no está disponible. Elige otro o deja la misión sin vincular.',
    'task_not_found' => 'No encontramos esa misión. Desliza para actualizar.',
    'task_not_open' => 'Esa misión ya estaba cerrada. ¡Una menos!',
    _ => 'Algo salió mal. Inténtalo de nuevo en un momento.',
  };
}
