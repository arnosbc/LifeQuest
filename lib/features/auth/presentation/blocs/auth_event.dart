part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Al arrancar: recupera la sesión guardada en el dispositivo.
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class LoginRequested extends AuthEvent {
  const LoginRequested({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

class RegisterRequested extends AuthEvent {
  const RegisterRequested({
    required this.username,
    required this.email,
    required this.password,
  });

  final String username;
  final String email;
  final String password;

  @override
  List<Object?> get props => [username, email, password];
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

class GoogleLoginRequested extends AuthEvent {
  const GoogleLoginRequested();
}

/// Llegó un inicio de sesión (p. ej. al volver de Google) o su error.
class AuthSignedInChanged extends AuthEvent {
  const AuthSignedInChanged(this.result);

  final Either<Failure, User> result;

  @override
  List<Object?> get props => [result];
}
