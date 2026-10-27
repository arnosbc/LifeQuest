import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/settings/domain/entities/game_settings.dart';
import 'package:proyecto_movil/features/settings/domain/usecases/get_settings.dart';
import 'package:proyecto_movil/features/settings/domain/usecases/save_game_settings.dart';

import '../../../helpers/mocks.dart';
import '../settings_fixtures.dart';

void main() {
  late MockSettingsRepository repository;

  setUpAll(() => registerFallbackValue(const GameSettings()));
  setUp(() => repository = MockSettingsRepository());

  test('GetSettings delega en el repositorio', () async {
    when(
      () => repository.getOverview(),
    ).thenAnswer((_) async => const Right(settingsOverview));
    expect(
      await GetSettings(repository)(const NoParams()),
      const Right(settingsOverview),
    );
  });

  test('SaveGameSettings guarda reglas válidas', () async {
    when(
      () => repository.save(any()),
    ).thenAnswer((_) async => const Right(unit));
    const settings = GameSettings(
      notificationDailyLimit: 50,
      silenceStart: '22:00',
      silenceEnd: '07:00',
    );
    expect(await SaveGameSettings(repository)(settings), const Right(unit));
  });

  test('SaveGameSettings rechaza valores fuera de rango sin llamar al '
      'servidor', () async {
    for (final settings in const [
      GameSettings(notificationDailyLimit: 0),
      GameSettings(silenceStart: '22:00'),
      GameSettings(shortBreakMinutes: 31),
      GameSettings(longBreakMinutes: 4),
      GameSettings(longBreakEveryNCycles: 9),
    ]) {
      expect(
        await SaveGameSettings(repository)(settings),
        const Left(ServerFailure(SettingsMessages.outOfRange)),
      );
    }
    verifyNever(() => repository.save(any()));
  });
}
