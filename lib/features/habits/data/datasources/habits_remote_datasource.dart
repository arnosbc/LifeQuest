import 'dart:async';

import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/features/habits/data/models/habits_board_model.dart';
import 'package:proyecto_movil/features/habits/domain/entities/new_habit.dart';
import 'package:proyecto_movil/core/rewards/reward_feed.dart';

/// RPCs de Hábitos en Supabase. Lanza [ServerException] o [NetworkException].
abstract class HabitsRemoteDataSource {
  /// [day] en formato `yyyy-MM-dd`, fecha local del dispositivo.
  Future<HabitsBoardModel> getBoard(String day);

  Future<void> createHabit(NewHabit habit);

  Future<void> completeGoodHabit({
    required String habitId,
    required String day,
  });

  Future<void> registerBadHabit(String habitId);

  Future<void> renameHabit(String habitId, String name);

  Future<void> deleteHabit(String habitId);
}

class HabitsRemoteDataSourceImpl implements HabitsRemoteDataSource {
  const HabitsRemoteDataSourceImpl(this._client, [this._rewards]);

  final SupabaseClient _client;

  /// Recibe lo que pagó el servidor para el momento de recompensa.
  final RewardFeed? _rewards;

  @override
  Future<HabitsBoardModel> getBoard(String day) => _guard(() async {
    final json = await _client.rpc<Map<String, dynamic>>(
      'habits_overview',
      params: {'p_day': day},
    );
    return HabitsBoardModel.fromJson(json);
  });

  @override
  Future<void> createHabit(NewHabit habit) => _guard(() async {
    await _client.rpc<void>(
      'create_habit',
      params: {
        'p_name': habit.name,
        'p_type': habit.type.name,
        'p_frequency': habit.specificDays.isEmpty ? 'daily' : 'specific_days',
        'p_specific_days': habit.specificDays,
        'p_hp_penalty': habit.hpPenalty,
        'p_skill_id': habit.skillId,
      },
    );
    _rewards?.announce(
      'Nuevo hábito: ${habit.name}',
      'Ya está en tu lista. Te recordaremos cuando esté pendiente.',
    );
  });

  @override
  Future<void> completeGoodHabit({
    required String habitId,
    required String day,
  }) => _guard(
    () async => _rewards?.report(
      await _client.rpc<dynamic>(
        'complete_habit',
        params: {'p_habit_id': habitId, 'p_day': day},
      ),
    ),
  );

  @override
  Future<void> registerBadHabit(String habitId) => _guard(
    () async => _rewards?.report(
      await _client.rpc<dynamic>(
        'register_bad_habit',
        params: {'p_habit_id': habitId},
      ),
    ),
  );

  @override
  Future<void> renameHabit(String habitId, String name) => _guard(
    () => _client.rpc<void>(
      'rename_habit',
      params: {'p_habit_id': habitId, 'p_name': name},
    ),
  );

  @override
  Future<void> deleteHabit(String habitId) => _guard(
    () => _client.rpc<void>('delete_habit', params: {'p_habit_id': habitId}),
  );

  /// Las funciones SQL lanzan su motivo como mensaje (p. ej.
  /// `already_completed`); se pasa como [ServerException.code].
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
