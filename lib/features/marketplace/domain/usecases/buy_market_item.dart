import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/marketplace/domain/repositories/marketplace_repository.dart';

/// Compra un ítem del Hotel o del Mercado; el parámetro es su código.
class BuyMarketItem implements UseCase<Unit, String> {
  const BuyMarketItem(this._repository);

  final MarketplaceRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(String params) =>
      _repository.buyItem(params);
}
