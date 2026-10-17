part of 'auth_bloc.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Aún no se ha comprobado si hay sesión guardada.
class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Sesión iniciada.
class AuthSuccess extends AuthState {
  const AuthSuccess(this.user);

  final User user;

  @override
  List<Object?> get props => [user];
}

/// Cuenta creada; falta confirmar el correo para poder entrar.
class AuthEmailConfirmationRequired extends AuthState {
  const AuthEmailConfirmationRequired({
    required this.username,
    required this.email,
  });

  final String username;
  final String email;

  @override
  List<Object?> get props => [username, email];
}

/// Sin sesión.
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// La última acción falló; no hay sesión.
class AuthFailure extends AuthState {
  const AuthFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
