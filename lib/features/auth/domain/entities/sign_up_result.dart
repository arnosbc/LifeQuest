import 'package:equatable/equatable.dart';

import 'package:proyecto_movil/features/auth/domain/entities/user.dart';

/// Cómo terminó el registro.
enum SignUpStatus {
  /// La cuenta quedó creada y con sesión iniciada.
  signedIn,

  /// El proyecto pide confirmar el correo antes de iniciar sesión.
  emailConfirmationRequired,
}

class SignUpResult extends Equatable {
  const SignUpResult({required this.status, required this.user});

  final SignUpStatus status;
  final User user;

  @override
  List<Object?> get props => [status, user];
}
