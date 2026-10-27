import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/onboarding/domain/entities/onboarding_status.dart';
import 'package:proyecto_movil/features/onboarding/domain/repositories/onboarding_repository.dart';

/// ¿Le toca el Onboarding al jugador? Trae también las dificultades.
class GetOnboardingStatus implements UseCase<OnboardingStatus, NoParams> {
  const GetOnboardingStatus(this._repository);

  final OnboardingRepository _repository;

  @override
  Future<Either<Failure, OnboardingStatus>> call(NoParams params) =>
      _repository.getStatus();
}
