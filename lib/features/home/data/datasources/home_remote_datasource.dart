import 'dart:async';

import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/features/home/data/models/home_dashboard_model.dart';

/// RPCs del Home en Supabase. Lanza [ServerException] o [NetworkException].
abstract class HomeRemoteDataSource {
  /// [day] en formato `yyyy-MM-dd`, fecha local del dispositivo.
  Future<HomeDashboardModel> getDashboard({
    required String day,
    required int utcOffsetMinutes,
  });

  Future<void> completeHabit({required String habitId, required String day});
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  const HomeRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

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
    return HomeDashboardModel.fromJson(json);
  });

  @override
  Future<void> completeHabit({required String habitId, required String day}) =>
      _guard(
        () => _client.rpc<void>(
          'complete_habit',
          params: {'p_habit_id': habitId, 'p_day': day},
        ),
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
