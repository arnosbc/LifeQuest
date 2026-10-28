part of 'goals_bloc.dart';

sealed class GoalsState extends Equatable {
  const GoalsState();

  @override
  List<Object?> get props => [];
}

class GoalsInitial extends GoalsState {
  const GoalsInitial();
}

/// Primera carga, sin datos que mostrar todavía.
class GoalsLoading extends GoalsState {
  const GoalsLoading();
}

/// Datos listos. Las acciones posteriores no los quitan de la pantalla.
class GoalsSuccess extends GoalsState {
  const GoalsSuccess(
    this.board, {
    this.refreshing = false,
    this.busyKey,
    this.message,
  });

  final GoalsBoard board;
  final bool refreshing;

  /// Ataque o Meta que se está procesando.
  final String? busyKey;

  /// Aviso puntual para mostrar en un snackbar.
  final String? message;

  @override
  List<Object?> get props => [board, refreshing, busyKey, message];
}

/// La primera carga falló; no hay datos que mostrar.
class GoalsFailure extends GoalsState {
  const GoalsFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
