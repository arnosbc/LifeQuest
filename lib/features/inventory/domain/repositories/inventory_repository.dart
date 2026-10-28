import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/inventory/domain/entities/inventory_board.dart';

/// Contrato del Inventario. La capa data lo implementa.
abstract class InventoryRepository {
  Future<Either<Failure, InventoryBoard>> getInventory();
}
