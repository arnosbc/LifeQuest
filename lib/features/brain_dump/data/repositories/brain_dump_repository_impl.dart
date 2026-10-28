import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/brain_dump/data/datasources/brain_dump_remote_datasource.dart';
import 'package:proyecto_movil/features/brain_dump/domain/entities/brain_dump_board.dart';
import 'package:proyecto_movil/features/brain_dump/domain/repositories/brain_dump_repository.dart';

class BrainDumpRepositoryImpl implements BrainDumpRepository {
  const BrainDumpRepositoryImpl(this._remote);

  final BrainDumpRemoteDataSource _remote;

  @override
  Future<Either<Failure, BrainDumpBoard>> getBoard() =>
      _run(() async => (await _remote.getBoard()).toEntity());

  @override
  Future<Either<Failure, Unit>> capture(String content) =>
      _done(() => _remote.capture(content));

  @override
  Future<Either<Failure, Unit>> file(String thoughtId, ThoughtShelf shelf) =>
      _done(() => _remote.file(thoughtId, shelf));

  @override
  Future<Either<Failure, Unit>> convert(Conversion conversion) =>
      _done(() => _remote.convert(conversion));

  @override
  Future<Either<Failure, Unit>> delete(String thoughtId) =>
      _done(() => _remote.delete(thoughtId));

  Future<Either<Failure, Unit>> _done(Future<void> Function() action) =>
      _run(() async {
        await action();
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
    'invalid_content' => 'Escribe tu idea en hasta 500 caracteres.',
    'invalid_title' => 'Dale un nombre de hasta 200 caracteres.',
    'thought_not_found' =>
      'Esa idea ya no está en la bandeja. Desliza para actualizar.',
    'invalid_end_date' => 'La fecha no puede quedar en el pasado.',
    _ => 'Algo salió mal. Inténtalo de nuevo en un momento.',
  };
}
