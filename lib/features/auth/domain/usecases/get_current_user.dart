import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/auth/domain/entities/user.dart';
import 'package:proyecto_movil/features/auth/domain/repositories/auth_repository.dart';

/// Devuelve el usuario de la sesión guardada, o null si no hay sesión.
class GetCurrentUser implements UseCase<User?, NoParams> {
  const GetCurrentUser(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, User?>> call(NoParams params) =>
      _repository.getCurrentUser();
}
