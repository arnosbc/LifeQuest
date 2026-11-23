import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/auth/domain/repositories/auth_repository.dart';

/// Abre el inicio con Google. La sesión llega después por [WatchSignedInUser].
class LoginWithGoogle implements UseCase<Unit, NoParams> {
  const LoginWithGoogle(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) =>
      _repository.loginWithGoogle();
}
