import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/marketplace/domain/entities/market_board.dart';

/// Contrato del Marketplace. Todo gasto lo valida y cobra el servidor.
abstract class MarketplaceRepository {
  Future<Either<Failure, MarketBoard>> getBoard();

  /// Hotel o Mercado, por [code].
  Future<Either<Failure, Unit>> buyItem(String code);

  /// Mercado negro; "Recuperar racha" necesita [habitId].
  Future<Either<Failure, Unit>> buyBlackMarketItem(
    String code, {
    String? habitId,
  });

  Future<Either<Failure, Unit>> useRecoveryPass(String habitId);

  Future<Either<Failure, Unit>> upgradeRefuge(String building);

  Future<Either<Failure, Unit>> activateElixir();
}
