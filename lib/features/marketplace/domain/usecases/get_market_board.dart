import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/marketplace/domain/entities/market_board.dart';
import 'package:proyecto_movil/features/marketplace/domain/repositories/marketplace_repository.dart';

/// Lee la bolsa, el catálogo y el Refugio.
class GetMarketBoard implements UseCase<MarketBoard, NoParams> {
  const GetMarketBoard(this._repository);

  final MarketplaceRepository _repository;

  @override
  Future<Either<Failure, MarketBoard>> call(NoParams params) =>
      _repository.getBoard();
}
