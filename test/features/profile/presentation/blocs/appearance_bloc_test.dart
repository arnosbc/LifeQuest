import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/profile/domain/entities/theme_preference.dart';
import 'package:proyecto_movil/features/profile/presentation/blocs/appearance_bloc.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockGetThemePreference getThemePreference;
  late MockSaveThemePreference saveThemePreference;

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(ThemePreference.system);
  });

  setUp(() {
    getThemePreference = MockGetThemePreference();
    saveThemePreference = MockSaveThemePreference();
  });

  AppearanceBloc build() => AppearanceBloc(
    getThemePreference: getThemePreference,
    saveThemePreference: saveThemePreference,
  );

  blocTest<AppearanceBloc, AppearanceState>(
    'carga el tema guardado',
    setUp: () => when(
      () => getThemePreference(any()),
    ).thenAnswer((_) async => const Right(ThemePreference.dark)),
    build: build,
    act: (bloc) => bloc.add(const AppearanceRequested()),
    expect: () => [const AppearanceSuccess(ThemePreference.dark)],
  );

  blocTest<AppearanceBloc, AppearanceState>(
    'si no puede leerlo, sigue al sistema',
    setUp: () => when(
      () => getThemePreference(any()),
    ).thenAnswer((_) async => const Left(CacheFailure('x'))),
    build: build,
    act: (bloc) => bloc.add(const AppearanceRequested()),
    expect: () => [const AppearanceSuccess(ThemePreference.system)],
  );

  blocTest<AppearanceBloc, AppearanceState>(
    'cambiar el tema lo aplica y lo guarda',
    setUp: () => when(
      () => saveThemePreference(any()),
    ).thenAnswer((_) async => const Right(unit)),
    build: build,
    act: (bloc) => bloc.add(const AppearanceThemeChanged(ThemePreference.dark)),
    expect: () => [const AppearanceSuccess(ThemePreference.dark)],
    verify: (_) => verify(() => saveThemePreference(ThemePreference.dark)),
  );

  blocTest<AppearanceBloc, AppearanceState>(
    'si no se guarda, conserva el tema y avisa',
    setUp: () => when(
      () => saveThemePreference(any()),
    ).thenAnswer((_) async => const Left(CacheFailure('No se guardó.'))),
    build: build,
    act: (bloc) =>
        bloc.add(const AppearanceThemeChanged(ThemePreference.light)),
    expect: () => [
      const AppearanceSuccess(ThemePreference.light),
      const AppearanceSuccess(ThemePreference.light, message: 'No se guardó.'),
    ],
  );
}
