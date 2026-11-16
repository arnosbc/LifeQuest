import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/habits/domain/entities/habits_board.dart';
import 'package:proyecto_movil/features/habits/domain/usecases/complete_good_habit.dart';
import 'package:proyecto_movil/features/habits/domain/usecases/set_habit_time.dart';
import 'package:proyecto_movil/features/habits/presentation/blocs/habits_bloc.dart';

import '../../../helpers/mocks.dart';
import '../habits_fixtures.dart';

void main() {
  late MockGetHabitsBoard getBoard;
  late MockCreateHabit createHabit;
  late MockCompleteGoodHabit completeGood;
  late MockRegisterBadHabit registerBad;
  late _SetTime setTime;
  final now = DateTime(2026, 10, 25, 9);
  const failure = ServerFailure('Algo salió mal.');

  setUpAll(() {
    registerFallbackValue(now);
    registerFallbackValue(newHabit);
    registerFallbackValue(CompleteGoodHabitParams(habitId: 'h', now: now));
  });

  setUp(() {
    getBoard = MockGetHabitsBoard();
    createHabit = MockCreateHabit();
    completeGood = MockCompleteGoodHabit();
    registerBad = MockRegisterBadHabit();
    setTime = _SetTime();
  });

  HabitsBloc build() => HabitsBloc(
    getHabitsBoard: getBoard,
    createHabit: createHabit,
    completeGoodHabit: completeGood,
    registerBadHabit: registerBad,
    renameHabit: MockRenameHabit(),
    deleteHabit: MockDeleteHabit(),
    setHabitTime: setTime,
    clock: () => now,
  );

  void givenBoard(Either<Failure, HabitsBoard> result) =>
      when(() => getBoard(any())).thenAnswer((_) async => result);

  blocTest<HabitsBloc, HabitsState>(
    'la primera carga pasa por Loading y termina en Success',
    setUp: () => givenBoard(const Right(habitsBoard)),
    build: build,
    act: (bloc) => bloc.add(const HabitsRequested()),
    expect: () => [const HabitsLoading(), const HabitsSuccess(habitsBoard)],
    verify: (_) => verify(() => getBoard(now)).called(1),
  );

  blocTest<HabitsBloc, HabitsState>(
    'si la primera carga falla, muestra el error',
    setUp: () => givenBoard(const Left(failure)),
    build: build,
    act: (bloc) => bloc.add(const HabitsRequested()),
    expect: () => [const HabitsLoading(), HabitsFailure(failure.message)],
  );

  blocTest<HabitsBloc, HabitsState>(
    'cumplir un hábito bueno lo marca ocupado y vuelve a leer',
    setUp: () {
      when(
        () => completeGood(any()),
      ).thenAnswer((_) async => const Right(unit));
      givenBoard(const Right(habitsBoard));
    },
    build: build,
    seed: () => const HabitsSuccess(emptyHabitsBoard),
    act: (bloc) => bloc.add(const GoodHabitCompleted('h1')),
    expect: () => [
      const HabitsSuccess(emptyHabitsBoard, busyHabitId: 'h1'),
      const HabitsSuccess(
        habitsBoard,
        message: '¡Hábito cumplido! Tu racha sigue creciendo.',
      ),
    ],
    verify: (_) => verify(
      () => completeGood(CompleteGoodHabitParams(habitId: 'h1', now: now)),
    ).called(1),
  );

  blocTest<HabitsBloc, HabitsState>(
    'si registrar un hábito malo falla, conserva los datos y avisa',
    setUp: () => when(
      () => registerBad('h2'),
    ).thenAnswer((_) async => const Left(failure)),
    build: build,
    seed: () => const HabitsSuccess(habitsBoard),
    act: (bloc) => bloc.add(const BadHabitRegistered('h2')),
    expect: () => [
      const HabitsSuccess(habitsBoard, busyHabitId: 'h2'),
      HabitsSuccess(habitsBoard, message: failure.message),
    ],
    verify: (_) => verifyNever(() => getBoard(any())),
  );

  blocTest<HabitsBloc, HabitsState>(
    'crear un hábito muestra guardando y recarga',
    setUp: () {
      when(() => createHabit(any())).thenAnswer((_) async => const Right(unit));
      givenBoard(const Right(habitsBoard));
    },
    build: build,
    seed: () => const HabitsSuccess(emptyHabitsBoard),
    act: (bloc) => bloc.add(const HabitCreated(newHabit)),
    expect: () => [
      const HabitsSuccess(emptyHabitsBoard, saving: true),
      const HabitsSuccess(
        habitsBoard,
        message: 'Hábito creado. ¡Cada día cuenta!',
      ),
    ],
  );

  blocTest<HabitsBloc, HabitsState>(
    'elegir la hora de un hábito la guarda, relee y lo explica (071)',
    setUp: () {
      when(
        () => setTime(const HabitTimeParams('h1', '20:00')),
      ).thenAnswer((_) async => const Right(unit));
      givenBoard(const Right(habitsBoard));
    },
    build: build,
    seed: () => const HabitsSuccess(emptyHabitsBoard),
    act: (bloc) => bloc.add(const HabitTimeSet('h1', '20:00')),
    expect: () => [
      const HabitsSuccess(emptyHabitsBoard, busyHabitId: 'h1'),
      const HabitsSuccess(
        habitsBoard,
        message: 'Listo: Nevi te avisará a esa hora si aún no lo haces.',
      ),
    ],
  );

  blocTest<HabitsBloc, HabitsState>(
    'quitar la hora la borra y lo dice',
    setUp: () {
      when(
        () => setTime(const HabitTimeParams('h1', null)),
      ).thenAnswer((_) async => const Right(unit));
      givenBoard(const Right(habitsBoard));
    },
    build: build,
    seed: () => const HabitsSuccess(emptyHabitsBoard),
    act: (bloc) => bloc.add(const HabitTimeSet('h1', null)),
    skip: 1,
    expect: () => [
      const HabitsSuccess(habitsBoard, message: 'Quitaste la hora del hábito.'),
    ],
  );
}

class _SetTime extends Mock implements SetHabitTime {}
