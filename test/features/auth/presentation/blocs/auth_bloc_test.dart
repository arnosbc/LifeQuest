import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/auth/domain/entities/sign_up_result.dart';
import 'package:proyecto_movil/features/auth/domain/entities/user.dart';
import 'package:proyecto_movil/features/auth/domain/usecases/login_user.dart';
import 'package:proyecto_movil/features/auth/domain/usecases/register_user.dart';
import 'package:proyecto_movil/features/auth/presentation/blocs/auth_bloc.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockGetCurrentUser getCurrentUser;
  late MockLoginUser loginUser;
  late MockRegisterUser registerUser;
  late MockLogoutUser logoutUser;
  late MockLoginWithGoogle loginWithGoogle;
  late MockWatchSignedInUser watchSignedInUser;

  const user = User(id: 'u1', email: 'ana@correo.com', username: 'Ana');
  const loginParams = LoginParams(email: 'ana@correo.com', password: 'x1');
  const registerParams = RegisterParams(
    username: 'Ana',
    email: 'ana@correo.com',
    password: 'secret1',
  );

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(loginParams);
    registerFallbackValue(registerParams);
  });

  setUp(() {
    getCurrentUser = MockGetCurrentUser();
    loginUser = MockLoginUser();
    registerUser = MockRegisterUser();
    logoutUser = MockLogoutUser();
    loginWithGoogle = MockLoginWithGoogle();
    watchSignedInUser = MockWatchSignedInUser();
    when(() => watchSignedInUser()).thenAnswer((_) => const Stream.empty());
  });

  AuthBloc build() => AuthBloc(
    getCurrentUser: getCurrentUser,
    loginUser: loginUser,
    registerUser: registerUser,
    logoutUser: logoutUser,
    loginWithGoogle: loginWithGoogle,
    watchSignedInUser: watchSignedInUser,
  );

  test(
    'empieza en AuthInitial',
    () => expect(build().state, const AuthInitial()),
  );

  group('AuthCheckRequested', () {
    blocTest<AuthBloc, AuthState>(
      'con sesión guardada → AuthSuccess',
      setUp: () => when(
        () => getCurrentUser(any()),
      ).thenAnswer((_) async => const Right(user)),
      build: build,
      act: (bloc) => bloc.add(const AuthCheckRequested()),
      expect: () => [const AuthSuccess(user)],
    );

    blocTest<AuthBloc, AuthState>(
      'sin sesión → AuthUnauthenticated',
      setUp: () => when(
        () => getCurrentUser(any()),
      ).thenAnswer((_) async => const Right(null)),
      build: build,
      act: (bloc) => bloc.add(const AuthCheckRequested()),
      expect: () => [const AuthUnauthenticated()],
    );
  });

  group('LoginRequested', () {
    blocTest<AuthBloc, AuthState>(
      'éxito → Loading, Success',
      setUp: () => when(
        () => loginUser(loginParams),
      ).thenAnswer((_) async => const Right(user)),
      build: build,
      act: (bloc) => bloc.add(
        const LoginRequested(email: 'ana@correo.com', password: 'x1'),
      ),
      expect: () => [const AuthLoading(), const AuthSuccess(user)],
    );

    blocTest<AuthBloc, AuthState>(
      'error → Loading, Failure con el mensaje',
      setUp: () => when(() => loginUser(any())).thenAnswer(
        (_) async =>
            const Left(ServerFailure('Correo o contraseña incorrectos.')),
      ),
      build: build,
      act: (bloc) =>
          bloc.add(const LoginRequested(email: 'a@b.co', password: 'x')),
      expect: () => [
        const AuthLoading(),
        const AuthFailure('Correo o contraseña incorrectos.'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'un segundo toque mientras carga se ignora (droppable)',
      setUp: () => when(() => loginUser(any())).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return const Right(user);
      }),
      build: build,
      act: (bloc) => bloc
        ..add(const LoginRequested(email: 'ana@correo.com', password: 'x1'))
        ..add(const LoginRequested(email: 'ana@correo.com', password: 'x1')),
      wait: const Duration(milliseconds: 50),
      expect: () => [const AuthLoading(), const AuthSuccess(user)],
      verify: (_) => verify(() => loginUser(any())).called(1),
    );
  });

  group('RegisterRequested', () {
    RegisterRequested event() => const RegisterRequested(
      username: 'Ana',
      email: 'ana@correo.com',
      password: 'secret1',
    );

    blocTest<AuthBloc, AuthState>(
      'con sesión → Loading, Success',
      setUp: () => when(() => registerUser(registerParams)).thenAnswer(
        (_) async => const Right(
          SignUpResult(status: SignUpStatus.signedIn, user: user),
        ),
      ),
      build: build,
      act: (bloc) => bloc.add(event()),
      expect: () => [const AuthLoading(), const AuthSuccess(user)],
    );

    blocTest<AuthBloc, AuthState>(
      'pide confirmar el correo → Loading, EmailConfirmationRequired',
      setUp: () => when(() => registerUser(registerParams)).thenAnswer(
        (_) async => const Right(
          SignUpResult(
            status: SignUpStatus.emailConfirmationRequired,
            user: user,
          ),
        ),
      ),
      build: build,
      act: (bloc) => bloc.add(event()),
      expect: () => [
        const AuthLoading(),
        const AuthEmailConfirmationRequired(
          username: 'Ana',
          email: 'ana@correo.com',
        ),
      ],
    );
  });

  blocTest<AuthBloc, AuthState>(
    'LogoutRequested → AuthUnauthenticated',
    setUp: () => when(
      () => logoutUser(any()),
    ).thenAnswer((_) async => const Right(unit)),
    build: build,
    seed: () => const AuthSuccess(user),
    act: (bloc) => bloc.add(const LogoutRequested()),
    expect: () => [const AuthUnauthenticated()],
  );

  group('Google', () {
    blocTest<AuthBloc, AuthState>(
      'si no se abre Google → AuthFailure, sin AuthLoading',
      setUp: () => when(() => loginWithGoogle(any())).thenAnswer(
        (_) async => const Left(ServerFailure('No pudimos abrir Google.')),
      ),
      build: build,
      act: (bloc) => bloc.add(const GoogleLoginRequested()),
      expect: () => [const AuthFailure('No pudimos abrir Google.')],
    );

    blocTest<AuthBloc, AuthState>(
      'si se abre Google no cambia el estado hasta que vuelve',
      setUp: () => when(
        () => loginWithGoogle(any()),
      ).thenAnswer((_) async => const Right(unit)),
      build: build,
      act: (bloc) => bloc.add(const GoogleLoginRequested()),
      expect: () => <AuthState>[],
    );

    final signedIn = StreamController<Either<Failure, User>>();
    blocTest<AuthBloc, AuthState>(
      'al volver de Google con sesión → AuthSuccess; un error luego no la cierra',
      setUp: () =>
          when(() => watchSignedInUser()).thenAnswer((_) => signedIn.stream),
      build: build,
      act: (bloc) async {
        signedIn.add(const Right(user));
        await Future<void>.delayed(Duration.zero);
        signedIn.add(const Left(ServerFailure('falló')));
      },
      expect: () => [const AuthSuccess(user)],
    );

    final failing = StreamController<Either<Failure, User>>();
    blocTest<AuthBloc, AuthState>(
      'al volver de Google con error y sin sesión → AuthFailure',
      setUp: () =>
          when(() => watchSignedInUser()).thenAnswer((_) => failing.stream),
      build: build,
      act: (_) => failing.add(const Left(ServerFailure('No se completó.'))),
      expect: () => [const AuthFailure('No se completó.')],
    );
  });
}
