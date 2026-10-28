import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/marketplace/domain/repositories/marketplace_repository.dart';

/// Canjea un ítem del Mercado negro.
class BuyBlackMarketItem implements UseCase<Unit, BlackMarketParams> {
  const BuyBlackMarketItem(this._repository);

  final MarketplaceRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(BlackMarketParams params) =>
      _repository.buyBlackMarketItem(params.code, habitId: params.habitId);
}

class BlackMarketParams extends Equatable {
  const BlackMarketParams(this.code, {this.habitId});

  final String code;

  /// Solo para "Recuperar racha".
  final String? habitId;

  @override
  List<Object?> get props => [code, habitId];
}
