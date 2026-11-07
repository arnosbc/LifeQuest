import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart' show Either, Left, Unit;

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/review/domain/entities/weekly_review.dart';
import 'package:proyecto_movil/features/review/domain/usecases/drop_task.dart';
import 'package:proyecto_movil/features/review/domain/usecases/get_weekly_review.dart';
import 'package:proyecto_movil/features/review/domain/usecases/postpone_task.dart';

part 'review_event.dart';
part 'review_state.dart';

class ReviewBloc extends Bloc<ReviewEvent, ReviewState> {
  ReviewBloc({
    required this._getReview,
    required this._postpone,
    required this._drop,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       super(const ReviewInitial()) {
    on<ReviewRequested>(_onRequested, transformer: droppable());
    on<ReviewTaskPostponed>(
      (e, emit) => _act(
        emit,
        e.taskId,
        () => _postpone((taskId: e.taskId, days: e.days)),
        e.days == 1 ? 'Queda para mañana.' : 'Pasó a la semana que viene.',
      ),
      transformer: droppable(),
    );
    on<ReviewTaskDropped>(
      (e, emit) => _act(
        emit,
        e.taskId,
        () => _drop(e.taskId),
        'Soltada. Una decisión menos.',
      ),
      transformer: droppable(),
    );
  }

  final GetWeeklyReview _getReview;
  final PostponeTask _postpone;
  final DropTask _drop;
  final DateTime Function() _clock;

  Future<void> _onRequested(
    ReviewRequested event,
    Emitter<ReviewState> emit,
  ) async {
    final current = state;
    if (current is! ReviewSuccess) emit(const ReviewLoading());
    final result = await _getReview(_clock());
    emit(
      result.match(
        (f) => current is ReviewSuccess
            ? ReviewSuccess(current.review, message: f.message)
            : ReviewFailure(f.message),
        ReviewSuccess.new,
      ),
    );
  }

  Future<void> _act(
    Emitter<ReviewState> emit,
    String taskId,
    Future<Either<Failure, Unit>> Function() action,
    String done,
  ) async {
    final current = state;
    if (current is! ReviewSuccess || current.busyTaskId != null) return;
    emit(ReviewSuccess(current.review, busyTaskId: taskId));
    if (await action() case Left(value: final failure)) {
      emit(ReviewSuccess(current.review, message: failure.message));
      return;
    }
    final reloaded = await _getReview(_clock());
    emit(
      reloaded.match(
        (f) => ReviewSuccess(current.review, message: f.message),
        (review) => ReviewSuccess(review, message: done),
      ),
    );
  }
}
