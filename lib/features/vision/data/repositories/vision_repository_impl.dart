import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/vision/data/datasources/vision_remote_datasource.dart';
import 'package:proyecto_movil/features/vision/domain/entities/vision_board.dart';
import 'package:proyecto_movil/features/vision/domain/repositories/vision_repository.dart';

class VisionRepositoryImpl implements VisionRepository {
  const VisionRepositoryImpl(this._remote);

  final VisionRemoteDataSource _remote;

  @override
  Future<Either<Failure, VisionBoard>> getBoard() =>
      _run(() async => (await _remote.getBoard()).toEntity());

  @override
  Future<Either<Failure, Unit>> save(String content) => _run(() async {
    await _remote.save(content);
    return unit;
  });

  @override
  Future<Either<Failure, Unit>> setLink(
    VisionItem item, {
    required bool linked,
  }) => _run(() async {
    await _remote.setLink(item, linked);
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
          'invalid_content' => 'Tu visión cabe en 2.000 caracteres.',
          'item_not_found' => 'Eso ya no está aquí. Desliza para actualizar.',
          _ => 'Algo salió mal. Inténtalo de nuevo en un momento.',
        }),
      );
    }
  }
}
