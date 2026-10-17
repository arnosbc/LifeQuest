import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_user.dart';

/// Error de autenticación con un mensaje listo para mostrar al usuario.
class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => 'AuthFailure: $message';
}

/// Resultado del registro: entra directo o debe confirmar el correo primero.
enum SignUpOutcome { signedIn, needsEmailConfirmation }

/// Único punto de la app que habla con Supabase Auth.
class AuthService {
  AuthService(this._client);

  final SupabaseClient _client;

  AppUser? get currentUser {
    final user = _client.auth.currentUser;
    return user == null ? null : AppUser.fromSupabase(user);
  }

  Future<AppUser> signIn({required String email, required String password}) =>
      _guard(() async {
        final response = await _client.auth.signInWithPassword(
          email: email,
          password: password,
        );
        return AppUser.fromSupabase(response.user!);
      });

  Future<(SignUpOutcome, AppUser)> signUp({
    required String username,
    required String email,
    required String password,
  }) => _guard(() async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'username': username},
    );
    final user = response.user!;
    // Con un correo ya confirmado, Supabase no da error (para no revelar qué
    // cuentas existen) pero devuelve el usuario sin identidades.
    if (user.identities?.isEmpty ?? false) {
      throw const AuthFailure(
        'Ya existe una cuenta con ese correo. Inicia sesión.',
      );
    }
    final outcome = response.session != null
        ? SignUpOutcome.signedIn
        : SignUpOutcome.needsEmailConfirmation;
    return (outcome, AppUser.fromSupabase(user));
  });

  /// Sin conexión no se revoca en el servidor, pero la sesión local sí se
  /// borra, así que nunca falla.
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (_) {}
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AuthFailure {
      rethrow;
    } catch (error) {
      throw AuthFailure(_messageFor(error));
    }
  }

  /// Traduce los errores de Supabase a mensajes que dicen qué hacer.
  static String _messageFor(Object error) {
    if (error is AuthRetryableFetchException) {
      return 'No hay conexión con el servidor. Revisa tu internet y reintenta.';
    }
    if (error is AuthException) {
      final code = error.code;
      final message = error.message.toLowerCase();
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
    }
    return 'Algo salió mal. Inténtalo de nuevo en un momento.';
  }
}

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(Supabase.instance.client),
);
