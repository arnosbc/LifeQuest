import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/auth/domain/entities/user.dart';
import 'package:proyecto_movil/features/auth/domain/repositories/auth_repository.dart';

/// Inicia sesión con la cuenta de Google del teléfono. Null si se canceló.
class LoginWithGoogle implements UseCase<User?, NoParams> {
  const LoginWithGoogle(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, User?>> call(NoParams params) =>
      _repository.loginWithGoogle();
}
