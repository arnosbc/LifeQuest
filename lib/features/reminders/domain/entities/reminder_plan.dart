import 'package:equatable/equatable.dart';

/// Tarea con hora y aviso (RPC `sync_reminders`, 032).
class TaskReminder extends Equatable {
  const TaskReminder({
    required this.id,
    required this.title,
    required this.startsAt,
    required this.minutesBefore,
  });

  final String id;
  final String title;

  /// Inicio del bloque, hora local.
  final DateTime startsAt;
  final int minutesBefore;

  @override
  List<Object?> get props => [id, title, startsAt, minutesBefore];
}

/// Hábito bueno con hora de aviso.
class HabitReminder extends Equatable {
  const HabitReminder({
    required this.id,
    required this.name,
    required this.minuteOfDay,
    required this.days,
  });

  final String id;
  final String name;
  final int minuteOfDay;

  /// 0 = domingo … 6 = sábado, como `habits.specific_days`.
  final List<int> days;

  @override
  List<Object?> get props => [id, name, minuteOfDay, days];
}

/// Lo que el servidor pide avisar y la ventana de silencio de Ajustes.
class ReminderPlan extends Equatable {
  const ReminderPlan({
    this.tasks = const [],
    this.habits = const [],
    this.silenceStart,
    this.silenceEnd,
  });

  final List<TaskReminder> tasks;
  final List<HabitReminder> habits;

  /// Minutos desde medianoche; null = sin ventana.
  final int? silenceStart;
  final int? silenceEnd;

  @override
  List<Object?> get props => [tasks, habits, silenceStart, silenceEnd];
}

/// Aviso listo para el teléfono.
class LocalReminder extends Equatable {
  const LocalReminder({
    required this.id,
    required this.title,
    required this.body,
    required this.at,
    this.taskId,
    this.weekly = false,
  });

  final int id;
  final String title;
  final String body;
  final DateTime at;

  /// Solo los avisos de tareas llevan botones Hecha / Posponer.
  final String? taskId;

  /// Se repite cada semana el mismo día y hora (hábitos).
  final bool weekly;

  @override
  List<Object?> get props => [id, title, body, at, taskId, weekly];
}
