import 'dart:async';

import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/features/brain_dump/data/models/brain_dump_board_model.dart';
import 'package:proyecto_movil/features/brain_dump/domain/entities/brain_dump_board.dart';

/// RPCs del Brain Dump (023). Lanza [ServerException] o [NetworkException].
abstract class BrainDumpRemoteDataSource {
  Future<BrainDumpBoardModel> getBoard();

  Future<void> capture(String content);

  Future<void> file(String thoughtId, ThoughtShelf shelf);

  Future<void> convert(Conversion conversion);

  Future<void> delete(String thoughtId);
}

class BrainDumpRemoteDataSourceImpl implements BrainDumpRemoteDataSource {
  const BrainDumpRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<BrainDumpBoardModel> getBoard() => _guard(
    () async => BrainDumpBoardModel.fromJson(
      await _client.rpc<Map<String, dynamic>>('brain_dump_overview'),
    ),
  );

  @override
  Future<void> capture(String content) =>
      _rpc('capture_thought', {'p_content': content});

  @override
  Future<void> file(String thoughtId, ThoughtShelf shelf) =>
      _rpc('file_thought', {'p_id': thoughtId, 'p_status': shelf.name});

  @override
  Future<void> convert(Conversion c) => _rpc('convert_thought', {
    'p_id': c.thoughtId,
    'p_kind': c.kind.name,
    'p_title': c.title,
    'p_priority': c.priority.name,
    'p_due_date': c.dueDate?.toUtc().toIso8601String(),
    'p_delegated_to': c.delegatedTo,
  });

  @override
  Future<void> delete(String thoughtId) =>
      _rpc('delete_thought', {'p_id': thoughtId});

  Future<void> _rpc(String name, Map<String, dynamic> params) =>
      _guard(() => _client.rpc<void>(name, params: params));

  /// Las funciones SQL lanzan su motivo como mensaje; se pasa como
  /// [ServerException.code].
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
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
