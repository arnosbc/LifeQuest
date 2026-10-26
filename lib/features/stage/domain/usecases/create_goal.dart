import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/stage/domain/entities/new_goal.dart';
import 'package:proyecto_movil/features/stage/domain/repositories/stage_repository.dart';

/// Crea una Meta (Boss) con su ficha S.M.A.R.T.
class CreateGoal implements UseCase<Unit, NewGoal> {
  const CreateGoal(this._repository);

  final StageRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(NewGoal params) =>
      _repository.createGoal(params);
}
