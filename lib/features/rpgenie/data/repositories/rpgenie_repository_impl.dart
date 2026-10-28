import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/rpgenie/data/datasources/rpgenie_remote_datasource.dart';
import 'package:proyecto_movil/features/rpgenie/domain/entities/current_mission.dart';
import 'package:proyecto_movil/features/rpgenie/domain/repositories/rpgenie_repository.dart';

class RpgenieRepositoryImpl implements RpgenieRepository {
  const RpgenieRepositoryImpl(this._remote);

  final RpgenieRemoteDataSource _remote;

  @override
  Future<Either<Failure, RpgenieBoard>> getCurrentMission(List<String> skip) =>
      _run(() async => (await _remote.getCurrentMission(skip)).toEntity());

  @override
  Future<Either<Failure, Unit>> completeMission(String taskId) =>
      _run(() async {
        await _remote.completeMission(taskId);
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
      return Left(
        ServerFailure(switch (error.code) {
          'task_not_open' => 'Esa misión ya estaba cerrada. ¡Una menos!',
          'task_not_found' =>
            'No encontramos esa misión. Desliza para actualizar.',
          _ => 'Algo salió mal. Inténtalo de nuevo en un momento.',
        }),
      );
    }
  }
}
