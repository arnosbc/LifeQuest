import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/auth/domain/repositories/auth_repository.dart';

/// Cierra la sesión actual.
class LogoutUser implements UseCase<Unit, NoParams> {
  const LogoutUser(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) =>
      _repository.logoutUser();
}
