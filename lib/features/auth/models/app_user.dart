import 'package:supabase_flutter/supabase_flutter.dart' show User;

/// Usuario con sesión iniciada, tal como lo usa la app.
class AppUser {
  const AppUser({required this.id, required this.email, this.username});

  /// Construye el usuario a partir del de Supabase Auth (`auth.users`).
  factory AppUser.fromSupabase(User user) {
    final username = user.userMetadata?['username'];
    return AppUser(
      id: user.id,
      email: user.email ?? '',
      username: username is String && username.trim().isNotEmpty
          ? username.trim()
          : null,
    );
  }

  final String id;
  final String email;

  /// Nombre elegido en el registro; puede faltar en cuentas antiguas.
  final String? username;

  /// Nombre a mostrar: el de usuario o, si falta, el del correo.
  String get displayName {
    if (username != null) return username!;
    final emailName = email.split('@').first;
    return emailName.isEmpty
        ? 'Héroe'
        : emailName[0].toUpperCase() + emailName.substring(1);
  }
}
