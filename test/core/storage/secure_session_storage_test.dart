import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:proyecto_movil/core/storage/secure_session_storage.dart';

void main() {
  const key = 'sb-proyecto-auth-token';
  const session = '{"access_token":"ey.a.b","refresh_token":"r"}';

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('H-01: migra la sesión en claro al almacén cifrado y borra las copias', () async {
    SharedPreferences.setMockInitialValues({
      key: session,
      'sb-proyectoviejo-auth-token': '{"access_token":"viejo"}',
      'supabase.auth.token-code-verifier': 'verificador',
      'theme_mode': 'dark',
    });
    final storage = SecureSessionStorage(persistSessionKey: key);
    await storage.initialize();

    expect(await storage.accessToken(), session);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys(), {'theme_mode'});
  });

  test('H-01: la sesión nueva se guarda solo en el almacén cifrado', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = SecureSessionStorage(persistSessionKey: key);
    await storage.initialize();
    await storage.persistSession(session);

    expect(await storage.hasAccessToken(), isTrue);
    expect((await SharedPreferences.getInstance()).getKeys(), isEmpty);
    await storage.removePersistedSession();
    expect(await storage.hasAccessToken(), isFalse);
  });
}
