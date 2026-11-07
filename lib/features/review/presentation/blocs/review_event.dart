part of 'review_bloc.dart';

sealed class ReviewEvent extends Equatable {
  const ReviewEvent();

  @override
  List<Object?> get props => [];
}

class ReviewRequested extends ReviewEvent {
  const ReviewRequested();
}

class ReviewTaskPostponed extends ReviewEvent {
  const ReviewTaskPostponed(this.taskId, {this.days = 7});

  final String taskId;

  /// 1 = mañana; 7 = la otra semana.
  final int days;

  @override
  List<Object?> get props => [taskId, days];
}

class ReviewTaskDropped extends ReviewEvent {
  const ReviewTaskDropped(this.taskId);

  final String taskId;

  @override
  List<Object?> get props => [taskId];
}
