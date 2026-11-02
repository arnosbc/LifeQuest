part of 'guided_task_bloc.dart';

sealed class GuidedTaskEvent extends Equatable {
  const GuidedTaskEvent();

  @override
  List<Object?> get props => [];
}

class GuidedTaskRequested extends GuidedTaskEvent {
  const GuidedTaskRequested(this.taskId);

  final String taskId;

  @override
  List<Object?> get props => [taskId];
}

/// Marcar o desmarcar un paso.
class GuidedStepToggled extends GuidedTaskEvent {
  const GuidedStepToggled(this.stepId);

  final String stepId;

  @override
  List<Object?> get props => [stepId];
}

/// Dividir la tarea en pasos escritos por el usuario.
class GuidedStepsSet extends GuidedTaskEvent {
  const GuidedStepsSet(this.steps);

  final List<String> steps;

  @override
  List<Object?> get props => [steps];
}

class GuidedStepReviewRequested extends GuidedTaskEvent {
  const GuidedStepReviewRequested({
    required this.stepId,
    required this.evidence,
  });

  final String stepId;
  final List<GuidedStepEvidence> evidence;

  @override
  List<Object?> get props => [stepId, evidence];
}

/// Completar la tarea sin pasar por todos los pasos.
class GuidedTaskCompleted extends GuidedTaskEvent {
  const GuidedTaskCompleted();
}
