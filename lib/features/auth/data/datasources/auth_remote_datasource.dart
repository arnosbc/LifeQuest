import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/features/auth/data/models/user_model.dart';

/// Acceso a Supabase Auth. Lanza [ServerException] o [NetworkException].
abstract class AuthRemoteDataSource {
  Future<UserModel> signIn({required String email, required String password});

  /// Cuenta de Google del teléfono. Null si el usuario cerró la ventana.
  Future<UserModel?> signInWithGoogle();

  /// Devuelve el usuario creado y si quedó con sesión iniciada.
  Future<({UserModel user, bool hasSession})> signUp({
    required String username,
    required String email,
    required String password,
  });

  Future<void> signOut();

  /// Cambia la contraseña del usuario con sesión.
  Future<void> updatePassword(String password);

  UserModel? currentUser();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl(this._client, {this.googleWebClientId = ''});

  final SupabaseClient _client;
  final String googleWebClientId;

  // GoogleSignIn.initialize solo se puede llamar una vez por proceso.
  static Future<void>? _googleReady;

  @override
  Future<UserModel> signIn({required String email, required String password}) =>
      _guard(() async {
        final response = await _client.auth.signInWithPassword(
          email: email,
          password: password,
        );
        return UserModel.fromSupabase(response.user!);
      });

  @override
  Future<UserModel?> signInWithGoogle() => _guard(() async {
    if (googleWebClientId.isEmpty) {
      throw const ServerException(code: 'google_not_configured');
    }
    final google = GoogleSignIn.instance;
    final GoogleSignInAccount account;
    try {
      await (_googleReady ??= google.initialize(
        serverClientId: googleWebClientId,
      ));
      account = await google.authenticate();
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) return null;
      throw ServerException(code: 'google_failed', message: error.description);
    } catch (error) {
      _googleReady = null; // si falló al preparar, se reintenta la próxima vez
      throw ServerException(code: 'google_failed', message: '$error');
    }
    final idToken = account.authentication.idToken;
    if (idToken == null) throw const ServerException(code: 'google_failed');
    final response = await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
    );
    return UserModel.fromSupabase(response.user!);
  });

  @override
  Future<({UserModel user, bool hasSession})> signUp({
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
      throw const ServerException(code: 'user_already_exists');
    }
    return (
      user: UserModel.fromSupabase(user),
      hasSession: response.session != null,
    );
  });

  @override
  Future<void> signOut() => _guard(() => _client.auth.signOut());

  @override
  Future<void> updatePassword(String password) =>
      _guard(() => _client.auth.updateUser(UserAttributes(password: password)));

  @override
  UserModel? currentUser() {
    final user = _client.auth.currentUser;
    return user == null ? null : UserModel.fromSupabase(user);
  }

  /// Traduce los errores del SDK a las excepciones de la capa data.
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ServerException {
      rethrow;
    } on AuthRetryableFetchException catch (error) {
      throw NetworkException(error.message);
    } on AuthException catch (error) {
      throw ServerException(
        code: error.code,
        message: error.message,
        statusCode: error.statusCode,
      );
    }
  }
}
