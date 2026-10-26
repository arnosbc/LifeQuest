part of 'missions_bloc.dart';

sealed class MissionsState extends Equatable {
  const MissionsState();

  @override
  List<Object?> get props => [];
}

class MissionsInitial extends MissionsState {
  const MissionsInitial();
}

/// Primera carga, sin datos que mostrar todavía.
class MissionsLoading extends MissionsState {
  const MissionsLoading();
}

/// Datos listos. Las acciones posteriores no los quitan de la pantalla.
class MissionsSuccess extends MissionsState {
  const MissionsSuccess(
    this.board, {
    this.refreshing = false,
    this.saving = false,
    this.busyMissionId,
    this.message,
    this.focusRequested = false,
  });

  final MissionsBoard board;

  /// Refresco en curso (deslizar hacia abajo).
  final bool refreshing;

  /// Creando una misión.
  final bool saving;

  /// Misión que se está completando.
  final String? busyMissionId;

  /// Aviso puntual para mostrar en un snackbar.
  final String? message;

  /// La misión se creó con "Crear e iniciar Focus": abrir la Mazmorra.
  final bool focusRequested;

  @override
  List<Object?> get props => [
    board,
    refreshing,
    saving,
    busyMissionId,
    message,
    focusRequested,
  ];
}

/// La primera carga falló; no hay datos que mostrar.
class MissionsFailure extends MissionsState {
  const MissionsFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
