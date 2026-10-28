import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/stats/data/datasources/stats_remote_datasource.dart';
import 'package:proyecto_movil/features/stats/domain/entities/stats_board.dart';
import 'package:proyecto_movil/features/stats/domain/repositories/stats_repository.dart';

class StatsRepositoryImpl implements StatsRepository {
  const StatsRepositoryImpl(this._remote);

  final StatsRemoteDataSource _remote;

  @override
  Future<Either<Failure, StatsBoard>> getStats(DateTime now) async {
    try {
      final day =
          '${now.year.toString().padLeft(4, '0')}-'
          '${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}';
      return Right((await _remote.getStats(day)).toEntity());
    } on NetworkException {
      return const Left(
        NetworkFailure(
          'No hay conexión con el servidor. Revisa tu internet y reintenta.',
        ),
      );
    } on ServerException {
      return const Left(
        ServerFailure(
          'No pudimos leer tus estadísticas. Inténtalo en un momento.',
        ),
      );
    }
  }
}
