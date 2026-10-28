import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/notifications/data/models/notifications_model.dart';
import 'package:proyecto_movil/features/notifications/domain/entities/app_notification.dart';
import 'package:proyecto_movil/features/notifications/presentation/blocs/notifications_bloc.dart';

import '../../helpers/mocks.dart';

final at = DateTime(2026, 10, 27, 9);
final streak = AppNotification(
  id: 'n1',
  kind: NotificationKind.critical,
  title: 'Tu racha te está esperando 🔥',
  description: 'Llevas 12 días con «Leer».',
  createdAt: at,
);
final readStreak = AppNotification(
  id: 'n1',
  kind: NotificationKind.critical,
  title: 'Tu racha te está esperando 🔥',
  description: 'Llevas 12 días con «Leer».',
  createdAt: at,
  read: true,
);

void main() {
  test('NotificationsModel traduce los tres niveles', () {
    final items = NotificationsModel.fromJson({
      'items': [
        for (final type in ['critical', 'motivational', 'informational'])
          {
            'id': type,
            'type': type,
            'title': 't',
            'message': 'm',
            'created_at': '2026-10-27T10:00:00+00:00',
            'read': type == 'critical',
          },
      ],
    }).toEntity();
    expect(items.map((n) => n.kind), NotificationKind.values);
    expect(items.map((n) => n.read), [true, false, false]);
  });

  late MockGetNotifications getNotifications;
  late MockMarkNotificationsRead markRead;

  setUp(() {
    getNotifications = MockGetNotifications();
    markRead = MockMarkNotificationsRead();
  });

  NotificationsBloc build() => NotificationsBloc(
    getNotifications: getNotifications,
    markRead: markRead,
    clock: () => at,
  );

  blocTest<NotificationsBloc, NotificationsState>(
    'carga los avisos del día',
    setUp: () => when(
      () => getNotifications(at),
    ).thenAnswer((_) async => Right([streak])),
    build: build,
    act: (bloc) => bloc.add(const NotificationsRequested()),
    expect: () => [
      const NotificationsLoading(),
      NotificationsSuccess([streak]),
    ],
  );

  blocTest<NotificationsBloc, NotificationsState>(
    'marcar leído se ve al instante',
    setUp: () =>
        when(() => markRead(['n1'])).thenAnswer((_) async => const Right(unit)),
    build: build,
    seed: () => NotificationsSuccess([streak]),
    act: (bloc) => bloc.add(const NotificationsRead(['n1'])),
    expect: () => [
      NotificationsSuccess([readStreak]),
    ],
  );

  blocTest<NotificationsBloc, NotificationsState>(
    'si el servidor falla, vuelve a no leído y avisa',
    setUp: () => when(
      () => markRead(null),
    ).thenAnswer((_) async => const Left(ServerFailure('Sin conexión.'))),
    build: build,
    seed: () => NotificationsSuccess([streak]),
    act: (bloc) => bloc.add(const NotificationsRead()),
    expect: () => [
      NotificationsSuccess([readStreak]),
      NotificationsSuccess([streak], message: 'Sin conexión.'),
    ],
  );
}
