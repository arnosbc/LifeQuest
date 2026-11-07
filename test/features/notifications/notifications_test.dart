import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/reminders/data/datasources/reminders_local_datasource.dart';
import 'package:proyecto_movil/features/reminders/domain/entities/reminder_plan.dart';
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

  test('NotificationsModel sabe qué abre cada aviso (043)', () {
    final items = NotificationsModel.fromJson({
      'items': [
        for (final category in ['streak', 'project', 'due', 'level', null])
          {
            'id': '$category',
            'type': 'critical',
            'title': 't',
            'message': 'm',
            'created_at': '2026-10-27T10:00:00+00:00',
            'category': category,
          },
      ],
    }).toEntity();
    expect(items.map((n) => n.topic), [
      NotificationTopic.habit,
      NotificationTopic.project,
      NotificationTopic.task,
      NotificationTopic.level,
      NotificationTopic.other,
    ]);
  });

  test('cada aviso del teléfono lleva a dónde abre', () {
    final at = DateTime(2026, 11, 9, 9);
    String? payload(LocalReminder r) =>
        RemindersLocalDataSourceImpl.payloadOf(r);
    expect(
      payload(LocalReminder(id: 1, title: 't', body: 'b', at: at, taskId: 'a')),
      'task:a',
    );
    expect(
      payload(
        LocalReminder(id: 1, title: 't', body: 'b', at: at, habitId: 'h'),
      ),
      'habit:h',
    );
    expect(
      payload(
        LocalReminder(id: 1, title: 't', body: 'b', at: at, projectId: 'p'),
      ),
      'project:p',
    );
    expect(
      payload(LocalReminder(id: 1, title: 't', body: 'b', at: at, daily: true)),
      'close',
    );
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
