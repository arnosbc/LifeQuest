import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/onboarding/data/models/onboarding_status_model.dart';
import 'package:proyecto_movil/features/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'package:proyecto_movil/features/onboarding/domain/entities/onboarding_choices.dart';

import '../../../helpers/mocks.dart';
import '../onboarding_fixtures.dart';

void main() {
  group('OnboardingStatusModel', () {
    test('convierte la respuesta de onboarding_overview', () {
      final status = OnboardingStatusModel.fromJson({
        'pending': true,
        'difficulties': [
          for (final (level, xp, hp) in [
            ('easy', 1.2, 0.75),
            ('normal', 1, 1),
            ('hard', 0.85, 1.25),
            ('legendary', 2, 2), // nivel desconocido: se ignora
          ])
            {
              'level': level,
              'xp_multiplier': xp,
              'hp_penalty_multiplier': hp,
              'coin_multiplier': 1,
            },
        ],
      }).toEntity();

      expect(status, pendingStatus);
    });

    test('respuesta vacía no deja pendiente el Onboarding', () {
      final status = OnboardingStatusModel.fromJson({}).toEntity();
      expect(status.pending, isFalse);
      expect(status.difficulties, isEmpty);
    });
  });

  group('OnboardingRepositoryImpl', () {
    late MockOnboardingRemoteDataSource remote;
    late OnboardingRepositoryImpl repository;
    const choices = OnboardingChoices(identity: 'Ana', skill: 'Salud');

    setUpAll(() => registerFallbackValue(choices));

    setUp(() {
      remote = MockOnboardingRemoteDataSource();
      repository = OnboardingRepositoryImpl(remote);
    });

    test('getStatus devuelve la entidad', () async {
      when(() => remote.getStatus()).thenAnswer(
        (_) async => const OnboardingStatusModel(
          pending: true,
          difficulties: difficulties,
        ),
      );
      expect(await repository.getStatus(), const Right(pendingStatus));
    });

    test('complete guarda lo elegido', () async {
      when(() => remote.complete(any())).thenAnswer((_) async {});
      expect(await repository.complete(choices), const Right(unit));
      verify(() => remote.complete(choices)).called(1);
    });

    test('onboarding_done (ya terminado en otro teléfono) es éxito', () async {
      when(
        () => remote.complete(any()),
      ).thenThrow(const ServerException(code: 'onboarding_done'));
      expect(await repository.complete(choices), const Right(unit));
    });

    test('traduce los errores del servidor y de red', () async {
      Future<Object?> failWith(Exception error) async {
        when(() => remote.complete(any())).thenThrow(error);
        return (await repository.complete(choices)).getLeft().toNullable();
      }

      expect(
        await failWith(const ServerException(code: 'skill_exists')),
        const ServerFailure('Ya tienes una skill con ese nombre.'),
      );
      expect(
        await failWith(
          const ServerException(code: 'violates check', statusCode: '23514'),
        ),
        const ServerFailure(
          'Usa una identidad de hasta 280 caracteres y una skill de hasta 40.',
        ),
      );
      expect(
        await failWith(const ServerException(code: 'otro')),
        const ServerFailure(
          'No pudimos guardar tu aventura. Inténtalo de nuevo.',
        ),
      );
      expect(
        await failWith(const NetworkException()),
        const NetworkFailure(
          'Sin conexión. Revisa tu internet y vuelve a intentarlo.',
        ),
      );
    });
  });
}
