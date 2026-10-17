import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';

/// Estado de la sesión: quién entró y si hay una petición en curso.
class AuthState {
  const AuthState({this.user, this.isLoading = false});

  final AppUser? user;
  final bool isLoading;

  bool get isSignedIn => user != null;
}

/// Store de la sesión. Las pantallas leen su estado y llaman a sus acciones;
/// los errores llegan como [AuthFailure] para mostrarlos donde corresponda.
class AuthStore extends Notifier<AuthState> {
  AuthService get _service => ref.read(authServiceProvider);

  @override
  AuthState build() => AuthState(user: _service.currentUser);

  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    _startLoading();
    try {
      final user = await _service.signIn(email: email, password: password);
      state = AuthState(user: user);
      return user;
    } catch (_) {
      state = AuthState(user: state.user);
      rethrow;
    }
  }

  /// Si hay que confirmar el correo, el usuario no queda con sesión iniciada.
  Future<SignUpOutcome> signUp({
    required String username,
    required String email,
    required String password,
  }) async {
    _startLoading();
    try {
      final (outcome, user) = await _service.signUp(
        username: username,
        email: email,
        password: password,
      );
      state = AuthState(
        user: outcome == SignUpOutcome.signedIn ? user : state.user,
      );
      return outcome;
    } catch (_) {
      state = AuthState(user: state.user);
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _service.signOut();
    state = const AuthState();
  }

  /// Un segundo toque mientras carga no lanza otra petición.
  void _startLoading() {
    if (state.isLoading) throw const AuthFailure('Espera un momento…');
    state = AuthState(user: state.user, isLoading: true);
  }
}

final authStoreProvider = NotifierProvider<AuthStore, AuthState>(AuthStore.new);
