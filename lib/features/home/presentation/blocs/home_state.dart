part of 'home_bloc.dart';

sealed class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {
  const HomeInitial();
}

/// Primera carga, sin datos que mostrar todavía.
class HomeLoading extends HomeState {
  const HomeLoading();
}

/// Datos listos. Las acciones posteriores no los quitan de la pantalla.
class HomeSuccess extends HomeState {
  const HomeSuccess(
    this.dashboard, {
    this.refreshing = false,
    this.busyHabitId,
    this.claimingChest = false,
    this.message,
  });

  final HomeDashboard dashboard;

  /// Refresco en curso (deslizar hacia abajo).
  final bool refreshing;

  /// Hábito que se está registrando.
  final String? busyHabitId;

  /// Abriendo el cofre del día.
  final bool claimingChest;

  /// Aviso puntual para mostrar en un snackbar (p. ej. un error al registrar).
  final String? message;

  @override
  List<Object?> get props => [
    dashboard,
    refreshing,
    busyHabitId,
    claimingChest,
    message,
  ];
}

/// La primera carga falló; no hay datos que mostrar.
class HomeFailure extends HomeState {
  const HomeFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
