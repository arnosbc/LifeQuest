part of 'settings_bloc.dart';

sealed class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => [];
}

class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

class SettingsLoading extends SettingsState {
  const SettingsLoading();
}

class SettingsSuccess extends SettingsState {
  const SettingsSuccess(this.overview, {this.saving = false, this.message});

  final SettingsOverview overview;

  /// Guardando un cambio.
  final bool saving;

  /// Aviso puntual para mostrar en un snackbar.
  final String? message;

  @override
  List<Object?> get props => [overview, saving, message];
}

/// La carga falló; no hay datos que mostrar.
class SettingsFailure extends SettingsState {
  const SettingsFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
