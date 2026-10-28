import 'dart:async';

import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/features/tavern/data/models/tavern_board_model.dart';
import 'package:proyecto_movil/features/tavern/domain/entities/tavern_board.dart';

/// RPCs de la Taverna (019) y `complete_task` (005). Lanza
/// [ServerException] o [NetworkException].
abstract class TavernRemoteDataSource {
  Future<TavernBoardModel> getBoard();

  Future<void> createNpc(NewNpc npc);

  Future<void> acceptMission(String npcId, String title);

  Future<void> completeMission(String taskId);
}

class TavernRemoteDataSourceImpl implements TavernRemoteDataSource {
  const TavernRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

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
  Future<void> acceptMission(String npcId, String title) =>
      _rpc('accept_npc_mission', {'p_npc_id': npcId, 'p_title': title});

  @override
  Future<void> completeMission(String taskId) =>
      _rpc('complete_task', {'p_task_id': taskId});

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
