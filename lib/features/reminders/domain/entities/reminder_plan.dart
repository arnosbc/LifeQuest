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

/// Proyecto que pasaría a 🔴 ese día si no se avanza (042).
class ProjectAlert extends Equatable {
  const ProjectAlert({
    required this.id,
    required this.title,
    required this.day,
  });

  final String id;
  final String title;

  /// Día local (sin hora).
  final DateTime day;

  @override
  List<Object?> get props => [id, title, day];
}

/// Lo que el servidor pide avisar y la ventana de silencio de Ajustes.
class ReminderPlan extends Equatable {
  const ReminderPlan({
    this.tasks = const [],
    this.habits = const [],
    this.projects = const [],
    this.silenceStart,
    this.silenceEnd,
    this.dayClose = false,
  });

  final List<TaskReminder> tasks;

  /// Aviso diario a las 21:00 para cerrar el día (pantalla de revisión).
  final bool dayClose;
  final List<HabitReminder> habits;
  final List<ProjectAlert> projects;

  /// Minutos desde medianoche; null = sin ventana.
  final int? silenceStart;
  final int? silenceEnd;

  @override
  List<Object?> get props => [
    tasks,
    habits,
    projects,
    silenceStart,
    silenceEnd,
    dayClose,
  ];
}

/// Aviso listo para el teléfono.
class LocalReminder extends Equatable {
  const LocalReminder({
    required this.id,
    required this.title,
    required this.body,
    required this.at,
    this.taskId,
    this.habitId,
    this.projectId,
    this.weekly = false,
    this.daily = false,
  });

  final int id;
  final String title;
  final String body;
  final DateTime at;

  /// Solo los avisos de tareas llevan botones Hecha / Posponer.
  final String? taskId;

  /// Aviso de un hábito: lleva el botón Hecho.
  final String? habitId;

  /// Aviso de un proyecto atrasado (042).
  final String? projectId;

  /// Se repite cada semana el mismo día y hora (hábitos).
  final bool weekly;

  /// Se repite cada día a la misma hora.
  final bool daily;

  @override
  List<Object?> get props => [
    id,
    title,
    body,
    at,
    taskId,
    habitId,
    projectId,
    weekly,
    daily,
  ];
}
