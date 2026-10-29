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

  /// Registra este dispositivo (036) y devuelve su código.
  Future<String> registerDevice();

  /// Da de baja el código; funciona también sin sesión.
  Future<void> unregisterDevice(String token);

  /// Avisos que toca mostrar ahora en el dispositivo de [token] (036).
  /// [day] es `yyyy-MM-dd` y [time] `HH:mm`, ambos locales.
  Future<NotificationsModel> takeDeviceNotifications(
    String token,
    String day,
    String time,
  );
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

  @override
  Future<String> registerDevice() =>
      _guard(() => _client.rpc<String>('register_device'));

  @override
  Future<void> unregisterDevice(String token) => _guard(
    () => _client.rpc<void>('unregister_device', params: {'p_token': token}),
  );

  @override
  Future<NotificationsModel> takeDeviceNotifications(
    String token,
    String day,
    String time,
  ) => _guard(
    () async => NotificationsModel.fromJson(
      await _client.rpc<Map<String, dynamic>>(
        'device_notifications',
        params: {'p_token': token, 'p_day': day, 'p_time': time},
      ),
    ),
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
