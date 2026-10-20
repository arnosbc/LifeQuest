import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/profile/data/repositories/appearance_repository_impl.dart';
import 'package:proyecto_movil/features/profile/domain/entities/theme_preference.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockAppearanceLocalDataSource local;
  late AppearanceRepositoryImpl repository;

  setUp(() {
    local = MockAppearanceLocalDataSource();
    repository = AppearanceRepositoryImpl(local);
  });

  test('sin tema guardado devuelve sistema', () async {
    when(() => local.getThemePreference()).thenAnswer((_) async => null);

    expect(
      await repository.getThemePreference(),
      const Right<Failure, ThemePreference>(ThemePreference.system),
    );
  });

  test('devuelve el tema guardado', () async {
    when(
      () => local.getThemePreference(),
    ).thenAnswer((_) async => ThemePreference.dark);

    expect(
      await repository.getThemePreference(),
      const Right<Failure, ThemePreference>(ThemePreference.dark),
    );
  });

  test('un fallo al guardar se vuelve CacheFailure', () async {
    when(
      () => local.saveThemePreference(ThemePreference.dark),
    ).thenThrow(const CacheException());

    final result = await repository.saveThemePreference(ThemePreference.dark);

    expect(result.getLeft().toNullable(), isA<CacheFailure>());
  });
}
