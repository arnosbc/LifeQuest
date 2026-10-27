import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/settings/data/models/settings_overview_model.dart';
import 'package:proyecto_movil/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:proyecto_movil/features/settings/domain/entities/game_settings.dart';
import 'package:proyecto_movil/features/settings/domain/usecases/save_game_settings.dart';

import '../../../helpers/mocks.dart';
import '../settings_fixtures.dart';

void main() {
  group('SettingsOverviewModel', () {
    test('convierte la respuesta de settings_overview', () {
      final overview = SettingsOverviewModel.fromJson({
        'level': 7,
        'current_xp': 120,
        'xp_to_next_level': 1852,
        'difficulty': 'hard',
        'notification_daily_limit': 10,
        'silence_window_start': '22:00',
        'silence_window_end': '07:30',
        'critical_bypass_silence': true,
        'short_break_minutes': 10,
        'long_break_minutes': 30,
        'long_break_every_n_cycles': 3,
        'difficulties': [
          for (final (level, xp, hp) in [
            ('easy', 1.2, 0.75),
            ('normal', 1, 1),
            ('hard', 0.85, 1.25),
          ])
            {
              'level': level,
              'xp_multiplier': xp,
              'hp_penalty_multiplier': hp,
              'coin_multiplier': 1,
            },
        ],
      }).toEntity();

      expect(
        overview,
        const SettingsOverview(
          level: 7,
          currentXp: 120,
          xpToNextLevel: 1852,
          settings: GameSettings(
            difficulty: GameDifficulty.hard,
            notificationDailyLimit: 10,
            silenceStart: '22:00',
            silenceEnd: '07:30',
            criticalBypassSilence: true,
            shortBreakMinutes: 10,
            longBreakMinutes: 30,
            longBreakEveryNCycles: 3,
          ),
          difficulties: settingsDifficulties,
        ),
      );
    });

    test('respuesta vacía usa los valores por defecto', () {
      final overview = SettingsOverviewModel.fromJson({}).toEntity();
      expect(overview.settings, const GameSettings());
      expect(overview.level, 1);
    });

    test('toRow escribe solo las columnas del jugador', () {
      expect(SettingsOverviewModel.toRow(const GameSettings()), {
        'difficulty': 'normal',
        'notification_daily_limit': null,
        'silence_window_start': null,
        'silence_window_end': null,
        'critical_bypass_silence': false,
        'short_break_minutes': 5,
        'long_break_minutes': 15,
        'long_break_every_n_cycles': 4,
      });
    });
  });

  group('SettingsRepositoryImpl', () {
    late MockSettingsRemoteDataSource remote;
    late SettingsRepositoryImpl repository;

    setUpAll(() => registerFallbackValue(const GameSettings()));

    setUp(() {
      remote = MockSettingsRemoteDataSource();
      repository = SettingsRepositoryImpl(remote);
    });

    test('getOverview devuelve la entidad', () async {
      when(() => remote.getOverview()).thenAnswer(
        (_) async => SettingsOverviewModel.fromJson({
          'level': 7,
          'current_xp': 120,
          'xp_to_next_level': 1852,
        }),
      );
      final result = await repository.getOverview();
      expect(result.map((o) => o.level), const Right<Failure, int>(7));
    });

    test('save guarda las reglas', () async {
      when(() => remote.save(any())).thenAnswer((_) async {});
      const settings = GameSettings(difficulty: GameDifficulty.easy);
      expect(await repository.save(settings), const Right(unit));
      verify(() => remote.save(settings)).called(1);
    });

    test('traduce el check de rango y los errores de red', () async {
      when(() => remote.save(any())).thenThrow(
        const ServerException(code: 'violates check', statusCode: '23514'),
      );
      expect(
        await repository.save(const GameSettings()),
        const Left(ServerFailure(SettingsMessages.outOfRange)),
      );
      when(() => remote.save(any())).thenThrow(const NetworkException());
      expect(
        (await repository.save(const GameSettings())).getLeft().toNullable(),
        isA<NetworkFailure>(),
      );
    });
  });
}
