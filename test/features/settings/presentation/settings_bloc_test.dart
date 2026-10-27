import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/settings/domain/entities/game_settings.dart';
import 'package:proyecto_movil/features/settings/presentation/blocs/settings_bloc.dart';

import '../../../helpers/mocks.dart';
import '../settings_fixtures.dart';

void main() {
  late MockGetSettings getSettings;
  late MockSaveGameSettings save;
  const hard = GameSettings(difficulty: GameDifficulty.hard);

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(const GameSettings());
  });

  setUp(() {
    getSettings = MockGetSettings();
    save = MockSaveGameSettings();
  });

  SettingsBloc build() =>
      SettingsBloc(getSettings: getSettings, saveGameSettings: save);

  blocTest<SettingsBloc, SettingsState>(
    'carga la Configuración',
    setUp: () => when(
      () => getSettings(any()),
    ).thenAnswer((_) async => const Right(settingsOverview)),
    build: build,
    act: (bloc) => bloc.add(const SettingsRequested()),
    expect: () => const [SettingsLoading(), SettingsSuccess(settingsOverview)],
  );

  blocTest<SettingsBloc, SettingsState>(
    'si la carga falla, muestra el motivo',
    setUp: () => when(
      () => getSettings(any()),
    ).thenAnswer((_) async => const Left(NetworkFailure('Sin red'))),
    build: build,
    act: (bloc) => bloc.add(const SettingsRequested()),
    expect: () => const [SettingsLoading(), SettingsFailure('Sin red')],
  );

  blocTest<SettingsBloc, SettingsState>(
    'un cambio se ve al instante y se confirma al guardar',
    setUp: () =>
        when(() => save(any())).thenAnswer((_) async => const Right(unit)),
    build: build,
    seed: () => const SettingsSuccess(settingsOverview),
    act: (bloc) => bloc.add(const GameSettingsChanged(hard)),
    expect: () => [
      SettingsSuccess(settingsOverview.withSettings(hard), saving: true),
      SettingsSuccess(
        settingsOverview.withSettings(hard),
        message: 'Cambios guardados.',
      ),
    ],
    verify: (_) => verify(() => save(hard)).called(1),
  );

  blocTest<SettingsBloc, SettingsState>(
    'si guardar falla, vuelve lo anterior con el aviso',
    setUp: () => when(
      () => save(any()),
    ).thenAnswer((_) async => const Left(ServerFailure('Fuera de rango'))),
    build: build,
    seed: () => const SettingsSuccess(settingsOverview),
    act: (bloc) => bloc.add(const GameSettingsChanged(hard)),
    expect: () => [
      SettingsSuccess(settingsOverview.withSettings(hard), saving: true),
      const SettingsSuccess(settingsOverview, message: 'Fuera de rango'),
    ],
  );

  blocTest<SettingsBloc, SettingsState>(
    'sin cambios no guarda nada',
    build: build,
    seed: () => const SettingsSuccess(settingsOverview),
    act: (bloc) => bloc.add(const GameSettingsChanged(GameSettings())),
    expect: () => const <SettingsState>[],
    verify: (_) => verifyNever(() => save(any())),
  );
}
