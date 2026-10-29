import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/notifications/data/datasources/notifications_local_datasource.dart';
import 'package:proyecto_movil/features/notifications/data/datasources/notifications_remote_datasource.dart';
import 'package:proyecto_movil/features/notifications/data/models/notifications_model.dart';
import 'package:proyecto_movil/features/notifications/data/repositories/notifications_repository_impl.dart';
import 'package:proyecto_movil/features/notifications/domain/entities/app_notification.dart';

class _MockRemote extends Mock implements NotificationsRemoteDataSource {}

class _MockLocal extends Mock implements NotificationsLocalDataSource {}

void main() {
  late _MockRemote remote;
  late _MockLocal local;
  late NotificationsRepositoryImpl repository;

  setUpAll(() => registerFallbackValue(<AppNotification>[]));

  setUp(() {
    remote = _MockRemote();
    local = _MockLocal();
    repository = NotificationsRepositoryImpl(remote, local);
    when(
      () => local.initialize(onOpened: any(named: 'onOpened')),
    ).thenAnswer((_) async {});
    when(() => local.saveDeviceToken(any())).thenAnswer((_) async {});
    when(() => local.startPeriodicCheck()).thenAnswer((_) async {});
    when(() => local.stopPeriodicCheck()).thenAnswer((_) async {});
    when(() => local.show(any())).thenAnswer((_) async {});
  });

  group('enableOnDevice', () {
    test(
      'registra el dispositivo una sola vez y programa la revisión',
      () async {
        when(() => local.requestPermission()).thenAnswer((_) async => true);
        when(() => local.readDeviceToken()).thenAnswer((_) async => null);
        when(() => remote.registerDevice()).thenAnswer((_) async => 'abc');

        expect(await repository.enableOnDevice(() {}), const Right(unit));
        verify(() => local.saveDeviceToken('abc')).called(1);
        verify(() => local.startPeriodicCheck()).called(1);

        when(() => local.readDeviceToken()).thenAnswer((_) async => 'abc');
        await repository.enableOnDevice(() {});
        verify(() => remote.registerDevice()).called(1);
      },
    );

    test('sin permiso no registra ni programa nada', () async {
      when(() => local.requestPermission()).thenAnswer((_) async => false);

      expect(await repository.enableOnDevice(() {}), const Right(unit));
      verifyNever(() => remote.registerDevice());
      verifyNever(() => local.startPeriodicCheck());
    });

    test('si el plugin falla, devuelve CacheFailure', () async {
      when(
        () => local.requestPermission(),
      ).thenThrow(const CacheException('sin plugin'));

      expect(
        (await repository.enableOnDevice(() {})).getLeft().toNullable(),
        isA<CacheFailure>(),
      );
    });
  });

  test('disableOnDevice detiene la revisión y da de baja el código', () async {
    when(() => local.readDeviceToken()).thenAnswer((_) async => 'abc');
    when(
      () => remote.unregisterDevice('abc'),
    ).thenThrow(const NetworkException('sin red'));

    expect(await repository.disableOnDevice(), const Right(unit));
    verify(() => local.stopPeriodicCheck()).called(1);
    verify(() => local.saveDeviceToken(null)).called(1);
  });

  group('deliverToDevice', () {
    final now = DateTime(2026, 10, 29, 7, 5);

    test('pide con fecha y hora local y muestra lo que llega', () async {
      when(() => local.readDeviceToken()).thenAnswer((_) async => 'abc');
      when(
        () => remote.takeDeviceNotifications('abc', '2026-10-29', '07:05'),
      ).thenAnswer(
        (_) async => NotificationsModel.fromJson({
          'items': [
            {
              'id': 'n1',
              'type': 'critical',
              'title': 'Un proyecto necesita tu atención',
              'message': '«Tesis» va con el tiempo justo.',
              'created_at': '2026-10-29T12:00:00+00:00',
            },
          ],
        }),
      );

      expect(await repository.deliverToDevice(now), const Right(1));
      final shown =
          verify(() => local.show(captureAny())).captured.single
              as List<AppNotification>;
      expect(shown.single.kind, NotificationKind.critical);
      expect(shown.single.read, isFalse);
    });

    test('sin código no consulta al servidor', () async {
      when(() => local.readDeviceToken()).thenAnswer((_) async => null);

      expect(await repository.deliverToDevice(now), const Right(0));
      verifyZeroInteractions(remote);
    });

    test('si el servidor ya no conoce el código, lo olvida', () async {
      when(() => local.readDeviceToken()).thenAnswer((_) async => 'viejo');
      when(
        () => remote.takeDeviceNotifications(any(), any(), any()),
      ).thenThrow(const ServerException(code: 'device_not_registered'));

      expect(await repository.deliverToDevice(now), const Right(0));
      verify(() => local.saveDeviceToken(null)).called(1);
    });

    test('sin red devuelve NetworkFailure y no muestra nada', () async {
      when(() => local.readDeviceToken()).thenAnswer((_) async => 'abc');
      when(
        () => remote.takeDeviceNotifications(any(), any(), any()),
      ).thenThrow(const NetworkException('sin red'));

      expect(
        (await repository.deliverToDevice(now)).getLeft().toNullable(),
        isA<NetworkFailure>(),
      );
      verifyNever(() => local.show(any()));
    });
  });
}
