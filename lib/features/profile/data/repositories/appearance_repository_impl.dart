import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/profile/data/datasources/appearance_local_datasource.dart';
import 'package:proyecto_movil/features/profile/domain/entities/theme_preference.dart';
import 'package:proyecto_movil/features/profile/domain/entities/theme_realm.dart';
import 'package:proyecto_movil/features/profile/domain/repositories/appearance_repository.dart';

class AppearanceRepositoryImpl implements AppearanceRepository {
  const AppearanceRepositoryImpl(this._local);

  final AppearanceLocalDataSource _local;

  @override
  Future<Either<Failure, ThemePreference>> getThemePreference() async {
    try {
      return Right(await _local.getThemePreference() ?? ThemePreference.system);
    } on CacheException {
      return const Left(CacheFailure('No pudimos leer tu tema guardado.'));
    }
  }

  @override
  Future<Either<Failure, Unit>> saveThemePreference(
    ThemePreference theme,
  ) async {
    try {
      await _local.saveThemePreference(theme);
      return const Right(unit);
    } on CacheException {
      return const Left(
        CacheFailure(
          'No pudimos guardar tu tema. Se aplicará hasta que cierres la app.',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, ThemeRealm>> getThemeRealm() async {
    try {
      return Right(await _local.getThemeRealm() ?? ThemeRealm.bosque);
    } on CacheException {
      return const Left(CacheFailure('No pudimos leer tu tema guardado.'));
    }
  }

  @override
  Future<Either<Failure, Unit>> saveThemeRealm(ThemeRealm realm) async {
    try {
      await _local.saveThemeRealm(realm);
      return const Right(unit);
    } on CacheException {
      return const Left(
        CacheFailure(
          'No pudimos guardar tu tema. Se aplicará hasta que cierres la app.',
        ),
      );
    }
  }
}
