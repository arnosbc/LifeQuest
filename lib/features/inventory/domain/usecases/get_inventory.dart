import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/inventory/domain/entities/inventory_board.dart';
import 'package:proyecto_movil/features/inventory/domain/repositories/inventory_repository.dart';

/// Lee los objetos, los logros y los títulos.
class GetInventory implements UseCase<InventoryBoard, NoParams> {
  const GetInventory(this._repository);

  final InventoryRepository _repository;

  @override
  Future<Either<Failure, InventoryBoard>> call(NoParams params) =>
      _repository.getInventory();
}
