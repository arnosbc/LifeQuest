import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Sesión de Supabase (access y refresh token) cifrada con una llave del
/// Android Keystore / Keychain, en lugar del texto plano de SharedPreferences
/// que usa supabase_flutter por defecto (OWASP M9, hallazgo H-01).
class SecureSessionStorage extends LocalStorage {
  const SecureSessionStorage(this.key, {FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  /// Misma clave que usa supabase_flutter: `sb-<proyecto>-auth-token`.
  final String key;
  final FlutterSecureStorage _storage;

  /// Clave por defecto de supabase_flutter para [url].
  static String keyFor(String url) =>
      'sb-${Uri.parse(url).host.split('.').first}-auth-token';

  @override
  Future<void> initialize() async {
    // Versiones anteriores la dejaron en texto plano: se mueve y se borra,
    // así nadie tiene que volver a iniciar sesión.
    final prefs = await SharedPreferences.getInstance();
    final old = prefs.getString(key);
    if (old == null) return;
    await _storage.write(key: key, value: old);
    await prefs.remove(key);
  }

  @override
  Future<bool> hasAccessToken() => _storage.containsKey(key: key);

  @override
  Future<String?> accessToken() => _storage.read(key: key);

  @override
  Future<void> removePersistedSession() => _storage.delete(key: key);

  @override
  Future<void> persistSession(String persistSessionString) =>
      _storage.write(key: key, value: persistSessionString);
}
