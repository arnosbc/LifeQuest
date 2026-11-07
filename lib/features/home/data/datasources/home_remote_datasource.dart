import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/features/home/data/models/home_dashboard_model.dart';
import 'package:proyecto_movil/core/errors/supabase_guard.dart';

/// RPCs del Home en Supabase. Lanza [ServerException] o [NetworkException].
abstract class HomeRemoteDataSource {
  /// [day] en formato `yyyy-MM-dd`, fecha local del dispositivo.
  Future<HomeDashboardModel> getDashboard({
    required String day,
    required int utcOffsetMinutes,
  });

  Future<void> completeHabit({required String habitId, required String day});

  /// Pone la tarea en la agenda a [at] o la quita si es null.
  Future<void> scheduleTask({required String taskId, required DateTime? at});

  Future<void> completeTask(String taskId);
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  const HomeRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<HomeDashboardModel> getDashboard({
    required String day,
    required int utcOffsetMinutes,
  }) => guardSupabase(() async {
    final params = {'p_day': day, 'p_utc_offset_minutes': utcOffsetMinutes};
    final json = await _client.rpc<Map<String, dynamic>?>(
      'home_dashboard',
      params: params,
    );
    // Null: aún no existe la fila de profiles de este usuario.
    if (json == null) throw const ServerException(code: 'profile_not_found');
    final agenda = await _client.rpc<Map<String, dynamic>>(
      'day_agenda',
      params: params,
    );
    return HomeDashboardModel.fromJson({...json, 'agenda': agenda});
  });

  @override
  Future<void> completeHabit({required String habitId, required String day}) =>
      guardSupabase(
        () => _client.rpc<void>(
          'complete_habit',
          params: {'p_habit_id': habitId, 'p_day': day},
        ),
      );

  @override
  Future<void> scheduleTask({required String taskId, required DateTime? at}) =>
      guardSupabase(
        () => _client.rpc<void>(
          'schedule_task',
          params: {'p_task_id': taskId, 'p_at': at?.toUtc().toIso8601String()},
        ),
      );

  @override
  Future<void> completeTask(String taskId) => guardSupabase(
    () => _client.rpc<void>('complete_task', params: {'p_task_id': taskId}),
  );
}
