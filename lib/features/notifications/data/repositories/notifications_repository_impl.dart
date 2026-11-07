import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/notifications/data/datasources/notifications_remote_datasource.dart';
import 'package:proyecto_movil/features/notifications/domain/entities/app_notification.dart';
import 'package:proyecto_movil/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:proyecto_movil/core/errors/supabase_guard.dart';

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

  Future<Either<Failure, T>> _run<T>(Future<T> Function() action) => runGuarded(
    action,
    (_) => 'No pudimos traer tus avisos. Inténtalo en un momento.',
  );
}
