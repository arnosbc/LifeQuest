import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/profile/domain/entities/theme_preference.dart';
import 'package:proyecto_movil/features/profile/domain/entities/theme_realm.dart';
import 'package:proyecto_movil/features/profile/presentation/blocs/appearance_bloc.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockGetThemePreference getThemePreference;
  late MockSaveThemePreference saveThemePreference;
  late MockGetThemeRealm getThemeRealm;
  late MockSaveThemeRealm saveThemeRealm;

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(ThemePreference.system);
    registerFallbackValue(ThemeRealm.bosque);
  });

  setUp(() {
    getThemePreference = MockGetThemePreference();
    saveThemePreference = MockSaveThemePreference();
    getThemeRealm = MockGetThemeRealm();
    saveThemeRealm = MockSaveThemeRealm();
    when(
      () => getThemeRealm(any()),
    ).thenAnswer((_) async => const Right(ThemeRealm.bosque));
  });

  AppearanceBloc build() => AppearanceBloc(
    getThemePreference: getThemePreference,
    saveThemePreference: saveThemePreference,
    getThemeRealm: getThemeRealm,
    saveThemeRealm: saveThemeRealm,
  );

  blocTest<AppearanceBloc, AppearanceState>(
    'carga el modo y el tema del reino guardados',
    setUp: () {
      when(
        () => getThemePreference(any()),
      ).thenAnswer((_) async => const Right(ThemePreference.dark));
      when(
        () => getThemeRealm(any()),
      ).thenAnswer((_) async => const Right(ThemeRealm.rio));
    },
    build: build,
    act: (bloc) => bloc.add(const AppearanceRequested()),
    expect: () => [
      const AppearanceSuccess(ThemePreference.dark, realm: ThemeRealm.rio),
    ],
  );

  blocTest<AppearanceBloc, AppearanceState>(
    'si no puede leerlos, sigue al sistema con Bosque',
    setUp: () {
      when(
        () => getThemePreference(any()),
      ).thenAnswer((_) async => const Left(CacheFailure('x')));
      when(
        () => getThemeRealm(any()),
      ).thenAnswer((_) async => const Left(CacheFailure('x')));
    },
    build: build,
    act: (bloc) => bloc.add(const AppearanceRequested()),
    expect: () => [const AppearanceSuccess(ThemePreference.system)],
  );

  blocTest<AppearanceBloc, AppearanceState>(
    'cambiar el modo lo aplica, lo guarda y conserva el tema del reino',
    setUp: () => when(
      () => saveThemePreference(any()),
    ).thenAnswer((_) async => const Right(unit)),
    build: build,
    seed: () =>
        const AppearanceSuccess(ThemePreference.light, realm: ThemeRealm.oro),
    act: (bloc) => bloc.add(const AppearanceThemeChanged(ThemePreference.dark)),
    expect: () => [
      const AppearanceSuccess(ThemePreference.dark, realm: ThemeRealm.oro),
    ],
    verify: (_) => verify(() => saveThemePreference(ThemePreference.dark)),
  );

  blocTest<AppearanceBloc, AppearanceState>(
    'si no se guarda, conserva el modo y avisa',
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

  blocTest<AppearanceBloc, AppearanceState>(
    'cambiar el tema del reino lo aplica, lo guarda y conserva el modo',
    setUp: () => when(
      () => saveThemeRealm(any()),
    ).thenAnswer((_) async => const Right(unit)),
    build: build,
    seed: () => const AppearanceSuccess(ThemePreference.dark),
    act: (bloc) => bloc.add(const AppearanceRealmChanged(ThemeRealm.brasa)),
    expect: () => [
      const AppearanceSuccess(ThemePreference.dark, realm: ThemeRealm.brasa),
    ],
    verify: (_) => verify(() => saveThemeRealm(ThemeRealm.brasa)),
  );

  blocTest<AppearanceBloc, AppearanceState>(
    'si el tema del reino no se guarda, se aplica igual y avisa',
    setUp: () => when(
      () => saveThemeRealm(any()),
    ).thenAnswer((_) async => const Left(CacheFailure('No se guardó.'))),
    build: build,
    act: (bloc) => bloc.add(const AppearanceRealmChanged(ThemeRealm.rio)),
    expect: () => [
      const AppearanceSuccess(ThemePreference.system, realm: ThemeRealm.rio),
      const AppearanceSuccess(
        ThemePreference.system,
        realm: ThemeRealm.rio,
        message: 'No se guardó.',
      ),
    ],
  );
}
