import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:proyecto_movil/core/storage/secure_session_storage.dart';

/// Configuración que llega al compilar:
/// `flutter run --dart-define-from-file=supabase.json`
abstract final class AppConstants {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  /// Clave publicable (sb_publishable_…) o la anon key heredada; ambas son
  /// públicas por diseño: los datos los protege el RLS.
  static const supabaseKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  /// Sesión cifrada con Keystore/Keychain, nunca en texto plano (H-01).
  static FlutterAuthClientOptions get authOptions => FlutterAuthClientOptions(
    localStorage: SecureSessionStorage(
      SecureSessionStorage.keyFor(supabaseUrl),
    ),
  );

  static void ensureSupabaseConfigured() {
    // H-06: solo HTTPS, también si alguien compila con un supabase.json mal hecho.
    if (supabaseUrl.isNotEmpty && !supabaseUrl.startsWith('https://')) {
      throw StateError('SUPABASE_URL debe empezar por https://');
    }
    if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
      throw StateError(
        'Faltan SUPABASE_URL y SUPABASE_PUBLISHABLE_KEY. Copia '
        'supabase.example.json a supabase.json, rellénalo y ejecuta: '
        'flutter run --dart-define-from-file=supabase.json',
      );
    }
  }
}
