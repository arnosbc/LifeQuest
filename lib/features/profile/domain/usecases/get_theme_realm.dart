import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/profile/domain/entities/theme_realm.dart';
import 'package:proyecto_movil/features/profile/domain/repositories/appearance_repository.dart';

/// Lee el tema del reino guardado; [ThemeRealm.bosque] si nunca se eligió.
class GetThemeRealm implements UseCase<ThemeRealm, NoParams> {
  const GetThemeRealm(this._repository);

  final AppearanceRepository _repository;

  @override
  Future<Either<Failure, ThemeRealm>> call(NoParams params) =>
      _repository.getThemeRealm();
}
