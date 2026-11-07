part of 'review_bloc.dart';

sealed class ReviewState extends Equatable {
  const ReviewState();

  @override
  List<Object?> get props => [];
}

class ReviewInitial extends ReviewState {
  const ReviewInitial();
}

class ReviewLoading extends ReviewState {
  const ReviewLoading();
}

class ReviewSuccess extends ReviewState {
  const ReviewSuccess(this.review, {this.busyTaskId, this.message});

  final WeeklyReview review;
  final String? busyTaskId;
  final String? message;

  @override
  List<Object?> get props => [review, busyTaskId, message];
}

class ReviewFailure extends ReviewState {
  const ReviewFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
