part of 'settings_bloc.dart';

sealed class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class SettingsRequested extends SettingsEvent {
  const SettingsRequested();
}

/// El jugador cambió sus reglas (dificultad, avisos o descansos).
class GameSettingsChanged extends SettingsEvent {
  const GameSettingsChanged(this.settings);

  final GameSettings settings;

  @override
  List<Object?> get props => [settings];
}
