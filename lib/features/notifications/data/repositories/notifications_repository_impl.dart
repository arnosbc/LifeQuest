import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/notifications/data/datasources/notifications_local_datasource.dart';
import 'package:proyecto_movil/features/notifications/data/datasources/notifications_remote_datasource.dart';
import 'package:proyecto_movil/features/notifications/domain/entities/app_notification.dart';
import 'package:proyecto_movil/features/notifications/domain/repositories/notifications_repository.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  const NotificationsRepositoryImpl(this._remote, this._local);

  final NotificationsRemoteDataSource _remote;
  final NotificationsLocalDataSource _local;

  @override
  Future<Either<Failure, List<AppNotification>>> getNotifications(
    DateTime now,
  ) => _run(() async => (await _remote.getNotifications(_day(now))).toEntity());

  @override
  Future<Either<Failure, Unit>> markRead(List<String>? ids) => _run(() async {
    await _remote.markRead(ids);
    return unit;
  });

  @override
  Future<Either<Failure, Unit>> enableOnDevice(void Function() onOpened) =>
      _run(() async {
        await _local.initialize(onOpened: onOpened);
        // Sin permiso no se registra nada: no tendría dónde mostrarse.
        if (!await _local.requestPermission()) return unit;
        if (await _local.readDeviceToken() == null) {
          await _local.saveDeviceToken(await _remote.registerDevice());
        }
        await _local.startPeriodicCheck();
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> disableOnDevice() => _run(() async {
    await _local.stopPeriodicCheck();
    final token = await _local.readDeviceToken();
    if (token == null) return unit;
    await _local.saveDeviceToken(null);
    try {
      await _remote.unregisterDevice(token);
    } on Exception {
      // El código ya no está en el móvil: sin él nadie puede usarlo.
    }
    return unit;
  });

  @override
  Future<Either<Failure, int>> deliverToDevice(DateTime now) => _run(() async {
    final token = await _local.readDeviceToken();
    if (token == null) return 0;
    try {
      final items = (await _remote.takeDeviceNotifications(
        token,
        _day(now),
        '${_two(now.hour)}:${_two(now.minute)}',
      )).toEntity();
      await _local.show(items);
      return items.length;
    } on ServerException catch (error) {
      if (error.code != 'device_not_registered') rethrow;
      // Se dio de baja en el servidor: al próximo inicio de sesión se registra
      // otra vez.
      await _local.saveDeviceToken(null);
      return 0;
    }
  });

  static String _two(int n) => n.toString().padLeft(2, '0');

  static String _day(DateTime now) =>
      '${now.year.toString().padLeft(4, '0')}-${_two(now.month)}-'
      '${_two(now.day)}';

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
    } on CacheException {
      return const Left(
        CacheFailure('No pudimos usar las notificaciones de este dispositivo.'),
      );
    }
  }
}
