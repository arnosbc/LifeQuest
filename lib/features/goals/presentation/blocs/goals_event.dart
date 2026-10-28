part of 'goals_bloc.dart';

sealed class GoalsEvent extends Equatable {
  const GoalsEvent();

  @override
  List<Object?> get props => [];
}

/// Cargar o refrescar Objetivos.
class GoalsRequested extends GoalsEvent {
  const GoalsRequested();
}

/// El usuario lanzó un ataque (completar tarea o proyecto) contra un jefe.
class BossAttacked extends GoalsEvent {
  const BossAttacked({required this.goalId, required this.attack});

  final String goalId;
  final BossAttack attack;

  @override
  List<Object?> get props => [goalId, attack];
}

class GoalArchived extends GoalsEvent {
  const GoalArchived(this.goalId);

  final String goalId;

  @override
  List<Object?> get props => [goalId];
}
