import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/marketplace/domain/repositories/marketplace_repository.dart';

/// Activa un Elixir guardado para la próxima Mazmorra.
class ActivateElixir implements UseCase<Unit, NoParams> {
  const ActivateElixir(this._repository);

  final MarketplaceRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) =>
      _repository.activateElixir();
}
