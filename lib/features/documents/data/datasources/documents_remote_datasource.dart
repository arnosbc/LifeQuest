import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/features/documents/data/models/work_document_model.dart';
import 'package:proyecto_movil/features/documents/domain/entities/work_document.dart';

/// Tabla `documents` (046), protegida por RLS. Lanza [ServerException] o
/// [NetworkException].
abstract interface class DocumentsRemoteDataSource {
  /// Todos los del usuario, también los marcados como borrados.
  Future<List<WorkDocument>> fetchAll();

  Future<void> upsert(List<WorkDocument> documents);

  /// Sube una imagen al bucket `documents` (047), en la carpeta del usuario.
  Future<void> uploadImage(String documentId, String name, Uint8List bytes);

  Future<Uint8List> downloadImage(String documentId, String name);
}

class DocumentsRemoteDataSourceImpl implements DocumentsRemoteDataSource {
  const DocumentsRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<List<WorkDocument>> fetchAll() => _guard(() async {
    final rows = await _client
        .from('documents')
        .select(
          'id, title, content, updated_at, task_id, template, deleted_at',
        );
    return [for (final row in rows) WorkDocumentModel.fromJson(row)];
  });

  @override
  Future<void> upsert(List<WorkDocument> documents) => _guard(() async {
    if (documents.isEmpty) return;
    await _client.from('documents').upsert([
      for (final d in documents) WorkDocumentModel.toJson(d),
    ]);
  });

  String _path(String documentId, String name) =>
      '${_client.auth.currentUser?.id}/$documentId/$name';

  @override
  Future<void> uploadImage(String documentId, String name, Uint8List bytes) =>
      _guard(() async {
        final ext = name.split('.').last.toLowerCase();
        await _client.storage
            .from('documents')
            .uploadBinary(
              _path(documentId, name),
              bytes,
              fileOptions: FileOptions(
                upsert: true,
                contentType: ext == 'jpg' ? 'image/jpeg' : 'image/$ext',
              ),
            );
      });

  @override
  Future<Uint8List> downloadImage(String documentId, String name) => _guard(
    () => _client.storage.from('documents').download(_path(documentId, name)),
  );

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on StorageException catch (error) {
      throw ServerException(code: error.message, statusCode: error.statusCode);
    } on PostgrestException catch (error) {
      throw ServerException(
        code: error.message,
        message: error.details?.toString(),
        statusCode: error.code,
      );
    } on ClientException catch (error) {
      throw NetworkException(error.message);
    } on SocketException catch (error) {
      throw NetworkException(error.message);
    } on TimeoutException catch (error) {
      throw NetworkException(error.message);
    }
  }
}
