import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/brain_dump/domain/entities/brain_dump_board.dart';
import 'package:proyecto_movil/features/brain_dump/domain/repositories/brain_dump_repository.dart';

/// Convierte una idea en Meta tras el formulario S.M.A.R.T. (RF-014).
class ConvertThoughtToGoal implements UseCase<Unit, GoalConversion> {
  const ConvertThoughtToGoal(this._repository);

  final BrainDumpRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(GoalConversion params) =>
      _repository.convertToGoal(params);
}
