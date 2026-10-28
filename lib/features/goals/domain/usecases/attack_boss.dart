import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/goals/domain/entities/goals_board.dart';
import 'package:proyecto_movil/features/goals/domain/repositories/goals_repository.dart';

/// Lanza un ataque: completa la tarea o el proyecto vinculado.
class AttackBoss implements UseCase<Unit, BossAttack> {
  const AttackBoss(this._repository);

  final GoalsRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(BossAttack params) =>
      _repository.attack(params);
}
