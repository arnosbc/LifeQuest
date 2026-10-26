import 'package:equatable/equatable.dart';

import 'package:proyecto_movil/features/missions/domain/entities/mission.dart';

/// Datos que el usuario escribe al crear una misión. Sin recompensa: la
/// calcula el servidor.
class NewMission extends Equatable {
  const NewMission({
    required this.title,
    this.description,
    this.priority = MissionPriority.low,
    this.dueDate,
    this.skillId,
    this.projectId,
    this.goalId,
    this.subtasks = const [],
  });

  final String title;
  final String? description;
  final MissionPriority priority;
  final DateTime? dueDate;
  final String? skillId;
  final String? projectId;
  final String? goalId;
  final List<String> subtasks;

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
  ];
}
