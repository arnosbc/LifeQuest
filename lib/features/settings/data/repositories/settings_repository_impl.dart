import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/settings/data/datasources/settings_remote_datasource.dart';
import 'package:proyecto_movil/features/settings/domain/entities/game_settings.dart';
import 'package:proyecto_movil/features/settings/domain/repositories/settings_repository.dart';
import 'package:proyecto_movil/features/settings/domain/usecases/save_game_settings.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  const SettingsRepositoryImpl(this._remote);

  final SettingsRemoteDataSource _remote;

  @override
  Future<Either<Failure, SettingsOverview>> getOverview() =>
      _run(() async => (await _remote.getOverview()).toEntity());

  @override
  Future<Either<Failure, Unit>> save(GameSettings settings) => _run(() async {
    await _remote.save(settings);
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
        ServerFailure(
          // 23514: un check de 016 rechazó el valor.
          error.statusCode == '23514'
              ? SettingsMessages.outOfRange
              : 'Algo salió mal. Inténtalo de nuevo en un momento.',
        ),
      );
    }
  }
}
