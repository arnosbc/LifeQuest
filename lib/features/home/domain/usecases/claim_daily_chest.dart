import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/home/domain/repositories/home_repository.dart';

/// Cobra el cofre del día.
class ClaimDailyChest implements UseCase<Unit, NoParams> {
  const ClaimDailyChest(this._repository);

  final HomeRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) =>
      _repository.claimDailyChest();
}
