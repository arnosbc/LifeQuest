part of 'appearance_bloc.dart';

sealed class AppearanceEvent extends Equatable {
  const AppearanceEvent();

  @override
  List<Object?> get props => [];
}

/// Leer el tema guardado (al abrir la app).
class AppearanceRequested extends AppearanceEvent {
  const AppearanceRequested();
}

class AppearanceThemeChanged extends AppearanceEvent {
  const AppearanceThemeChanged(this.theme);

  final ThemePreference theme;

  @override
  List<Object?> get props => [theme];
}
