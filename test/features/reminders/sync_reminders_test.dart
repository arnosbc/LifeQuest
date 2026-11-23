import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_movil/app/reminder_actions.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/reminders/domain/entities/reminder_plan.dart';
import 'package:proyecto_movil/features/reminders/domain/repositories/reminders_repository.dart';
import 'package:proyecto_movil/features/reminders/domain/usecases/sync_reminders.dart';

class _Repo extends Mock implements RemindersRepository {}

void main() {
  // Jueves 5 nov 2026, 12:00.
  final now = DateTime(2026, 11, 5, 12);

  group('SyncReminders.build', () {
    test('avisa N minutos antes y omite lo que ya pasó', () {
      final out = SyncReminders.build(
        ReminderPlan(
          tasks: [
            TaskReminder(
              id: 'a',
              title: 'Dentista',
              startsAt: DateTime(2026, 11, 5, 18),
              minutesBefore: 15,
            ),
            TaskReminder(
              id: 'b',
              title: 'Ya fue',
              startsAt: DateTime(2026, 11, 5, 12, 5),
              minutesBefore: 10,
            ),
          ],
        ),
        now,
      );
      expect(out.map((r) => (r.taskId, r.at)), [
        ('a', DateTime(2026, 11, 5, 17, 45)),
      ]);
      expect(out.single.body, contains('18:00'));
    });

    test('lo que cae en la ventana de silencio pasa a su final', () {
      final plan = ReminderPlan(
        silenceStart: 22 * 60,
        silenceEnd: 7 * 60,
        tasks: [
          TaskReminder(
            id: 'noche',
            title: 'Noche',
            startsAt: DateTime(2026, 11, 5, 23),
            minutesBefore: 0,
          ),
          TaskReminder(
            id: 'madrugada',
            title: 'Madrugada',
            startsAt: DateTime(2026, 11, 6, 5),
            minutesBefore: 0,
          ),
          TaskReminder(
            id: 'tarde',
            title: 'Tarde',
            startsAt: DateTime(2026, 11, 5, 15),
            minutesBefore: 0,
          ),
        ],
      );
      expect(SyncReminders.build(plan, now).map((r) => r.at), [
        DateTime(2026, 11, 6, 7),
        DateTime(2026, 11, 6, 7),
        DateTime(2026, 11, 5, 15),
      ]);
    });

    test('un hábito da un aviso semanal por día, en la próxima fecha', () {
      final out = SyncReminders.build(
        const ReminderPlan(
          habits: [
            // 07:30 domingo (0) y jueves (4): el de hoy ya pasó.
            HabitReminder(
              id: 'h',
              name: 'Meditar',
              minuteOfDay: 450,
              days: [0, 4],
            ),
          ],
        ),
        now,
      );
      expect(
        out.every((r) => r.weekly && r.taskId == null && r.habitId == 'h'),
        isTrue,
      );
      expect(out.map((r) => r.at), [
        DateTime(2026, 11, 8, 7, 30),
        DateTime(2026, 11, 12, 7, 30),
      ]);
      expect(out.map((r) => r.id).toSet().length, 2);
    });

    test('un proyecto que pasaría a 🔴 avisa ese día a las 9:00, una vez', () {
      final out = SyncReminders.build(
        ReminderPlan(
          projects: [
            ProjectAlert(id: 'p', title: 'Tesis', day: DateTime(2026, 11, 9)),
          ],
        ),
        now,
      );
      expect(out.single.at, DateTime(2026, 11, 9, 9));
      expect(out.single.title, '«Tesis» necesita un empujón');
      expect(out.single.weekly, isFalse);
    });
  });

  group('avisos del día (048)', () {
    final today = DateTime(2026, 11, 5);
    final tomorrow = DateTime(2026, 11, 6);

    test('resumen a las 8:00 solo los días con algo; el de hoy ya pasó', () {
      final out = SyncReminders.build(
        ReminderPlan(
          days: [
            DayOutlook(day: today, tasks: 2),
            DayOutlook(day: tomorrow, tasks: 1, habits: 2),
          ],
        ),
        now,
      );
      expect(out.single.at, DateTime(2026, 11, 6, 8));
      expect(
        out.single.body,
        '1 tarea y 2 hábitos te esperan. '
        'Empieza por lo más fácil.',
      );
      expect(out.single.kind, 'today');
      expect(
        SyncReminders.build(
          ReminderPlan(days: [DayOutlook(day: tomorrow, tasks: 1)]),
          now,
        ).single.body,
        '1 tarea te espera. Empieza por lo más fácil.',
      );
    });

    test('racha en peligro a las 20:00, con la racha de hoy', () {
      final out = SyncReminders.build(
        ReminderPlan(
          days: [
            DayOutlook(day: today, habits: 2, streakHabits: 2, bestStreak: 12),
          ],
        ),
        now,
      );
      expect(out.single.at, DateTime(2026, 11, 5, 20));
      expect(out.single.title, 'Tu racha de 12 días te está esperando 🔥');
      expect(out.single.body, startsWith('Te faltan 2 hábitos de hoy.'));
      expect(out.single.kind, 'streak');
    });

    test(
      'si las 20:00 caen en silencio, sale una hora antes de que empiece',
      () {
        ReminderPlan plan({required bool bypass}) => ReminderPlan(
          silenceStart: 19 * 60,
          silenceEnd: 7 * 60,
          criticalBypassSilence: bypass,
          days: [DayOutlook(day: today, habits: 1, streakHabits: 1)],
        );
        expect(
          SyncReminders.build(plan(bypass: false), now).single.at,
          DateTime(2026, 11, 5, 18),
        );
        expect(
          SyncReminders.build(plan(bypass: true), now).single.at,
          DateTime(2026, 11, 5, 20),
        );
      },
    );

    test(
      'con límite diario se quitan primero el resumen y luego el cierre',
      () {
        ReminderPlan plan(int limit) => ReminderPlan(
          dayClose: true,
          dailyLimit: limit,
          tasks: [
            TaskReminder(
              id: 't',
              title: 'Dentista',
              startsAt: DateTime(2026, 11, 6, 10),
              minutesBefore: 0,
            ),
          ],
          days: [DayOutlook(day: tomorrow, tasks: 1, streakHabits: 1)],
        );
        List<String?> kinds(int limit) => [
          for (final r in SyncReminders.build(plan(limit), now))
            if (r.at.day == 6) r.kind ?? r.taskId,
        ];
        expect(kinds(4), ['t', 'today', 'streak', 'close']);
        expect(kinds(3), ['t', 'streak', 'close']);
        expect(kinds(1), ['t', 'streak']); // lo pedido y lo crítico siempre
      },
    );

    test('en una sesión de Foco lo no crítico sale al terminar', () {
      final end = DateTime(2026, 11, 5, 12, 25);
      final out = SyncReminders.build(
        ReminderPlan(
          tasks: [
            TaskReminder(
              id: 't',
              title: 'Llamar',
              startsAt: DateTime(2026, 11, 5, 12, 10),
              minutesBefore: 0,
            ),
          ],
          habits: const [
            // Jueves 12:15.
            HabitReminder(id: 'h', name: 'Agua', minuteOfDay: 735, days: [4]),
          ],
        ),
        now,
        quietUntil: end,
      );
      expect(out.map((r) => (r.taskId ?? r.habitId, r.at, r.weekly)), [
        ('t', end, false),
        ('h', end, false), // una vez; al terminar Foco vuelve a ser semanal
      ]);
    });
  });

  test(
    'call programa el plan y no toca los avisos si el servidor falla',
    () async {
      final repo = _Repo();
      registerFallbackValue(<LocalReminder>[]);
      when(
        () => repo.getPlan(),
      ).thenAnswer((_) async => const Left(NetworkFailure('sin red')));
      final sync = SyncReminders(repo, clock: () => now);
      expect(await sync(null), const Left(NetworkFailure('sin red')));
      verifyNever(() => repo.replaceAll(any()));

      when(
        () => repo.getPlan(),
      ).thenAnswer((_) async => const Right(ReminderPlan()));
      when(
        () => repo.replaceAll(any()),
      ).thenAnswer((_) async => const Right(unit));
      expect((await sync(null)).getRight().toNullable(), isEmpty);
      verify(() => repo.replaceAll(const [])).called(1);
    },
  );

  test('newReminderText dice cuándo llega el aviso nuevo', () {
    LocalReminder r(DateTime at, String title, [String? kind]) =>
        LocalReminder(id: 9, title: title, body: 'b', at: at, kind: kind);
    final close = r(DateTime(2026, 11, 5, 21), 'Cierra el día', 'close');
    final summary = r(DateTime(2026, 11, 6, 8), 'Tu día', 'today');
    expect(
      ReminderActions.newReminderText([close], [close, summary], now),
      'Te aviso mañana a las 8:00.',
    );
    expect(ReminderActions.newReminderText([close], [close], now), isNull);
    // El aviso de la tarea gana al resumen aunque llegue más tarde.
    final task = LocalReminder(
      id: 1,
      title: 'Estudiar',
      body: 'b',
      at: DateTime(2026, 11, 6, 18, 50),
      taskId: 't',
    );
    expect(
      ReminderActions.newReminderText([close], [close, summary, task], now),
      'Te aviso mañana a las 18:50.',
    );
    expect(
      ReminderActions.newReminderText(const [], [
        r(DateTime(2026, 11, 9, 7, 5), 'x'),
      ], now),
      'Te aviso el lunes a las 7:05.',
    );
  });
}
