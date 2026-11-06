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

/// El usuario puso (o movió) una tarea en la agenda de hoy.
class HomeTaskScheduled extends HomeEvent {
  const HomeTaskScheduled(this.taskId, this.at);

  final String taskId;
  final DateTime at;

  @override
  List<Object?> get props => [taskId, at];
}

/// El usuario marcó un hábito bueno como cumplido hoy.
class HomeHabitCompleted extends HomeEvent {
  const HomeHabitCompleted(this.habitId);

  final String habitId;

  @override
  List<Object?> get props => [habitId];
}
