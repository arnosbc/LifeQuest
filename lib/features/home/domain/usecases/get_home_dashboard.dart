import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/home/domain/entities/home_dashboard.dart';
import 'package:proyecto_movil/features/home/domain/repositories/home_repository.dart';

/// Lee los datos del Home para el día de [DateTime] (hora local).
class GetHomeDashboard implements UseCase<HomeDashboard, DateTime> {
  const GetHomeDashboard(this._repository);

  final HomeRepository _repository;

  @override
  Future<Either<Failure, HomeDashboard>> call(DateTime now) =>
      _repository.getDashboard(now);
}
