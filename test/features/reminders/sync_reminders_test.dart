import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
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
      expect(out.every((r) => r.weekly && r.taskId == null), isTrue);
      expect(out.map((r) => r.at), [
        DateTime(2026, 11, 8, 7, 30),
        DateTime(2026, 11, 12, 7, 30),
      ]);
      expect(out.map((r) => r.id).toSet().length, 2);
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
      expect(
        await sync(const NoParams()),
        const Left(NetworkFailure('sin red')),
      );
      verifyNever(() => repo.replaceAll(any()));

      when(
        () => repo.getPlan(),
      ).thenAnswer((_) async => const Right(ReminderPlan()));
      when(
        () => repo.replaceAll(any()),
      ).thenAnswer((_) async => const Right(unit));
      expect(await sync(const NoParams()), const Right(unit));
      verify(() => repo.replaceAll(const [])).called(1);
    },
  );
}
