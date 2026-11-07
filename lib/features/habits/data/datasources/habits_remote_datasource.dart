import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/features/habits/data/models/habits_board_model.dart';
import 'package:proyecto_movil/features/habits/domain/entities/new_habit.dart';
import 'package:proyecto_movil/core/errors/supabase_guard.dart';

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

  Future<void> setReminder(String habitId, int? minuteOfDay);

  Future<void> deleteHabit(String habitId);
}

class HabitsRemoteDataSourceImpl implements HabitsRemoteDataSource {
  const HabitsRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<HabitsBoardModel> getBoard(String day) => guardSupabase(() async {
    final json = await _client.rpc<Map<String, dynamic>>(
      'habits_overview',
      params: {'p_day': day},
    );
    return HabitsBoardModel.fromJson(json);
  });

  @override
  Future<void> createHabit(NewHabit habit) => guardSupabase(() async {
    final id = await _client.rpc<String>(
      'create_habit',
      params: {
        'p_name': habit.name,
        'p_type': habit.type.name,
        'p_frequency': habit.specificDays.isEmpty ? 'daily' : 'specific_days',
        'p_specific_days': habit.specificDays,
        'p_hp_penalty': habit.hpPenalty,
        'p_skill_id': habit.skillId,
        // p_min_version llega con 039; sin texto no se envía.
        'p_min_version': ?habit.minVersion,
      },
    );
    final minute = habit.reminderMinuteOfDay;
    if (minute == null) return;
    // reminder_time tiene grant de columna (032); si falla, el hábito queda
    // creado sin aviso y el error se muestra.
    await _client
        .from('habits')
        .update({
          'reminder_time':
              '${(minute ~/ 60).toString().padLeft(2, '0')}:'
              '${(minute % 60).toString().padLeft(2, '0')}',
        })
        .eq('id', id);
  });

  @override
  Future<void> completeGoodHabit({
    required String habitId,
    required String day,
  }) => guardSupabase(
    () => _client.rpc<void>(
      'complete_habit',
      params: {'p_habit_id': habitId, 'p_day': day},
    ),
  );

  @override
  Future<void> registerBadHabit(String habitId) => guardSupabase(
    () => _client.rpc<void>(
      'register_bad_habit',
      params: {'p_habit_id': habitId},
    ),
  );

  @override
  Future<void> setReminder(String habitId, int? minuteOfDay) => guardSupabase(
    () => _client.rpc<void>(
      'set_habit_reminder',
      params: {
        'p_habit_id': habitId,
        'p_time': minuteOfDay == null
            ? null
            : '${(minuteOfDay ~/ 60).toString().padLeft(2, '0')}:'
                  '${(minuteOfDay % 60).toString().padLeft(2, '0')}',
      },
    ),
  );

  @override
  Future<void> renameHabit(String habitId, String name) => guardSupabase(
    () => _client.rpc<void>(
      'rename_habit',
      params: {'p_habit_id': habitId, 'p_name': name},
    ),
  );

  @override
  Future<void> deleteHabit(String habitId) => guardSupabase(
    () => _client.rpc<void>('delete_habit', params: {'p_habit_id': habitId}),
  );
}
