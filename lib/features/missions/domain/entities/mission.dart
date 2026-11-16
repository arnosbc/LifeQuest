import 'package:equatable/equatable.dart';

/// Escala única de urgencia de la app (`urgency_level`).
enum MissionPriority { low, medium, high }

/// Grupo del Daily Highlight (RF-089), en el orden en que se muestran.
enum MissionBucket { urgent, high, medium, low, pending }

/// Cada cuánto vuelve la tarea al completarla (073). El nombre es el del SQL.
enum MissionRepeat { daily, weekdays, weekly, monthly }

/// Misión abierta (tarea sin padre). La recompensa la fija el servidor.
class Mission extends Equatable {
  const Mission({
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
    this.repeat,
  });

  final String id;
  final String title;
  final String? description;
  final MissionPriority priority;
  final MissionBucket bucket;
  final DateTime? dueDate;
  final int xpReward;
  final int coinReward;
  final String? skillName;
  final String? projectTitle;
  final String? goalTitle;
  final int subtasksTotal;
  final int subtasksDone;

  /// null = no se repite.
  final MissionRepeat? repeat;

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
    repeat,
  ];
}
