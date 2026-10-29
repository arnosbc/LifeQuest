import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/auth/domain/entities/social_provider.dart';
import 'package:proyecto_movil/features/auth/domain/repositories/auth_repository.dart';

/// Abre el inicio de sesión de Google o Apple. La sesión no llega aquí: llega
/// por [WatchAuthChanges] cuando el usuario vuelve a la app.
class LoginWithProvider implements UseCase<Unit, SocialProvider> {
  const LoginWithProvider(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(SocialProvider provider) =>
      _repository.loginWithProvider(provider);
}
