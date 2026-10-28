import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/marketplace/domain/repositories/marketplace_repository.dart';

/// Sube un nivel una mejora del Refugio (`huerto`, `biblioteca`, `estandarte`).
class UpgradeRefuge implements UseCase<Unit, String> {
  const UpgradeRefuge(this._repository);

  final MarketplaceRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(String params) =>
      _repository.upgradeRefuge(params);
}
