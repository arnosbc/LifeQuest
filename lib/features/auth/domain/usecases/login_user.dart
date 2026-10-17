import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/auth/domain/entities/user.dart';
import 'package:proyecto_movil/features/auth/domain/repositories/auth_repository.dart';

/// Inicia sesión con correo y contraseña.
class LoginUser implements UseCase<User, LoginParams> {
  const LoginUser(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, User>> call(LoginParams params) =>
      _repository.loginUser(email: params.email, password: params.password);
}

class LoginParams extends Equatable {
  const LoginParams({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}
