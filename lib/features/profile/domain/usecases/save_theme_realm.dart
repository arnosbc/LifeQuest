import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/profile/domain/entities/theme_realm.dart';
import 'package:proyecto_movil/features/profile/domain/repositories/appearance_repository.dart';

class SaveThemeRealm implements UseCase<Unit, ThemeRealm> {
  const SaveThemeRealm(this._repository);

  final AppearanceRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(ThemeRealm realm) =>
      _repository.saveThemeRealm(realm);
}
