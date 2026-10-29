part of 'stage_bloc.dart';

sealed class StageEvent extends Equatable {
  const StageEvent();

  @override
  List<Object?> get props => [];
}

/// Cargar o refrescar Stage.
class StageRequested extends StageEvent {
  const StageRequested();
}

class StageProjectCreated extends StageEvent {
  const StageProjectCreated(this.project);

  final NewProject project;

  @override
  List<Object?> get props => [project];
}

class StageGoalCreated extends StageEvent {
  const StageGoalCreated(this.goal);

  final NewGoal goal;

  @override
  List<Object?> get props => [goal];
}

/// El usuario completó una misión desde su proyecto.
class StageTaskCompleted extends StageEvent {
  const StageTaskCompleted(this.taskId);

  final String taskId;

  @override
  List<Object?> get props => [taskId];
}

class StageResourceCreated extends StageEvent {
  const StageResourceCreated(this.resource);

  final NewResource resource;

  @override
  List<Object?> get props => [resource];
}

/// Abrir un documento guardado (necesita un enlace temporal del servidor).
class StageResourceOpened extends StageEvent {
  const StageResourceOpened(this.resource);

  final StageResource resource;

  @override
  List<Object?> get props => [resource];
}

class StageItemArchived extends StageEvent {
  const StageItemArchived({required this.kind, required this.id});

  final StageItemKind kind;
  final String id;

  @override
  List<Object?> get props => [kind, id];
}

class StageProjectCompleted extends StageEvent {
  const StageProjectCompleted(this.projectId);

  final String projectId;

  @override
  List<Object?> get props => [projectId];
}
