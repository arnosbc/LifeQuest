import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:proyecto_movil/features/auth/domain/entities/sign_up_result.dart';
import 'package:proyecto_movil/features/auth/domain/entities/user.dart';
import 'package:proyecto_movil/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remote);

  final AuthRemoteDataSource _remote;

  @override
  Future<Either<Failure, User>> loginUser({
    required String email,
    required String password,
  }) => _run(() async {
    final model = await _remote.signIn(email: email, password: password);
    return model.toEntity();
  });

  @override
  Future<Either<Failure, SignUpResult>> registerUser({
    required String username,
    required String email,
    required String password,
  }) => _run(() async {
    final result = await _remote.signUp(
      username: username,
      email: email,
      password: password,
    );
    return SignUpResult(
      status: result.hasSession
          ? SignUpStatus.signedIn
          : SignUpStatus.emailConfirmationRequired,
      user: result.user.toEntity(),
    );
  });

  @override
  Future<Either<Failure, Unit>> logoutUser() async {
    try {
      await _remote.signOut();
    } on NetworkException {
      // Sin conexión no se revoca en el servidor, pero el SDK ya borró la
      // sesión local: para el usuario, la sesión está cerrada.
    } on ServerException catch (error) {
      return Left(ServerFailure(_messageFor(error)));
    }
    return const Right(unit);
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async =>
      Right(_remote.currentUser()?.toEntity());

  Future<Either<Failure, T>> _run<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } on NetworkException {
      return const Left(
        NetworkFailure(
          'No hay conexión con el servidor. Revisa tu internet y reintenta.',
        ),
      );
    } on ServerException catch (error) {
      return Left(ServerFailure(_messageFor(error)));
    }
  }

  /// Mensajes que dicen qué hacer, con tono de invitación.
  static String _messageFor(ServerException error) {
    final code = error.code;
    final message = (error.message ?? '').toLowerCase();
    if (code == 'invalid_credentials' ||
        message.contains('invalid login credentials')) {
      return 'Correo o contraseña incorrectos. Revísalos e inténtalo de nuevo.';
    }
    if (code == 'email_not_confirmed' ||
        message.contains('email not confirmed')) {
      return 'Confirma tu correo con el enlace que te enviamos y vuelve a entrar.';
    }
    if (code == 'user_already_exists' ||
        message.contains('already registered')) {
      return 'Ya existe una cuenta con ese correo. Inicia sesión.';
    }
    if (code == 'weak_password' || message.contains('password should')) {
      return 'Elige una contraseña más segura, de al menos 6 caracteres.';
    }
    if (code == 'over_email_send_rate_limit' ||
        code == 'over_request_rate_limit' ||
        error.statusCode == '429') {
      return 'Demasiados intentos seguidos. Espera un momento y reintenta.';
    }
    return 'Algo salió mal. Inténtalo de nuevo en un momento.';
  }
}
