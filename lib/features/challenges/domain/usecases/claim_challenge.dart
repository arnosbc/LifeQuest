import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/challenges/domain/repositories/challenges_repository.dart';

/// Cobra el cofre de un desafío cumplido; el parámetro es su clave.
class ClaimChallenge implements UseCase<Unit, String> {
  const ClaimChallenge(this._repository);

  final ChallengesRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(String key) =>
      _repository.claimChallenge(key);
}
