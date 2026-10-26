import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/habits/data/models/habits_board_model.dart';
import 'package:proyecto_movil/features/habits/data/repositories/habits_repository_impl.dart';
import 'package:proyecto_movil/features/habits/domain/entities/habit.dart';
import 'package:proyecto_movil/features/habits/domain/entities/habits_board.dart';

import '../../../helpers/mocks.dart';
import '../habits_fixtures.dart';

void main() {
  group('HabitsBoardModel', () {
    test('convierte la respuesta de habits_overview', () {
      final board = HabitsBoardModel.fromJson({
        'habits': [
          {
            'id': 'h1',
            'name': 'Gimnasio',
            'type': 'good',
            'frequency': 'specific_days',
            'specific_days': [1, 3],
            'skill_name': 'Salud',
            'hp_penalty': 0,
            'current_streak': 2,
            'best_streak': 5,
            'scheduled_today': false,
            'done_today': false,
            'today_count': 0,
            'week': [true, false, false, false, false, false, false],
          },
        ],
        'week_xp': 20,
        'week_done': 2,
        'week_scheduled': 3,
        'bad_free_days': 6,
        'month_days': [1, 4],
        'skills': [
          {'id': 's1', 'name': 'Salud'},
        ],
      }).toEntity();

      final h = board.habits.single;
      expect(h.type, HabitType.good);
      expect(h.specificDays, [1, 3]);
      expect([h.currentStreak, h.bestStreak], [2, 5]);
      expect(h.scheduledToday, isFalse);
      expect(h.week.first, isTrue);
      expect(
        [board.weekXp, board.weekDone, board.weekScheduled, board.badFreeDays],
        [20, 2, 3, 6],
      );
      expect(board.monthDays, [1, 4]);
      expect(board.skills, [const HabitSkill(id: 's1', name: 'Salud')]);
    });

    test('respuesta vacía usa los valores por defecto', () {
      expect(
        HabitsBoardModel.fromJson({}).toEntity(),
        const HabitsBoard(habits: []),
      );
    });
  });

  group('HabitsRepositoryImpl', () {
    late MockHabitsRemoteDataSource remote;
    late HabitsRepositoryImpl repository;
    final now = DateTime(2026, 3, 7, 23, 30);

    setUpAll(() => registerFallbackValue(newHabit));

    setUp(() {
      remote = MockHabitsRemoteDataSource();
      repository = HabitsRepositoryImpl(remote);
    });

    test('pide el tablero con la fecha local', () async {
      when(
        () => remote.getBoard(any()),
      ).thenAnswer((_) async => const HabitsBoardModel({}));
      expect(await repository.getBoard(now), const Right(emptyHabitsBoard));
      verify(() => remote.getBoard('2026-03-07')).called(1);
    });

    test('cumplir pasa el día local', () async {
      when(
        () => remote.completeGoodHabit(
          habitId: any(named: 'habitId'),
          day: any(named: 'day'),
        ),
      ).thenAnswer((_) async {});
      expect(
        await repository.completeGoodHabit(habitId: 'h1', now: now),
        const Right(unit),
      );
      verify(
        () => remote.completeGoodHabit(habitId: 'h1', day: '2026-03-07'),
      ).called(1);
    });

    test('traduce los motivos del servidor', () async {
      when(
        () => remote.createHabit(any()),
      ).thenThrow(const ServerException(code: 'invalid_days'));
      expect(
        await repository.createHabit(newHabit),
        const Left(ServerFailure('Elige al menos un día de la semana.')),
      );
    });

    test('sin conexión devuelve NetworkFailure', () async {
      when(
        () => remote.registerBadHabit('h2'),
      ).thenThrow(const NetworkException());
      expect(
        (await repository.registerBadHabit('h2')).getLeft().toNullable(),
        isA<NetworkFailure>(),
      );
    });
  });
}
