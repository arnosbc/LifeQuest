import 'dart:async';

import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/features/reminders/data/models/reminder_plan_model.dart';

/// RPC `sync_reminders`. Lanza [ServerException] o [NetworkException].
abstract class RemindersRemoteDataSource {
  Future<ReminderPlanModel> sync(String timeZone);
}

class RemindersRemoteDataSourceImpl implements RemindersRemoteDataSource {
  const RemindersRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<ReminderPlanModel> sync(String timeZone) async {
    try {
      return ReminderPlanModel(
        await _client.rpc<Map<String, dynamic>>(
          'sync_reminders',
          params: {'p_time_zone': timeZone},
        ),
      );
    } on PostgrestException catch (error) {
      throw ServerException(code: error.message, statusCode: error.code);
    } on ClientException catch (error) {
      throw NetworkException(error.message);
    } on TimeoutException catch (error) {
      throw NetworkException(error.message);
    }
  }
}
