import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/settings/domain/entities/game_settings.dart';
import 'package:proyecto_movil/features/settings/domain/repositories/settings_repository.dart';

/// Guarda las reglas de Game Master si están dentro de sus rangos.
class SaveGameSettings implements UseCase<Unit, GameSettings> {
  const SaveGameSettings(this._repository);

  final SettingsRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(GameSettings params) async =>
      params.isValid
      ? _repository.save(params)
      : const Left(ServerFailure(SettingsMessages.outOfRange));
}

/// Mensajes compartidos entre el usecase y el repositorio.
abstract final class SettingsMessages {
  static const outOfRange =
      'Ese valor está fuera de lo permitido. Revísalo y vuelve a guardar.';
}
