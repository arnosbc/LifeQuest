part of 'habits_bloc.dart';

sealed class HabitsEvent extends Equatable {
  const HabitsEvent();

  @override
  List<Object?> get props => [];
}

/// Cargar o refrescar la pantalla Hábitos.
class HabitsRequested extends HabitsEvent {
  const HabitsRequested();
}

/// El usuario guardó un hábito nuevo.
class HabitCreated extends HabitsEvent {
  const HabitCreated(this.habit);

  final NewHabit habit;

  @override
  List<Object?> get props => [habit];
}

/// El usuario cumplió hoy un hábito bueno.
class GoodHabitCompleted extends HabitsEvent {
  const GoodHabitCompleted(this.habitId);

  final String habitId;

  @override
  List<Object?> get props => [habitId];
}

/// El usuario registró un evento de un hábito malo.
class BadHabitRegistered extends HabitsEvent {
  const BadHabitRegistered(this.habitId);

  final String habitId;

  @override
  List<Object?> get props => [habitId];
}
