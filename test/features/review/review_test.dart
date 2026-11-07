import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/reminders/domain/entities/reminder_plan.dart';
import 'package:proyecto_movil/features/reminders/domain/usecases/sync_reminders.dart';
import 'package:proyecto_movil/features/review/data/models/weekly_review_model.dart';
import 'package:proyecto_movil/features/review/domain/entities/weekly_review.dart';
import 'package:proyecto_movil/features/review/domain/repositories/review_repository.dart';
import 'package:proyecto_movil/features/review/domain/usecases/drop_task.dart';
import 'package:proyecto_movil/features/review/domain/usecases/get_weekly_review.dart';
import 'package:proyecto_movil/features/review/domain/usecases/postpone_task.dart';
import 'package:proyecto_movil/features/review/presentation/blocs/review_bloc.dart';

class _Repo extends Mock implements ReviewRepository {}

void main() {
  // Jueves 5 nov 2026.
  final now = DateTime(2026, 11, 5, 12);
  final review = WeeklyReview(
    weekStart: DateTime(2026, 11, 2),
    done: 4,
    focusMinutes: 90,
    habitDays: 6,
    pending: const [ReviewTask(id: 't1', title: 'Informe')],
  );
  final empty = WeeklyReview(
    weekStart: DateTime(2026, 11, 2),
    done: 5,
    focusMinutes: 90,
    habitDays: 6,
    pending: const [],
  );
  late _Repo repo;

  setUpAll(() => registerFallbackValue(DateTime(2026)));
  setUp(() => repo = _Repo());

  ReviewBloc build() => ReviewBloc(
    getReview: GetWeeklyReview(repo),
    postpone: PostponeTask(repo),
    drop: DropTask(repo),
    clock: () => now,
  );

  test('WeeklyReviewModel lee weekly_review', () {
    final r = WeeklyReviewModel({
      'week_start': '2026-11-02',
      'done': 4,
      'focus_minutes': 90,
      'habit_days': 6,
      'inbox': 3,
      'pending': [
        {
          'id': 't1',
          'title': 'Informe',
          'due_date': null,
          'repeat_rule': 'daily',
        },
      ],
    }).toEntity();
    expect(r.weekStart, DateTime(2026, 11, 2));
    expect(r.inbox, 3);
    expect(
      r.pending.single,
      const ReviewTask(id: 't1', title: 'Informe', repeats: true),
    );
  });

  blocTest<ReviewBloc, ReviewState>(
    'carga la semana',
    setUp: () =>
        when(() => repo.getReview(now)).thenAnswer((_) async => Right(review)),
    build: build,
    act: (bloc) => bloc.add(const ReviewRequested()),
    expect: () => [const ReviewLoading(), ReviewSuccess(review)],
  );

  blocTest<ReviewBloc, ReviewState>(
    'pasar a la otra semana marca la fila y vuelve a leer',
    setUp: () {
      when(
        () => repo.postpone('t1', days: 7),
      ).thenAnswer((_) async => const Right(unit));
      when(() => repo.getReview(now)).thenAnswer((_) async => Right(empty));
    },
    build: build,
    seed: () => ReviewSuccess(review),
    act: (bloc) => bloc.add(const ReviewTaskPostponed('t1')),
    expect: () => [
      ReviewSuccess(review, busyTaskId: 't1'),
      ReviewSuccess(empty, message: 'Pasó a la semana que viene.'),
    ],
  );

  blocTest<ReviewBloc, ReviewState>(
    'si soltar falla, conserva la lista y avisa',
    setUp: () => when(
      () => repo.drop('t1'),
    ).thenAnswer((_) async => const Left(ServerFailure('Tiene foco.'))),
    build: build,
    seed: () => ReviewSuccess(review),
    act: (bloc) => bloc.add(const ReviewTaskDropped('t1')),
    expect: () => [
      ReviewSuccess(review, busyTaskId: 't1'),
      ReviewSuccess(review, message: 'Tiene foco.'),
    ],
  );

  test('el aviso de cerrar el día cae a las 21:00 y se repite cada día', () {
    final out = SyncReminders.build(const ReminderPlan(dayClose: true), now);
    expect(out.single.title, 'Cierra el día');
    final day = now.hour < 21 ? now.day : now.day + 1;
    expect(out.single.at, DateTime(now.year, now.month, day, 21));
    expect(out.single.daily, isTrue);
    expect(SyncReminders.build(const ReminderPlan(), now), isEmpty);
  });
}
