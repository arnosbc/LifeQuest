import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/auth/domain/entities/sign_up_result.dart';
import 'package:proyecto_movil/features/auth/domain/entities/user.dart';

/// Contrato de autenticación. La capa data lo implementa.
abstract class AuthRepository {
  Future<Either<Failure, User>> loginUser({
    required String email,
    required String password,
  });

  Future<Either<Failure, SignUpResult>> registerUser({
    required String username,
    required String email,
    required String password,
  });

  Future<Either<Failure, Unit>> logoutUser();

  /// Usuario de la sesión guardada en el dispositivo, o null si no hay.
  Future<Either<Failure, User?>> getCurrentUser();
}
