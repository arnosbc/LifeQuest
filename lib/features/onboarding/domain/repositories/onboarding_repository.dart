import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/onboarding/domain/entities/onboarding_choices.dart';
import 'package:proyecto_movil/features/onboarding/domain/entities/onboarding_status.dart';

/// Contrato del Onboarding. La capa data lo implementa.
abstract class OnboardingRepository {
  Future<Either<Failure, OnboardingStatus>> getStatus();

  /// Guarda todo de una vez y marca el Onboarding como visto (terminar o saltar).
  Future<Either<Failure, Unit>> complete(OnboardingChoices choices);
}
