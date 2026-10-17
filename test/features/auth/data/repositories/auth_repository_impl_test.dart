import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/auth/data/models/user_model.dart';
import 'package:proyecto_movil/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:proyecto_movil/features/auth/domain/entities/sign_up_result.dart';
import 'package:proyecto_movil/features/auth/domain/entities/user.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockAuthRemoteDataSource remote;
  late AuthRepositoryImpl repository;
  const model = UserModel(id: 'u1', email: 'ana@correo.com', username: 'Ana');
  const user = User(id: 'u1', email: 'ana@correo.com', username: 'Ana');

  setUp(() {
    remote = MockAuthRemoteDataSource();
    repository = AuthRepositoryImpl(remote);
  });

  void givenSignInThrows(Object error) => when(
    () => remote.signIn(
      email: any(named: 'email'),
      password: any(named: 'password'),
    ),
  ).thenThrow(error);

  Future<Either<Failure, User>> login() =>
      repository.loginUser(email: 'ana@correo.com', password: 'x');

  group('loginUser', () {
    test('devuelve la entidad del modelo', () async {
      when(
        () => remote.signIn(email: 'ana@correo.com', password: 'x'),
      ).thenAnswer((_) async => model);

      expect(await login(), const Right<Failure, User>(user));
    });

    final cases = {
      const ServerException(code: 'invalid_credentials'):
          'Correo o contraseña incorrectos. Revísalos e inténtalo de nuevo.',
      const ServerException(message: 'Invalid login credentials'):
          'Correo o contraseña incorrectos. Revísalos e inténtalo de nuevo.',
      const ServerException(code: 'email_not_confirmed'):
          'Confirma tu correo con el enlace que te enviamos y vuelve a entrar.',
      const ServerException(statusCode: '429'):
          'Demasiados intentos seguidos. Espera un momento y reintenta.',
      const ServerException(code: 'otro_error'):
          'Algo salió mal. Inténtalo de nuevo en un momento.',
    };
    for (final MapEntry(key: error, value: message) in cases.entries) {
      test('$error → ServerFailure con mensaje en español', () async {
        givenSignInThrows(error);
        expect(await login(), Left<Failure, User>(ServerFailure(message)));
      });
    }

    test('sin conexión → NetworkFailure', () async {
      givenSignInThrows(const NetworkException());
      expect(
        await login(),
        const Left<Failure, User>(
          NetworkFailure(
            'No hay conexión con el servidor. Revisa tu internet y reintenta.',
          ),
        ),
      );
    });
  });

  group('registerUser', () {
    void givenSignUp({required bool hasSession}) => when(
      () => remote.signUp(
        username: 'Ana',
        email: 'ana@correo.com',
        password: 'secret1',
      ),
    ).thenAnswer((_) async => (user: model, hasSession: hasSession));

    Future<Either<Failure, SignUpResult>> register() => repository.registerUser(
      username: 'Ana',
      email: 'ana@correo.com',
      password: 'secret1',
    );

    test('con sesión → signedIn', () async {
      givenSignUp(hasSession: true);
      expect(
        await register(),
        const Right<Failure, SignUpResult>(
          SignUpResult(status: SignUpStatus.signedIn, user: user),
        ),
      );
    });

    test('sin sesión → emailConfirmationRequired', () async {
      givenSignUp(hasSession: false);
      expect(
        await register(),
        const Right<Failure, SignUpResult>(
          SignUpResult(
            status: SignUpStatus.emailConfirmationRequired,
            user: user,
          ),
        ),
      );
    });

    test('correo ya registrado → mensaje de cuenta existente', () async {
      when(
        () => remote.signUp(
          username: any(named: 'username'),
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const ServerException(code: 'user_already_exists'));
      expect(
        await register(),
        const Left<Failure, SignUpResult>(
          ServerFailure('Ya existe una cuenta con ese correo. Inicia sesión.'),
        ),
      );
    });
  });

  group('logoutUser', () {
    test('sin conexión igualmente cierra la sesión local', () async {
      when(() => remote.signOut()).thenThrow(const NetworkException());
      expect(await repository.logoutUser(), const Right<Failure, Unit>(unit));
    });

    test('error del servidor → ServerFailure', () async {
      when(
        () => remote.signOut(),
      ).thenThrow(const ServerException(code: 'otro_error'));
      expect(await repository.logoutUser(), isA<Left<Failure, Unit>>());
    });
  });

  test('getCurrentUser convierte el modelo o devuelve null', () async {
    when(() => remote.currentUser()).thenReturn(model);
    expect(
      await repository.getCurrentUser(),
      const Right<Failure, User?>(user),
    );

    when(() => remote.currentUser()).thenReturn(null);
    expect(
      await repository.getCurrentUser(),
      const Right<Failure, User?>(null),
    );
  });
}
