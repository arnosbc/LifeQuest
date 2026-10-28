import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/inventory/data/datasources/inventory_remote_datasource.dart';
import 'package:proyecto_movil/features/inventory/domain/entities/inventory_board.dart';
import 'package:proyecto_movil/features/inventory/domain/repositories/inventory_repository.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  const InventoryRepositoryImpl(this._remote);

  final InventoryRemoteDataSource _remote;

  @override
  Future<Either<Failure, InventoryBoard>> getInventory() async {
    try {
      return Right((await _remote.getInventory()).toEntity());
    } on NetworkException {
      return const Left(
        NetworkFailure(
          'No hay conexión con el servidor. Revisa tu internet y reintenta.',
        ),
      );
    } on ServerException {
      return const Left(
        ServerFailure(
          'No pudimos abrir tu Inventario. Inténtalo en un momento.',
        ),
      );
    }
  }
}
