import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:proyecto_movil/core/storage/secure_session_storage.dart';

// Seguridad (tarea OWASP): H-01 sesión cifrada.
void main() {
  const key = 'sb-demo-auth-token';

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test(
    'H-01: la sesión vieja en texto plano se mueve al almacén cifrado',
    () async {
      SharedPreferences.setMockInitialValues({key: '{"access_token":"t"}'});
      const storage = SecureSessionStorage(key);
      await storage.initialize();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(key), isNull, reason: 'no queda en texto plano');
      expect(await storage.hasAccessToken(), isTrue);
      expect(await storage.accessToken(), '{"access_token":"t"}');
    },
  );

  test('H-01: guardar y borrar la sesión no toca SharedPreferences', () async {
    SharedPreferences.setMockInitialValues({});
    const storage = SecureSessionStorage(key);
    await storage.initialize();
    await storage.persistSession('s');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys(), isEmpty);
    expect(await storage.accessToken(), 's');
    await storage.removePersistedSession();
    expect(await storage.hasAccessToken(), isFalse);
  });

  test('la clave es la misma que usa supabase_flutter', () {
    expect(
      SecureSessionStorage.keyFor('https://admy123.supabase.co'),
      'sb-admy123-auth-token',
    );
  });
}
