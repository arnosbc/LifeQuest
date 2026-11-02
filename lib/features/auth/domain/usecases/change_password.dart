import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/auth/domain/repositories/auth_repository.dart';

/// Cambia la contraseña de la sesión actual (Ajustes → Cuenta).
class ChangePassword implements UseCase<Unit, String> {
  const ChangePassword(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(String password) =>
      _repository.changePassword(password);
}
