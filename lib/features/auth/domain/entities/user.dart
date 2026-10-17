import 'package:equatable/equatable.dart';

/// Usuario con sesión iniciada.
class User extends Equatable {
  const User({required this.id, required this.email, this.username});

  final String id;
  final String email;

  /// Nombre elegido en el registro; puede faltar en cuentas antiguas.
  final String? username;

  /// Nombre a mostrar: el de usuario o, si falta, el del correo.
  String get displayName {
    if (username != null && username!.trim().isNotEmpty) return username!;
    final emailName = email.split('@').first;
    return emailName.isEmpty
        ? 'Héroe'
        : emailName[0].toUpperCase() + emailName.substring(1);
  }

  @override
  List<Object?> get props => [id, email, username];
}
