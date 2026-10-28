import 'dart:async';

import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/features/vision/data/models/vision_board_model.dart';
import 'package:proyecto_movil/features/vision/domain/entities/vision_board.dart';

/// RPCs del Vision Board (024). Lanza [ServerException] o
/// [NetworkException].
abstract class VisionRemoteDataSource {
  Future<VisionBoardModel> getBoard();

  Future<void> save(String content);

  Future<void> setLink(VisionItem item, bool linked);
}

class VisionRemoteDataSourceImpl implements VisionRemoteDataSource {
  const VisionRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<VisionBoardModel> getBoard() => _guard(
    () async => VisionBoardModel.fromJson(
      await _client.rpc<Map<String, dynamic>>('vision_overview'),
    ),
  );

  @override
  Future<void> save(String content) => _guard(
    () => _client.rpc<void>('save_vision', params: {'p_content': content}),
  );

  @override
  Future<void> setLink(VisionItem item, bool linked) => _guard(
    () => _client.rpc<void>(
      'set_vision_link',
      params: {'p_kind': item.kind.name, 'p_id': item.id, 'p_linked': linked},
    ),
  );

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
