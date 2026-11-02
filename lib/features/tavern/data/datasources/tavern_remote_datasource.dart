import 'dart:async';

import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/features/tavern/data/models/tavern_board_model.dart';
import 'package:proyecto_movil/features/tavern/domain/entities/tavern_board.dart';
import 'package:proyecto_movil/core/rewards/reward_feed.dart';
import 'package:proyecto_movil/core/entities/task_guide.dart';

/// RPCs de la Taverna (019) y `complete_task` (005). Lanza
/// [ServerException] o [NetworkException].
abstract class TavernRemoteDataSource {
  Future<TavernBoardModel> getBoard();

  Future<void> createNpc(NewNpc npc);

  Future<NpcMissionSuggestion?> suggestMission(String npcId);

  /// La tarea y [guide] se crean juntas para no dejar pasos sin asignar.
  Future<void> acceptMission(
    String npcId,
    String title, {
    String? description,
    TaskGuide? guide,
  });

  Future<void> completeMission(String taskId);

  /// Sube el archivo al bucket `npc-context` y pide a `npc-context` que lo
  /// resuma y lo guarde (032).
  Future<void> addDocument(NewNpcDocument document);

  Future<void> removeDocument(String documentId);

  Future<void> renameNpc(String npcId, String name);

  Future<void> deleteNpc(String npcId);
}

/// Motivos de `npc-context` que tienen su propio aviso; el resto llega como
/// `document_failed` con el motivo en [ServerException.statusCode].
const _documentErrors = {
  'npc_document_limit',
  'unsupported_type',
  'empty_document',
  'unreadable_document',
  'npc_not_found',
};

const _contentTypes = {
  'pdf': 'application/pdf',
  'docx':
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'md': 'text/markdown',
  'markdown': 'text/markdown',
};

class TavernRemoteDataSourceImpl implements TavernRemoteDataSource {
  const TavernRemoteDataSourceImpl(this._client, [this._rewards]);

  final SupabaseClient _client;

  /// Recibe lo que pagó el servidor para el momento de recompensa.
  final RewardFeed? _rewards;

  @override
  Future<TavernBoardModel> getBoard() => _guard(
    () async => TavernBoardModel.fromJson(
      await _client.rpc<Map<String, dynamic>>('tavern_overview'),
    ),
  );

  @override
  Future<void> createNpc(NewNpc npc) => _rpc('create_npc', {
    'p_name': npc.name,
    'p_skill_id': npc.skillId,
    'p_frequency': npc.frequency.name,
    'p_noble_mission': npc.nobleMission,
  });

  @override
  Future<NpcMissionSuggestion?> suggestMission(String npcId) => _guard(
    () async {
      try {
        final response = await _client.functions.invoke(
          'npc-mission',
          body: {'npc_id': npcId},
        );
        final data = response.data as Map?;
        final title = data?['title'];
        if (title is String && title.isNotEmpty) {
          final guide = data?['guide'];
          return NpcMissionSuggestion(
            title: title,
            guide: guide is String && guide.isNotEmpty ? guide : null,
            structured: _guide(data?['structured']),
          );
        }
        // Motivo de la Edge Function (p. ej. gemini_429) para el aviso.
        if (data?['reason'] case final String reason) {
          throw ServerException(code: 'suggestion_failed', statusCode: reason);
        }
        return null;
      } on FunctionException catch (error) {
        throw ServerException(
          code: 'suggestion_failed',
          statusCode: '${error.status}',
        );
      }
    },
  );

  @override
  Future<void> acceptMission(
    String npcId,
    String title, {
    String? description,
    TaskGuide? guide,
  }) => _guard(() async {
    await _client.rpc<dynamic>(
      'accept_npc_mission',
      params: {
        'p_npc_id': npcId,
        'p_title': title,
        'p_description': description,
        'p_guide': guide?.toJson(),
      },
    );
  });

  static TaskGuide? _guide(Object? raw) {
    if (raw is! Map) return null;
    List<String> list(Object? v) => v is List
        ? [
            for (final x in v)
              if (x is String && x.isNotEmpty) x,
          ]
        : const [];
    final steps = list(raw['steps']);
    if (steps.isEmpty) return null;
    final objective = raw['objective'];
    return TaskGuide(
      objective: objective is String && objective.isNotEmpty ? objective : null,
      steps: steps,
      hints: list(raw['hints']),
      search: list(raw['search']),
    );
  }

  @override
  Future<void> completeMission(String taskId) => _guard(
    () async => _rewards?.report(
      await _client.rpc<dynamic>(
        'complete_task',
        params: {'p_task_id': taskId},
      ),
    ),
  );

  @override
  Future<void> addDocument(NewNpcDocument document) => _guard(() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw const ServerException(code: 'not_authenticated');
    // Storage no admite tildes ni espacios en la ruta.
    final safe = document.fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final path =
        '$uid/${document.npcId}/${DateTime.now().millisecondsSinceEpoch}_$safe';
    try {
      await _client.storage
          .from('npc-context')
          .uploadBinary(
            path,
            document.bytes,
            fileOptions: FileOptions(
              contentType: _contentTypes[document.extension],
            ),
          );
    } on StorageException catch (error) {
      throw ServerException(
        code: 'upload_failed',
        statusCode: error.statusCode,
      );
    }
    try {
      final response = await _client.functions.invoke(
        'npc-context',
        body: {'npc_id': document.npcId, 'path': path, 'title': document.title},
      );
      if ((response.data as Map?)?['error'] case final String error) {
        throw _documentErrors.contains(error)
            ? ServerException(code: error)
            : ServerException(code: 'document_failed', statusCode: error);
      }
    } on FunctionException catch (error) {
      throw ServerException(
        code: 'document_failed',
        statusCode: '${error.status}',
      );
    }
  });

  @override
  Future<void> removeDocument(String documentId) => _guard(() async {
    final path = await _client.rpc<String>(
      'remove_npc_document',
      params: {'p_id': documentId},
    );
    try {
      await _client.storage.from('npc-context').remove([path]);
    } on StorageException {
      // La fila ya no está: el documento deja de usarse aunque el archivo
      // quede huérfano en el bucket.
    }
  });

  @override
  Future<void> renameNpc(String npcId, String name) =>
      _rpc('rename_npc', {'p_npc_id': npcId, 'p_name': name});

  @override
  Future<void> deleteNpc(String npcId) =>
      _rpc('delete_npc', {'p_npc_id': npcId});

  Future<void> _rpc(String name, Map<String, dynamic> params) =>
      _guard(() => _client.rpc<void>(name, params: params));

  /// Las funciones SQL lanzan su motivo como mensaje (p. ej.
  /// `npc_limit_reached`); se pasa como [ServerException.code].
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
