import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/profile/domain/entities/theme_preference.dart';

/// Preferencias de apariencia guardadas en el dispositivo.
abstract interface class AppearanceRepository {
  Future<Either<Failure, ThemePreference>> getThemePreference();

  Future<Either<Failure, Unit>> saveThemePreference(ThemePreference theme);
}
