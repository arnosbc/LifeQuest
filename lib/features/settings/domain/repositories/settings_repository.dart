import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/settings/domain/entities/game_settings.dart';

/// Contrato de Configuración. La capa data lo implementa.
abstract class SettingsRepository {
  Future<Either<Failure, SettingsOverview>> getOverview();

  Future<Either<Failure, Unit>> save(GameSettings settings);
}
