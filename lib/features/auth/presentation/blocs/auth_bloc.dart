import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/auth/domain/entities/sign_up_result.dart';
import 'package:proyecto_movil/features/auth/domain/entities/user.dart';
import 'package:proyecto_movil/features/auth/domain/usecases/get_current_user.dart';
import 'package:proyecto_movil/features/auth/domain/usecases/login_user.dart';
import 'package:proyecto_movil/features/auth/domain/usecases/logout_user.dart';
import 'package:proyecto_movil/features/auth/domain/usecases/register_user.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// Sesión de la app. Vive por encima del router para que este redirija según
/// haya o no sesión.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required this._getCurrentUser,
    required this._loginUser,
    required this._registerUser,
    required this._logoutUser,
  }) : super(const AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    // droppable: un segundo toque mientras carga se ignora.
    on<LoginRequested>(_onLoginRequested, transformer: droppable());
    on<RegisterRequested>(_onRegisterRequested, transformer: droppable());
    on<LogoutRequested>(_onLogoutRequested, transformer: droppable());
  }

  final GetCurrentUser _getCurrentUser;
  final LoginUser _loginUser;
  final RegisterUser _registerUser;
  final LogoutUser _logoutUser;

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final result = await _getCurrentUser(const NoParams());
    emit(
      result.match(
        (_) => const AuthUnauthenticated(),
        (user) =>
            user == null ? const AuthUnauthenticated() : AuthSuccess(user),
      ),
    );
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _loginUser(
      LoginParams(email: event.email, password: event.password),
    );
    emit(
      result.match(
        (failure) => AuthFailure(failure.message),
        (user) => AuthSuccess(user),
      ),
    );
  }

  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _registerUser(
      RegisterParams(
        username: event.username,
        email: event.email,
        password: event.password,
      ),
    );
    emit(
      result.match(
        (failure) => AuthFailure(failure.message),
        (signUp) => switch (signUp.status) {
          SignUpStatus.signedIn => AuthSuccess(signUp.user),
          SignUpStatus.emailConfirmationRequired =>
            AuthEmailConfirmationRequired(
              username: event.username,
              email: event.email,
            ),
        },
      ),
    );
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    final result = await _logoutUser(const NoParams());
    emit(
      result.match(
        (failure) => AuthFailure(failure.message),
        (_) => const AuthUnauthenticated(),
      ),
    );
  }
}
