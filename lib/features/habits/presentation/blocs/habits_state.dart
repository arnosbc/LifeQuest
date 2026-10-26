part of 'habits_bloc.dart';

sealed class HabitsState extends Equatable {
  const HabitsState();

  @override
  List<Object?> get props => [];
}

class HabitsInitial extends HabitsState {
  const HabitsInitial();
}

/// Primera carga, sin datos que mostrar todavía.
class HabitsLoading extends HabitsState {
  const HabitsLoading();
}

/// Datos listos. Las acciones posteriores no los quitan de la pantalla.
class HabitsSuccess extends HabitsState {
  const HabitsSuccess(
    this.board, {
    this.refreshing = false,
    this.saving = false,
    this.busyHabitId,
    this.message,
  });

  final HabitsBoard board;

  /// Refresco en curso (deslizar hacia abajo).
  final bool refreshing;

  /// Creando un hábito.
  final bool saving;

  /// Hábito que se está registrando.
  final String? busyHabitId;

  /// Aviso puntual para mostrar en un snackbar.
  final String? message;

  @override
  List<Object?> get props => [board, refreshing, saving, busyHabitId, message];
}

/// La primera carga falló; no hay datos que mostrar.
class HabitsFailure extends HabitsState {
  const HabitsFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
