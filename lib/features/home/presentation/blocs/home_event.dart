part of 'home_bloc.dart';

sealed class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

/// Cargar o refrescar los datos del Home.
class HomeRequested extends HomeEvent {
  const HomeRequested();
}

/// El usuario marcó un hábito bueno como cumplido hoy.
class HomeHabitCompleted extends HomeEvent {
  const HomeHabitCompleted(this.habitId);

  final String habitId;

  @override
  List<Object?> get props => [habitId];
}

/// El usuario abrió el cofre del día.
class HomeChestClaimed extends HomeEvent {
  const HomeChestClaimed();
}
