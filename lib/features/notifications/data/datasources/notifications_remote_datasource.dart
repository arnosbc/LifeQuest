import 'dart:async';

import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/features/notifications/data/models/notifications_model.dart';

/// RPCs del centro de avisos (029). Lanza [ServerException] o
/// [NetworkException].
abstract class NotificationsRemoteDataSource {
  /// [day] en formato `yyyy-MM-dd`, fecha local del dispositivo.
  Future<NotificationsModel> getNotifications(String day);

  Future<void> markRead(List<String>? ids);
}

class NotificationsRemoteDataSourceImpl
    implements NotificationsRemoteDataSource {
  const NotificationsRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<NotificationsModel> getNotifications(String day) => _guard(
    () async => NotificationsModel.fromJson(
      await _client.rpc<Map<String, dynamic>>(
        'notifications_overview',
        params: {'p_day': day},
      ),
    ),
  );

  @override
  Future<void> markRead(List<String>? ids) => _guard(
    () => _client.rpc<void>('mark_notifications_read', params: {'p_ids': ids}),
  );

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
