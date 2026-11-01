part of 'appearance_bloc.dart';

sealed class AppearanceState extends Equatable {
  const AppearanceState();

  /// Mientras no se lee la preferencia, se sigue al sistema.
  ThemePreference get theme => ThemePreference.system;

  @override
  List<Object?> get props => [];
}

class AppearanceInitial extends AppearanceState {
  const AppearanceInitial();
}

class AppearanceSuccess extends AppearanceState {
  const AppearanceSuccess(this.theme, {this.message});

  @override
  final ThemePreference theme;

  /// Aviso puntual para un snackbar (p. ej. no se pudo guardar).
  final String? message;

  @override
  List<Object?> get props => [theme, message];
}
