part of 'guided_task_bloc.dart';

sealed class GuidedTaskState extends Equatable {
  const GuidedTaskState();

  @override
  List<Object?> get props => [];
}

class GuidedTaskLoading extends GuidedTaskState {
  const GuidedTaskLoading();
}

class GuidedTaskSuccess extends GuidedTaskState {
  const GuidedTaskSuccess(
    this.task, {
    this.busyStepId,
    this.reviewingStepId,
    this.review,
    this.completing = false,
    this.message,
  });

  final GuidedTask task;

  /// Paso que se está marcando.
  final String? busyStepId;
  final String? reviewingStepId;
  final GuidedStepReview? review;
  final bool completing;

  /// Aviso puntual para mostrar en un snackbar.
  final String? message;

  bool get busy => busyStepId != null || reviewingStepId != null || completing;

  @override
  List<Object?> get props => [
    task,
    busyStepId,
    reviewingStepId,
    review,
    completing,
    message,
  ];
}

class GuidedTaskFailure extends GuidedTaskState {
  const GuidedTaskFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
