import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/features/auth/data/datasources/auth_remote_datasource.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockGoTrueClient extends Mock implements GoTrueClient {}

User _supabaseUser({List<UserIdentity>? identities}) => User(
  id: 'u1',
  appMetadata: const {},
  userMetadata: const {'username': ' Ana '},
  aud: 'authenticated',
  createdAt: '2026-10-16T00:00:00Z',
  email: 'ana@correo.com',
  identities: identities,
);

UserIdentity _identity() => UserIdentity(
  id: 'i1',
  userId: 'u1',
  identityData: const {},
  identityId: 'i1',
  provider: 'email',
  createdAt: null,
  lastSignInAt: null,
);

void main() {
  late _MockGoTrueClient auth;
  late AuthRemoteDataSourceImpl dataSource;

  setUp(() {
    final client = _MockSupabaseClient();
    auth = _MockGoTrueClient();
    when(() => client.auth).thenReturn(auth);
    dataSource = AuthRemoteDataSourceImpl(client);
  });

  void givenSignUp(AuthResponse response) => when(
    () => auth.signUp(
      email: any(named: 'email'),
      password: any(named: 'password'),
      data: any(named: 'data'),
    ),
  ).thenAnswer((_) async => response);

  Future<({dynamic user, bool hasSession})> signUp() => dataSource.signUp(
    username: 'Ana',
    email: 'ana@correo.com',
    password: 'secret1',
  );

  test('signUp guarda el nombre en los metadatos y lo recorta', () async {
    givenSignUp(AuthResponse(user: _supabaseUser(identities: [_identity()])));

    final result = await signUp();

    expect(result.hasSession, isFalse);
    expect(result.user.username, 'Ana');
    verify(
      () => auth.signUp(
        email: 'ana@correo.com',
        password: 'secret1',
        data: {'username': 'Ana'},
      ),
    ).called(1);
  });

  test('signUp sin identidades → correo ya registrado', () async {
    givenSignUp(AuthResponse(user: _supabaseUser(identities: const [])));

    expect(
      signUp,
      throwsA(
        isA<ServerException>().having(
          (e) => e.code,
          'code',
          'user_already_exists',
        ),
      ),
    );
  });

  test('AuthException del SDK → ServerException con su código', () async {
    when(
      () => auth.signInWithPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(
      const AuthApiException(
        'Invalid login credentials',
        statusCode: '400',
        code: 'invalid_credentials',
      ),
    );

    expect(
      () => dataSource.signIn(email: 'a@b.co', password: 'x'),
      throwsA(
        isA<ServerException>().having(
          (e) => e.code,
          'code',
          'invalid_credentials',
        ),
      ),
    );
  });

  test('error de red del SDK → NetworkException', () async {
    when(() => auth.signOut()).thenThrow(AuthRetryableFetchException());

    expect(dataSource.signOut, throwsA(isA<NetworkException>()));
  });

  test('currentUser es null sin sesión', () {
    when(() => auth.currentUser).thenReturn(null);
    expect(dataSource.currentUser(), isNull);
  });
}
