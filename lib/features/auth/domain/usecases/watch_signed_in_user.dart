import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/auth/domain/entities/user.dart';
import 'package:proyecto_movil/features/auth/domain/repositories/auth_repository.dart';

/// Avisa de cada inicio de sesión (Google vuelve a la app por un enlace).
class WatchSignedInUser {
  const WatchSignedInUser(this._repository);

  final AuthRepository _repository;

  Stream<Either<Failure, User>> call() => _repository.signedInUsers();
}
