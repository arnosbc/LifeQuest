import 'package:equatable/equatable.dart';

import 'package:proyecto_movil/features/tasks/domain/entities/task.dart';

/// Skill, Proyecto o Meta a la que se puede vincular una tarea nueva.
class TaskLink extends Equatable {
  const TaskLink({required this.id, required this.name, this.goalId});

  final String id;
  final String name;

  /// Solo en proyectos: la Meta a la que pertenecen.
  final String? goalId;

  @override
  List<Object?> get props => [id, name, goalId];
}

/// Todo lo que muestra la pantalla Tareas, en una sola carga.
class TasksBoard extends Equatable {
  const TasksBoard({
    required this.tasks,
    this.skills = const [],
    this.projects = const [],
    this.goals = const [],
  });

  /// Ordenadas por el Daily Highlight; la primera es la priorizada.
  final List<Task> tasks;
  final List<TaskLink> skills;
  final List<TaskLink> projects;
  final List<TaskLink> goals;

  @override
  List<Object?> get props => [tasks, skills, projects, goals];
}
