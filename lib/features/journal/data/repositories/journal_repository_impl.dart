import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/journal/data/datasources/journal_remote_datasource.dart';
import 'package:proyecto_movil/features/journal/domain/entities/journal_board.dart';
import 'package:proyecto_movil/features/journal/domain/repositories/journal_repository.dart';

class JournalRepositoryImpl implements JournalRepository {
  const JournalRepositoryImpl(this._remote);

  final JournalRemoteDataSource _remote;

  @override
  Future<Either<Failure, JournalBoard>> getJournal(DateTime now) async {
    try {
      final day =
          '${now.year.toString().padLeft(4, '0')}-'
          '${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}';
      return Right((await _remote.getJournal(day)).toEntity());
    } on NetworkException {
      return const Left(
        NetworkFailure(
          'No hay conexión con el servidor. Revisa tu internet y reintenta.',
        ),
      );
    } on ServerException {
      return const Left(
        ServerFailure('No pudimos abrir tu Diario. Inténtalo en un momento.'),
      );
    }
  }
}
