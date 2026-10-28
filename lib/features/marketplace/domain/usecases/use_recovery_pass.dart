import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/marketplace/domain/repositories/marketplace_repository.dart';

/// Usa un Pase de Recuperación sobre la racha rota del hábito indicado.
class UseRecoveryPass implements UseCase<Unit, String> {
  const UseRecoveryPass(this._repository);

  final MarketplaceRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(String params) =>
      _repository.useRecoveryPass(params);
}
