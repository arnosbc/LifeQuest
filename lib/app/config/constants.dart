/// Configuración que llega al compilar:
/// `flutter run --dart-define-from-file=supabase.json`
abstract final class AppConstants {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  /// Clave publicable (sb_publishable_…) o la anon key heredada; ambas son
  /// públicas por diseño: los datos los protege el RLS.
  static const supabaseKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  static void ensureSupabaseConfigured() {
    if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
      throw StateError(
        'Faltan SUPABASE_URL y SUPABASE_PUBLISHABLE_KEY. Copia '
        'supabase.example.json a supabase.json, rellénalo y ejecuta: '
        'flutter run --dart-define-from-file=supabase.json',
      );
    }
  }
}
