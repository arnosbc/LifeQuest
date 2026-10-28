import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/stats/domain/entities/stats_board.dart';
import 'package:proyecto_movil/features/stats/domain/repositories/stats_repository.dart';

/// Lee las estadísticas de la semana; el parámetro es la hora local.
class GetStats implements UseCase<StatsBoard, DateTime> {
  const GetStats(this._repository);

  final StatsRepository _repository;

  @override
  Future<Either<Failure, StatsBoard>> call(DateTime params) =>
      _repository.getStats(params);
}
