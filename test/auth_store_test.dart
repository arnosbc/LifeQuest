import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_movil/features/auth/models/app_user.dart';
import 'package:proyecto_movil/features/auth/services/auth_service.dart';
import 'package:proyecto_movil/features/auth/stores/auth_store.dart';

import 'helpers/fake_auth_service.dart';

ProviderContainer _container(FakeAuthService service) {
  final container = ProviderContainer(
    overrides: [authServiceProvider.overrideWithValue(service)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('arranca con la sesión guardada en el dispositivo', () {
    final c = _container(
      FakeAuthService(
        currentUser: const AppUser(id: 'u1', email: 'a@b.co'),
      ),
    );
    expect(c.read(authStoreProvider).isSignedIn, isTrue);
  });

  test('signIn guarda el usuario y apaga la carga', () async {
    final c = _container(FakeAuthService());
    final pending = c
        .read(authStoreProvider.notifier)
        .signIn(email: 'ana@correo.com', password: 'secret1');
    expect(c.read(authStoreProvider).isLoading, isTrue);

    await pending;
    final state = c.read(authStoreProvider);
    expect(state.isLoading, isFalse);
    expect(state.user!.email, 'ana@correo.com');
  });

  test('un error llega como AuthFailure y no deja sesión ni carga', () async {
    final c = _container(
      FakeAuthService(
        failure: const AuthFailure('Correo o contraseña incorrectos.'),
      ),
    );
    await expectLater(
      c.read(authStoreProvider.notifier).signIn(email: 'a@b.co', password: 'x'),
      throwsA(isA<AuthFailure>()),
    );
    final state = c.read(authStoreProvider);
    expect(state.isSignedIn, isFalse);
    expect(state.isLoading, isFalse);
  });

  test('un segundo toque mientras carga no lanza otra petición', () async {
    final c = _container(FakeAuthService());
    final store = c.read(authStoreProvider.notifier);
    final first = store.signIn(email: 'a@b.co', password: 'secret1');
    await expectLater(
      store.signIn(email: 'a@b.co', password: 'secret1'),
      throwsA(isA<AuthFailure>()),
    );
    await first;
  });

  test('registro que pide confirmar el correo no inicia sesión', () async {
    final c = _container(
      FakeAuthService(signUpOutcome: SignUpOutcome.needsEmailConfirmation),
    );
    final outcome = await c
        .read(authStoreProvider.notifier)
        .signUp(username: 'Ana', email: 'ana@correo.com', password: 'secret1');
    expect(outcome, SignUpOutcome.needsEmailConfirmation);
    expect(c.read(authStoreProvider).isSignedIn, isFalse);
  });

  test('registro con sesión inicia sesión con el nombre elegido', () async {
    final c = _container(FakeAuthService());
    await c
        .read(authStoreProvider.notifier)
        .signUp(username: 'Ana', email: 'ana@correo.com', password: 'secret1');
    expect(c.read(authStoreProvider).user!.displayName, 'Ana');
  });

  test('signOut borra la sesión', () async {
    final service = FakeAuthService(
      currentUser: const AppUser(id: 'u1', email: 'a@b.co'),
    );
    final c = _container(service);
    await c.read(authStoreProvider.notifier).signOut();
    expect(c.read(authStoreProvider).isSignedIn, isFalse);
    expect(service.signOutCalls, 1);
  });

  test('displayName usa el correo si no hay nombre de usuario', () {
    expect(const AppUser(id: 'u', email: 'ana@correo.com').displayName, 'Ana');
  });
}
