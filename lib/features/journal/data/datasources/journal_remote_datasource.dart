import 'dart:async';

import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/features/journal/data/models/journal_board_model.dart';

/// RPC del Diario. Lanza [ServerException] o [NetworkException].
abstract class JournalRemoteDataSource {
  /// [day] en formato `yyyy-MM-dd`, fecha local del dispositivo.
  Future<JournalBoardModel> getJournal(String day);
}

class JournalRemoteDataSourceImpl implements JournalRemoteDataSource {
  const JournalRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<JournalBoardModel> getJournal(String day) async {
    try {
      return JournalBoardModel.fromJson(
        await _client.rpc<Map<String, dynamic>>(
          'journal_overview',
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
