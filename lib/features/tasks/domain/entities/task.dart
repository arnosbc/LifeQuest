import 'package:equatable/equatable.dart';

/// Escala única de urgencia de la app (`urgency_level`).
enum TaskPriority { low, medium, high }

/// Grupo del Daily Highlight (RF-089), en el orden en que se muestran.
enum TaskBucket { urgent, high, medium, low, pending }

/// Tarea abierta (tarea sin padre). La recompensa la fija el servidor.
class Task extends Equatable {
  const Task({
    required this.id,
    required this.title,
    required this.priority,
    required this.bucket,
    required this.xpReward,
    required this.coinReward,
    this.description,
    this.dueDate,
    this.skillName,
    this.projectTitle,
    this.goalTitle,
    this.subtasksTotal = 0,
    this.subtasksDone = 0,
    this.scheduledAt,
    this.estimatedMinutes,
    this.reminderMinutes,
    this.repeatRule,
    this.focusMinutes = 0,
  });

  final String id;
  final String title;
  final String? description;
  final TaskPriority priority;
  final TaskBucket bucket;
  final DateTime? dueDate;
  final int xpReward;
  final int coinReward;
  final String? skillName;
  final String? projectTitle;
  final String? goalTitle;
  final int subtasksTotal;
  final int subtasksDone;

  /// Bloque en la agenda (hora local).
  final DateTime? scheduledAt;
  final int? estimatedMinutes;

  /// Aviso N minutos antes de [scheduledAt].
  final int? reminderMinutes;

  /// `daily`, `weekdays`, `weekly:1,3` o `monthly:15` (032_scheduling.sql).
  final String? repeatRule;

  /// Minutos medidos en Foco.
  final int focusMinutes;

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    priority,
    bucket,
    dueDate,
    xpReward,
    coinReward,
    skillName,
    projectTitle,
    goalTitle,
    subtasksTotal,
    subtasksDone,
    scheduledAt,
    estimatedMinutes,
    reminderMinutes,
    repeatRule,
    focusMinutes,
  ];
}
