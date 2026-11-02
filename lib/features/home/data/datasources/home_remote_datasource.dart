import 'dart:async';

import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/core/rewards/reward_feed.dart';
import 'package:proyecto_movil/features/home/data/models/home_dashboard_model.dart';

/// RPCs del Home en Supabase. Lanza [ServerException] o [NetworkException].
abstract class HomeRemoteDataSource {
  /// [day] en formato `yyyy-MM-dd`, fecha local del dispositivo.
  Future<HomeDashboardModel> getDashboard({
    required String day,
    required int utcOffsetMinutes,
  });

  Future<void> completeHabit({required String habitId, required String day});

  /// Cobra el cofre del día (`claim_daily_chest`, 008).
  Future<void> claimDailyChest();

  /// Completa una tarea de la lista «Hoy» (`complete_task`, 005).
  Future<void> completeTask(String taskId);
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  const HomeRemoteDataSourceImpl(this._client, [this._rewards]);

  final SupabaseClient _client;

  /// Recibe lo que pagó el servidor para el momento de recompensa.
  final RewardFeed? _rewards;

  @override
  Future<HomeDashboardModel> getDashboard({
    required String day,
    required int utcOffsetMinutes,
  }) => _guard(() async {
    final json = await _client.rpc<Map<String, dynamic>?>(
      'home_dashboard',
      params: {'p_day': day, 'p_utc_offset_minutes': utcOffsetMinutes},
    );
    // Null: aún no existe la fila de profiles de este usuario.
    if (json == null) throw const ServerException(code: 'profile_not_found');
    final chest = await _client.rpc<Map<String, dynamic>>('daily_chest_status');
    return HomeDashboardModel.fromJson({...json, 'daily_chest': chest});
  });

  @override
  Future<void> completeHabit({required String habitId, required String day}) =>
      _guard(
        () async => _rewards?.report(
          await _client.rpc<dynamic>(
            'complete_habit',
            params: {'p_habit_id': habitId, 'p_day': day},
          ),
        ),
      );

  @override
  Future<void> completeTask(String taskId) => _guard(
    () async => _rewards?.report(
      await _client.rpc<dynamic>(
        'complete_task',
        params: {'p_task_id': taskId},
      ),
    ),
  );

  @override
  Future<void> claimDailyChest() => _guard(
    () async =>
        _rewards?.report(await _client.rpc<dynamic>('claim_daily_chest')),
  );

  /// Las funciones SQL lanzan su motivo como mensaje (p. ej.
  /// `already_completed`); se pasa como [ServerException.code].
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ServerException {
      rethrow;
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
