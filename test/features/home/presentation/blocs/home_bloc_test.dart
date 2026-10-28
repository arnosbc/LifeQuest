import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/home/domain/entities/home_dashboard.dart';
import 'package:proyecto_movil/features/home/domain/usecases/complete_habit.dart';
import 'package:proyecto_movil/features/home/presentation/blocs/home_bloc.dart';

import '../../../../helpers/mocks.dart';
import '../../home_fixtures.dart';

void main() {
  late MockGetHomeDashboard getHomeDashboard;
  late MockCompleteHabit completeHabit;
  late MockClaimDailyChest claimChest;
  final now = DateTime(2026, 10, 17, 9);
  const failure = ServerFailure('Algo salió mal.');

  setUpAll(() {
    registerFallbackValue(now);
    registerFallbackValue(const NoParams());
    registerFallbackValue(CompleteHabitParams(habitId: 'h', now: now));
  });

  setUp(() {
    getHomeDashboard = MockGetHomeDashboard();
    completeHabit = MockCompleteHabit();
    claimChest = MockClaimDailyChest();
  });

  HomeBloc build() => HomeBloc(
    getHomeDashboard: getHomeDashboard,
    completeHabit: completeHabit,
    claimDailyChest: claimChest,
    clock: () => now,
  );

  void givenDashboard(Either<Failure, HomeDashboard> result) =>
      when(() => getHomeDashboard(any())).thenAnswer((_) async => result);

  group('HomeRequested', () {
    blocTest<HomeBloc, HomeState>(
      'la primera carga pasa por Loading y termina en Success',
      setUp: () => givenDashboard(Right(dashboard)),
      build: build,
      act: (bloc) => bloc.add(const HomeRequested()),
      expect: () => [const HomeLoading(), HomeSuccess(dashboard)],
      verify: (_) => verify(() => getHomeDashboard(now)).called(1),
    );

    blocTest<HomeBloc, HomeState>(
      'si la primera carga falla, muestra el error',
      setUp: () => givenDashboard(const Left(failure)),
      build: build,
      act: (bloc) => bloc.add(const HomeRequested()),
      expect: () => [const HomeLoading(), HomeFailure(failure.message)],
    );

    blocTest<HomeBloc, HomeState>(
      'al refrescar conserva los datos y, si falla, avisa sin quitarlos',
      setUp: () => givenDashboard(const Left(failure)),
      build: build,
      seed: () => HomeSuccess(dashboard),
      act: (bloc) => bloc.add(const HomeRequested()),
      expect: () => [
        HomeSuccess(dashboard, refreshing: true),
        HomeSuccess(dashboard, message: failure.message),
      ],
    );
  });

  group('HomeHabitCompleted', () {
    blocTest<HomeBloc, HomeState>(
      'registra el hábito y vuelve a leer XP, monedas y racha',
      setUp: () {
        when(
          () => completeHabit(any()),
        ).thenAnswer((_) async => const Right(unit));
        givenDashboard(const Right(emptyDashboard));
      },
      build: build,
      seed: () => HomeSuccess(dashboard),
      act: (bloc) => bloc.add(const HomeHabitCompleted('h2')),
      expect: () => [
        HomeSuccess(dashboard, busyHabitId: 'h2'),
        const HomeSuccess(emptyDashboard),
      ],
      verify: (_) => verify(
        () => completeHabit(CompleteHabitParams(habitId: 'h2', now: now)),
      ).called(1),
    );

    blocTest<HomeBloc, HomeState>(
      'si el servidor lo rechaza, avisa y no recarga',
      setUp: () => when(
        () => completeHabit(any()),
      ).thenAnswer((_) async => const Left(failure)),
      build: build,
      seed: () => HomeSuccess(dashboard),
      act: (bloc) => bloc.add(const HomeHabitCompleted('h2')),
      expect: () => [
        HomeSuccess(dashboard, busyHabitId: 'h2'),
        HomeSuccess(dashboard, message: failure.message),
      ],
      verify: (_) => verifyNever(() => getHomeDashboard(any())),
    );

    blocTest<HomeBloc, HomeState>(
      'sin datos cargados no hace nada',
      build: build,
      act: (bloc) => bloc.add(const HomeHabitCompleted('h2')),
      expect: () => <HomeState>[],
    );
  });

  blocTest<HomeBloc, HomeState>(
    'abrir el cofre lo cobra, vuelve a leer y celebra',
    setUp: () {
      when(() => claimChest(any())).thenAnswer((_) async => const Right(unit));
      when(
        () => getHomeDashboard(any()),
      ).thenAnswer((_) async => Right(dashboard));
    },
    build: build,
    seed: () => HomeSuccess(dashboard),
    act: (bloc) => bloc.add(const HomeChestClaimed()),
    expect: () => [
      HomeSuccess(dashboard, claimingChest: true),
      HomeSuccess(dashboard, message: '¡Cofre abierto! +15 Monedas.'),
    ],
  );

  blocTest<HomeBloc, HomeState>(
    'si el cofre aún no se abre, conserva el Home y avisa',
    setUp: () => when(
      () => claimChest(any()),
    ).thenAnswer((_) async => const Left(failure)),
    build: build,
    seed: () => HomeSuccess(dashboard),
    act: (bloc) => bloc.add(const HomeChestClaimed()),
    expect: () => [
      HomeSuccess(dashboard, claimingChest: true),
      HomeSuccess(dashboard, message: failure.message),
    ],
    verify: (_) => verifyNever(() => getHomeDashboard(any())),
  );
}
