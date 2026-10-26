import 'package:equatable/equatable.dart';

import 'package:proyecto_movil/features/missions/domain/entities/mission.dart';

/// Skill, Proyecto o Meta a la que se puede vincular una misión nueva.
class MissionLink extends Equatable {
  const MissionLink({required this.id, required this.name, this.goalId});

  final String id;
  final String name;

  /// Solo en proyectos: la Meta a la que pertenecen.
  final String? goalId;

  @override
  List<Object?> get props => [id, name, goalId];
}

/// Todo lo que muestra la pantalla Misiones, en una sola carga.
class MissionsBoard extends Equatable {
  const MissionsBoard({
    required this.missions,
    this.skills = const [],
    this.projects = const [],
    this.goals = const [],
  });

  /// Ordenadas por el Daily Highlight; la primera es la priorizada.
  final List<Mission> missions;
  final List<MissionLink> skills;
  final List<MissionLink> projects;
  final List<MissionLink> goals;

  @override
  List<Object?> get props => [missions, skills, projects, goals];
}
