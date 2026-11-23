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

/// Lo que toca un día (048): tareas y hábitos pendientes y racha en peligro.
class DayOutlook extends Equatable {
  const DayOutlook({
    required this.day,
    this.tasks = 0,
    this.habits = 0,
    this.streakHabits = 0,
    this.bestStreak = 0,
  });

  /// Día local (sin hora).
  final DateTime day;
  final int tasks;

  /// Hábitos buenos que tocan y aún no se marcan.
  final int habits;

  /// De esos, los que tienen racha viva; [bestStreak] es la más larga.
  final int streakHabits;
  final int bestStreak;

  @override
  List<Object?> get props => [day, tasks, habits, streakHabits, bestStreak];
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
    this.days = const [],
    this.dailyLimit,
    this.criticalBypassSilence = false,
  });

  /// Hoy y los 6 días siguientes.
  final List<DayOutlook> days;

  /// Máximo de avisos al día (Ajustes); null = sin límite.
  final int? dailyLimit;
  final bool criticalBypassSilence;

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
    days,
    dailyLimit,
    criticalBypassSilence,
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
    this.kind,
    this.weekly = false,
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

  /// Avisos de la app sin entidad: `today` (resumen), `streak`, `close`.
  final String? kind;

  /// Se repite cada semana el mismo día y hora (hábitos).
  final bool weekly;

  LocalReminder withId(int id) => LocalReminder(
    id: id,
    title: title,
    body: body,
    at: at,
    taskId: taskId,
    habitId: habitId,
    projectId: projectId,
    kind: kind,
    weekly: weekly,
  );

  @override
  List<Object?> get props => [
    id,
    title,
    body,
    at,
    taskId,
    habitId,
    projectId,
    kind,
    weekly,
  ];
}
