import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/review/data/datasources/review_remote_datasource.dart';
import 'package:proyecto_movil/features/review/domain/entities/weekly_review.dart';
import 'package:proyecto_movil/features/review/domain/repositories/review_repository.dart';
import 'package:proyecto_movil/core/errors/supabase_guard.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  const ReviewRepositoryImpl(this._remote);

  final ReviewRemoteDataSource _remote;

  @override
  Future<Either<Failure, WeeklyReview>> getReview(DateTime now) => _run(
    () async => (await _remote.getReview(
      day:
          '${now.year.toString().padLeft(4, '0')}-'
          '${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}',
      utcOffsetMinutes: now.timeZoneOffset.inMinutes,
    )).toEntity(),
  );

  @override
  Future<Either<Failure, Unit>> postpone(String taskId, {int days = 7}) =>
      _run(() async {
        await _remote.postpone(taskId, days: days);
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> drop(String taskId) => _run(() async {
    await _remote.drop(taskId);
    return unit;
  });

  Future<Either<Failure, T>> _run<T>(Future<T> Function() action) => runGuarded(
    action,
    (error) => switch (error.code) {
      'task_not_found' =>
        'Esa tarea ya no está abierta. Desliza para actualizar.',
      'task_in_use' =>
        'Esa tarea ya tiene sesiones de foco. Pásala a la otra semana o complétala.',
      _ => 'Algo salió mal. Inténtalo de nuevo en un momento.',
    },
  );
}
