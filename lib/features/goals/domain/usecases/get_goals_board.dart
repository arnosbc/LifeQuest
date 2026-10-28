import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/goals/domain/entities/goals_board.dart';
import 'package:proyecto_movil/features/goals/domain/repositories/goals_repository.dart';

/// Lee las Metas como jefes, con sus ataques y golpes.
class GetGoalsBoard implements UseCase<GoalsBoard, NoParams> {
  const GetGoalsBoard(this._repository);

  final GoalsRepository _repository;

  @override
  Future<Either<Failure, GoalsBoard>> call(NoParams params) =>
      _repository.getBoard();
}
