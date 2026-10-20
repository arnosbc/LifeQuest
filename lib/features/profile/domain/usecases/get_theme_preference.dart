import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/profile/domain/entities/theme_preference.dart';
import 'package:proyecto_movil/features/profile/domain/repositories/appearance_repository.dart';

/// Lee el tema guardado; [ThemePreference.system] si nunca se eligió uno.
class GetThemePreference implements UseCase<ThemePreference, NoParams> {
  const GetThemePreference(this._repository);

  final AppearanceRepository _repository;

  @override
  Future<Either<Failure, ThemePreference>> call(NoParams params) =>
      _repository.getThemePreference();
}
