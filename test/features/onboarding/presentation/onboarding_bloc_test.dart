import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/onboarding/domain/entities/onboarding_choices.dart';
import 'package:proyecto_movil/features/onboarding/domain/entities/onboarding_status.dart';
import 'package:proyecto_movil/features/onboarding/presentation/blocs/onboarding_bloc.dart';

import '../../../helpers/mocks.dart';
import '../onboarding_fixtures.dart';

void main() {
  late MockGetOnboardingStatus getStatus;
  late MockCompleteOnboarding complete;
  const choices = OnboardingChoices(
    identity: 'Ana',
    difficulty: GameDifficulty.hard,
  );

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(const OnboardingChoices());
  });

  setUp(() {
    getStatus = MockGetOnboardingStatus();
    complete = MockCompleteOnboarding();
  });

  OnboardingBloc build() => OnboardingBloc(
    getOnboardingStatus: getStatus,
    completeOnboarding: complete,
  );

  blocTest<OnboardingBloc, OnboardingState>(
    'pendiente: muestra el Onboarding',
    setUp: () => when(
      () => getStatus(any()),
    ).thenAnswer((_) async => const Right(pendingStatus)),
    build: build,
    act: (bloc) => bloc.add(const OnboardingRequested()),
    expect: () => const [OnboardingLoading(), OnboardingPending(pendingStatus)],
  );

  blocTest<OnboardingBloc, OnboardingState>(
    'ya hecho: no hace falta',
    setUp: () => when(() => getStatus(any())).thenAnswer(
      (_) async => const Right(
        OnboardingStatus(pending: false, difficulties: difficulties),
      ),
    ),
    build: build,
    act: (bloc) => bloc.add(const OnboardingRequested()),
    expect: () => const [OnboardingLoading(), OnboardingNotNeeded()],
  );

  blocTest<OnboardingBloc, OnboardingState>(
    'si la consulta falla, entra a Inicio (nunca queda atrapado)',
    setUp: () => when(
      () => getStatus(any()),
    ).thenAnswer((_) async => const Left(NetworkFailure('sin red'))),
    build: build,
    act: (bloc) => bloc.add(const OnboardingRequested()),
    expect: () => const [OnboardingLoading(), OnboardingNotNeeded()],
  );

  blocTest<OnboardingBloc, OnboardingState>(
    'terminar o saltar guarda y deja de estar pendiente',
    setUp: () =>
        when(() => complete(any())).thenAnswer((_) async => const Right(unit)),
    build: build,
    seed: () => const OnboardingPending(pendingStatus),
    act: (bloc) => bloc.add(const OnboardingSubmitted(choices)),
    expect: () => const [
      OnboardingPending(pendingStatus, saving: true),
      OnboardingNotNeeded(),
    ],
    verify: (_) => verify(() => complete(choices)).called(1),
  );

  blocTest<OnboardingBloc, OnboardingState>(
    'error al guardar: sigue en el Onboarding con el aviso',
    setUp: () => when(
      () => complete(any()),
    ).thenAnswer((_) async => const Left(ServerFailure('Inténtalo de nuevo'))),
    build: build,
    seed: () => const OnboardingPending(pendingStatus),
    act: (bloc) => bloc.add(const OnboardingSubmitted(choices)),
    expect: () => const [
      OnboardingPending(pendingStatus, saving: true),
      OnboardingPending(pendingStatus, error: 'Inténtalo de nuevo'),
    ],
  );

  blocTest<OnboardingBloc, OnboardingState>(
    'cerrar sesión lo olvida',
    build: build,
    seed: () => const OnboardingNotNeeded(),
    act: (bloc) => bloc.add(const OnboardingReset()),
    expect: () => const [OnboardingInitial()],
  );
}
