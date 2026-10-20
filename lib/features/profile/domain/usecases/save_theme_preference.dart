import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/profile/domain/entities/theme_preference.dart';
import 'package:proyecto_movil/features/profile/domain/repositories/appearance_repository.dart';

class SaveThemePreference implements UseCase<Unit, ThemePreference> {
  const SaveThemePreference(this._repository);

  final AppearanceRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(ThemePreference theme) =>
      _repository.saveThemePreference(theme);
}
