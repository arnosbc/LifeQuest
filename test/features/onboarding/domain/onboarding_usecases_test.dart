import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/onboarding/domain/entities/onboarding_choices.dart';
import 'package:proyecto_movil/features/onboarding/domain/usecases/complete_onboarding.dart';
import 'package:proyecto_movil/features/onboarding/domain/usecases/get_onboarding_status.dart';

import '../../../helpers/mocks.dart';
import '../onboarding_fixtures.dart';

void main() {
  late MockOnboardingRepository repository;

  setUpAll(() => registerFallbackValue(const OnboardingChoices()));
  setUp(() => repository = MockOnboardingRepository());

  test('GetOnboardingStatus delega en el repositorio', () async {
    when(
      () => repository.getStatus(),
    ).thenAnswer((_) async => const Right(pendingStatus));
    expect(
      await GetOnboardingStatus(repository)(const NoParams()),
      const Right(pendingStatus),
    );
  });

  test('CompleteOnboarding guarda si respeta los límites', () async {
    when(
      () => repository.complete(any()),
    ).thenAnswer((_) async => const Right(unit));
    const choices = OnboardingChoices(identity: '  Ana  ', skill: 'Salud');
    expect(await CompleteOnboarding(repository)(choices), const Right(unit));
    verify(() => repository.complete(choices)).called(1);
  });

  test(
    'CompleteOnboarding rechaza textos largos sin llamar al servidor',
    () async {
      final result = await CompleteOnboarding(repository)(
        OnboardingChoices(skill: 'x' * 41),
      );
      expect(result.isLeft(), isTrue);
      expect(result.getLeft().toNullable(), isA<ServerFailure>());
      verifyNever(() => repository.complete(any()));
    },
  );
}
