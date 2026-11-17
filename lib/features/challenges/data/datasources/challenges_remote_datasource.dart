import 'dart:async';

import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/core/rewards/reward_feed.dart';
import 'package:proyecto_movil/features/challenges/data/models/challenges_board_model.dart';

/// RPCs de Desafíos y Liga (052). Lanza [ServerException] o [NetworkException].
abstract class ChallengesRemoteDataSource {
  Future<ChallengesBoardModel> getChallenges();

  Future<void> claimChallenge(String key);
}

class ChallengesRemoteDataSourceImpl implements ChallengesRemoteDataSource {
  const ChallengesRemoteDataSourceImpl(this._client, [this._rewards]);

  final SupabaseClient _client;

  /// Recibe lo que pagó el servidor para el momento de recompensa.
  final RewardFeed? _rewards;

  @override
  Future<ChallengesBoardModel> getChallenges() => _guard(
    () async => ChallengesBoardModel.fromJson(
      await _client.rpc<Map<String, dynamic>>('challenges_overview'),
    ),
  );

  @override
  Future<void> claimChallenge(String key) => _guard(
    () async => _rewards?.report(
      await _client.rpc<dynamic>('claim_challenge', params: {'p_key': key}),
    ),
  );

  /// Las funciones SQL lanzan su motivo como mensaje; va en [ServerException.code].
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
