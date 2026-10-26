import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/habits/domain/entities/habits_board.dart';
import 'package:proyecto_movil/features/habits/domain/repositories/habits_repository.dart';

/// Lee los hábitos y su resumen; el parámetro es la hora local.
class GetHabitsBoard implements UseCase<HabitsBoard, DateTime> {
  const GetHabitsBoard(this._repository);

  final HabitsRepository _repository;

  @override
  Future<Either<Failure, HabitsBoard>> call(DateTime params) =>
      _repository.getBoard(params);
}
