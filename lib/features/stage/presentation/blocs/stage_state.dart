part of 'stage_bloc.dart';

sealed class StageState extends Equatable {
  const StageState();

  @override
  List<Object?> get props => [];
}

class StageInitial extends StageState {
  const StageInitial();
}

/// Primera carga, sin datos que mostrar todavía.
class StageLoading extends StageState {
  const StageLoading();
}

/// Datos listos. Las acciones posteriores no los quitan de la pantalla.
class StageSuccess extends StageState {
  const StageSuccess(
    this.board, {
    this.refreshing = false,
    this.busy = false,
    this.message,
  });

  final StageBoard board;

  /// Refresco en curso (deslizar hacia abajo).
  final bool refreshing;

  /// Creando, archivando o completando algo.
  final bool busy;

  /// Aviso puntual para mostrar en un snackbar.
  final String? message;

  @override
  List<Object?> get props => [board, refreshing, busy, message];
}

/// La primera carga falló; no hay datos que mostrar.
class StageFailure extends StageState {
  const StageFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
