import 'dart:async';

import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/features/inventory/data/models/inventory_board_model.dart';

/// RPC del Inventario (026). Lanza [ServerException] o [NetworkException].
abstract class InventoryRemoteDataSource {
  Future<InventoryBoardModel> getInventory();
}

class InventoryRemoteDataSourceImpl implements InventoryRemoteDataSource {
  const InventoryRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<InventoryBoardModel> getInventory() async {
    try {
      return InventoryBoardModel.fromJson(
        await _client.rpc<Map<String, dynamic>>('inventory_overview'),
      );
    } on PostgrestException catch (error) {
      throw ServerException(
        code: error.message,
        message: error.details?.toString(),
        statusCode: error.code,
      );
    } on ClientException catch (error) {
      throw NetworkException(error.message);
    } on TimeoutException catch (error) {
      throw NetworkException(error.message);
    }
  }
}
