import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/auth/domain/entities/sign_up_result.dart';
import 'package:proyecto_movil/features/auth/domain/repositories/auth_repository.dart';

/// Crea una cuenta con nombre de usuario, correo y contraseña.
class RegisterUser implements UseCase<SignUpResult, RegisterParams> {
  const RegisterUser(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, SignUpResult>> call(RegisterParams params) =>
      _repository.registerUser(
        username: params.username,
        email: params.email,
        password: params.password,
      );
}

class RegisterParams extends Equatable {
  const RegisterParams({
    required this.username,
    required this.email,
    required this.password,
  });

  final String username;
  final String email;
  final String password;

  @override
  List<Object?> get props => [username, email, password];
}
