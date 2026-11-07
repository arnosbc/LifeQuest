import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/review/domain/entities/weekly_review.dart';
import 'package:proyecto_movil/features/review/domain/repositories/review_repository.dart';

/// Lee la semana en curso.
class GetWeeklyReview implements UseCase<WeeklyReview, DateTime> {
  const GetWeeklyReview(this._repository);

  final ReviewRepository _repository;

  @override
  Future<Either<Failure, WeeklyReview>> call(DateTime now) =>
      _repository.getReview(now);
}
