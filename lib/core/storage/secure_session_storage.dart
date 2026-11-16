import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// H-01 (OWASP M9): la sesión de Supabase (access y refresh token) se guarda
/// cifrada con AES-GCM y una llave protegida por el Android Keystore
/// (`flutter_secure_storage`), no en SharedPreferences en texto plano.
class SecureSessionStorage extends LocalStorage {
  SecureSessionStorage({
    required this.persistSessionKey,
    this._storage = const FlutterSecureStorage(),
  });

  final String persistSessionKey;
  final FlutterSecureStorage _storage;

  /// Sesiones que la versión anterior dejaba en texto plano
  /// (`sb-<proyecto>-auth-token` de supabase_flutter).
  static bool _isLegacySession(String key) =>
      (key.startsWith('sb-') && key.endsWith('-auth-token')) ||
      key == 'supabase.auth.token-code-verifier';

  @override
  Future<void> initialize() async {
    // Migración única: se pasa la sesión al almacén cifrado (así nadie tiene
    // que volver a entrar) y se borran todas las copias en claro, también las
    // de proyectos de Supabase anteriores.
    final prefs = await SharedPreferences.getInstance();
    final legacy = prefs.getString(persistSessionKey);
    if (legacy != null && !await _storage.containsKey(key: persistSessionKey)) {
      await _storage.write(key: persistSessionKey, value: legacy);
    }
    for (final key in prefs.getKeys().where(_isLegacySession).toList()) {
      await prefs.remove(key);
    }
  }

  @override
  Future<bool> hasAccessToken() => _storage.containsKey(key: persistSessionKey);

  @override
  Future<String?> accessToken() => _storage.read(key: persistSessionKey);

  @override
  Future<void> persistSession(String persistSessionString) =>
      _storage.write(key: persistSessionKey, value: persistSessionString);

  @override
  Future<void> removePersistedSession() =>
      _storage.delete(key: persistSessionKey);
}

/// H-01: el verificador PKCE del inicio con Google también va cifrado.
class SecurePkceStorage extends GotrueAsyncStorage {
  const SecurePkceStorage({this._storage = const FlutterSecureStorage()});

  final FlutterSecureStorage _storage;

  @override
  Future<String?> getItem({required String key}) => _storage.read(key: key);

  @override
  Future<void> setItem({required String key, required String value}) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> removeItem({required String key}) => _storage.delete(key: key);
}
