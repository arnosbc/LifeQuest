import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/auth/domain/entities/sign_up_result.dart';
import 'package:proyecto_movil/features/auth/domain/entities/user.dart';
import 'package:proyecto_movil/features/auth/domain/usecases/get_current_user.dart';
import 'package:proyecto_movil/features/auth/domain/usecases/login_user.dart';
import 'package:proyecto_movil/features/auth/domain/usecases/logout_user.dart';
import 'package:proyecto_movil/features/auth/domain/usecases/register_user.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockAuthRepository repository;
  const user = User(id: 'u1', email: 'ana@correo.com', username: 'Ana');

  setUp(() => repository = MockAuthRepository());

  group('LoginUser', () {
    test('delega en el repositorio con correo y contraseña', () async {
      when(
        () => repository.loginUser(email: 'ana@correo.com', password: 'x1'),
      ).thenAnswer((_) async => const Right(user));

      final result = await LoginUser(repository)(
        const LoginParams(email: 'ana@correo.com', password: 'x1'),
      );

      expect(result, const Right<Failure, User>(user));
    });

    test('propaga el Failure del repositorio', () async {
      when(
        () => repository.loginUser(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const Left(ServerFailure('error')));

      final result = await LoginUser(repository)(
        const LoginParams(email: 'a@b.co', password: 'x'),
      );

      expect(result, const Left<Failure, User>(ServerFailure('error')));
    });
  });

  test('RegisterUser delega con nombre, correo y contraseña', () async {
    const signUp = SignUpResult(status: SignUpStatus.signedIn, user: user);
    when(
      () => repository.registerUser(
        username: 'Ana',
        email: 'ana@correo.com',
        password: 'secret1',
      ),
    ).thenAnswer((_) async => const Right(signUp));

    final result = await RegisterUser(repository)(
      const RegisterParams(
        username: 'Ana',
        email: 'ana@correo.com',
        password: 'secret1',
      ),
    );

    expect(result, const Right<Failure, SignUpResult>(signUp));
  });

  test('LogoutUser delega en el repositorio', () async {
    when(
      () => repository.logoutUser(),
    ).thenAnswer((_) async => const Right(unit));

    final result = await LogoutUser(repository)(const NoParams());

    expect(result, const Right<Failure, Unit>(unit));
    verify(() => repository.logoutUser()).called(1);
  });

  test('GetCurrentUser devuelve la sesión guardada', () async {
    when(
      () => repository.getCurrentUser(),
    ).thenAnswer((_) async => const Right(user));

    final result = await GetCurrentUser(repository)(const NoParams());

    expect(result, const Right<Failure, User?>(user));
  });

  test('User.displayName usa el correo si no hay nombre de usuario', () {
    expect(const User(id: 'u', email: 'ana@correo.com').displayName, 'Ana');
    expect(user.displayName, 'Ana');
  });
}
