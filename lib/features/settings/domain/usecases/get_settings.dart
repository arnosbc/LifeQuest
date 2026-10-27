import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/settings/domain/entities/game_settings.dart';
import 'package:proyecto_movil/features/settings/domain/repositories/settings_repository.dart';

/// Carga el progreso del personaje y sus reglas de Game Master.
class GetSettings implements UseCase<SettingsOverview, NoParams> {
  const GetSettings(this._repository);

  final SettingsRepository _repository;

  @override
  Future<Either<Failure, SettingsOverview>> call(NoParams params) =>
      _repository.getOverview();
}
