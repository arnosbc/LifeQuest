import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/onboarding/domain/entities/onboarding_choices.dart';
import 'package:proyecto_movil/features/onboarding/domain/repositories/onboarding_repository.dart';

/// Guarda lo elegido y cierra el Onboarding (al terminar o al saltar).
class CompleteOnboarding implements UseCase<Unit, OnboardingChoices> {
  const CompleteOnboarding(this._repository);

  final OnboardingRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(OnboardingChoices params) async =>
      params.isValid
      ? _repository.complete(params)
      : const Left(
          ServerFailure(
            'Usa una identidad de hasta 280 caracteres y una skill de hasta 40.',
          ),
        );
}
