import 'dart:async';

import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/features/stats/data/models/stats_board_model.dart';

/// RPC de Estadísticas (025). Lanza [ServerException] o [NetworkException].
abstract class StatsRemoteDataSource {
  /// [day] en formato `yyyy-MM-dd`, fecha local del dispositivo.
  Future<StatsBoardModel> getStats(String day);
}

class StatsRemoteDataSourceImpl implements StatsRemoteDataSource {
  const StatsRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<StatsBoardModel> getStats(String day) async {
    try {
      return StatsBoardModel.fromJson(
        await _client.rpc<Map<String, dynamic>>(
          'stats_overview',
          params: {'p_day': day},
        ),
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
