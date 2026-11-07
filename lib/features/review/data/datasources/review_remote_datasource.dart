import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/features/review/data/models/weekly_review_model.dart';
import 'package:proyecto_movil/core/errors/supabase_guard.dart';

/// RPCs de la Revisión semanal. Lanza [ServerException] o [NetworkException].
abstract class ReviewRemoteDataSource {
  Future<WeeklyReviewModel> getReview({
    required String day,
    required int utcOffsetMinutes,
  });

  Future<void> postpone(String taskId, {int days = 7});

  Future<void> drop(String taskId);
}

class ReviewRemoteDataSourceImpl implements ReviewRemoteDataSource {
  const ReviewRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<WeeklyReviewModel> getReview({
    required String day,
    required int utcOffsetMinutes,
  }) => guardSupabase(() async {
    final json = await _client.rpc<Map<String, dynamic>>(
      'weekly_review',
      params: {'p_day': day, 'p_utc_offset_minutes': utcOffsetMinutes},
    );
    return WeeklyReviewModel(json);
  });

  @override
  Future<void> postpone(String taskId, {int days = 7}) => guardSupabase(
    // p_days llega con 039; 7 usa el valor por defecto y sirve sin ella.
    () => _client.rpc<void>(
      'postpone_task',
      params: {'p_task_id': taskId, if (days != 7) 'p_days': days},
    ),
  );

  /// `delete_task` (028): no deja borrar lo que ya tiene sesiones de foco.
  @override
  Future<void> drop(String taskId) => guardSupabase(
    () => _client.rpc<void>('delete_task', params: {'p_task_id': taskId}),
  );
}
