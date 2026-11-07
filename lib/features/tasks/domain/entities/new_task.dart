import 'package:equatable/equatable.dart';

import 'package:proyecto_movil/features/tasks/domain/entities/task.dart';

/// Datos que el usuario escribe al crear una tarea. Sin recompensa: la
/// calcula el servidor.
class NewTask extends Equatable {
  const NewTask({
    required this.title,
    this.description,
    this.priority = TaskPriority.low,
    this.dueDate,
    this.skillId,
    this.projectId,
    this.goalId,
    this.subtasks = const [],
    this.scheduledAt,
    this.estimatedMinutes,
    this.reminderMinutes,
    this.repeatRule,
  });

  final String title;
  final String? description;
  final TaskPriority priority;
  final DateTime? dueDate;
  final String? skillId;
  final String? projectId;
  final String? goalId;
  final List<String> subtasks;
  final DateTime? scheduledAt;
  final int? estimatedMinutes;
  final int? reminderMinutes;
  final String? repeatRule;

  @override
  List<Object?> get props => [
    title,
    description,
    priority,
    dueDate,
    skillId,
    projectId,
    goalId,
    subtasks,
    scheduledAt,
    estimatedMinutes,
    reminderMinutes,
    repeatRule,
  ];
}
