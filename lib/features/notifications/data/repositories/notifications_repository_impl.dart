import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/notifications/data/datasources/notifications_remote_datasource.dart';
import 'package:proyecto_movil/features/notifications/domain/entities/app_notification.dart';
import 'package:proyecto_movil/features/notifications/domain/repositories/notifications_repository.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  const NotificationsRepositoryImpl(this._remote);

  final NotificationsRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<AppNotification>>> getNotifications(
    DateTime now,
  ) => _run(
    () async => (await _remote.getNotifications(
      '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}',
    )).toEntity(),
  );

  @override
  Future<Either<Failure, Unit>> markRead(List<String>? ids) => _run(() async {
    await _remote.markRead(ids);
    return unit;
  });

  Future<Either<Failure, T>> _run<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } on NetworkException {
      return const Left(
        NetworkFailure(
          'No hay conexión con el servidor. Revisa tu internet y reintenta.',
        ),
      );
    } on ServerException {
      return const Left(
        ServerFailure('No pudimos traer tus avisos. Inténtalo en un momento.'),
      );
    }
  }
}
