import 'package:equatable/equatable.dart';

import 'package:proyecto_movil/core/calendar/phone_event.dart';

export 'package:proyecto_movil/core/calendar/phone_event.dart'
    show CalendarAccess, PhoneEvent;

/// Única escala de urgencia de la app (`urgency_level`).
enum UrgencyLevel { low, medium, high }

/// La tarea que conviene hacer ahora, elegida por reglas (RF-097).
class PriorityTask extends Equatable {
  const PriorityTask({
    required this.id,
    required this.title,
    required this.priority,
    required this.xpReward,
    required this.coinReward,
    this.dueDate,
  });

  final String id;
  final String title;
  final UrgencyLevel priority;
  final int xpReward;
  final int coinReward;
  final DateTime? dueDate;

  @override
  List<Object?> get props => [
    id,
    title,
    priority,
    xpReward,
    coinReward,
    dueDate,
  ];
}

/// Hábito bueno programado para hoy.
class TodayHabit extends Equatable {
  const TodayHabit({
    required this.id,
    required this.name,
    required this.done,
    this.reminderAt,
  });

  final String id;
  final String name;
  final bool done;

  /// Hora de aviso de hoy (046); con ella sale en la agenda.
  final DateTime? reminderAt;

  @override
  List<Object?> get props => [id, name, done, reminderAt];
}

/// Meta sin avance en 7 días (046) con su siguiente tarea, si tiene.
class StalledGoal extends Equatable {
  const StalledGoal({
    required this.id,
    required this.title,
    this.nextTaskId,
    this.nextTaskTitle,
  });

  final String id;
  final String title;
  final String? nextTaskId;
  final String? nextTaskTitle;

  @override
  List<Object?> get props => [id, title, nextTaskId, nextTaskTitle];
}

/// Bloque de la agenda de hoy (tarea con hora, `day_agenda` de 032).
class AgendaBlock extends Equatable {
  const AgendaBlock({
    required this.id,
    required this.title,
    required this.start,
    this.minutes,
    this.done = false,
    this.repeats = false,
    this.isReminder = false,
  });

  final String id;
  final String title;

  /// Recordatorio (038): un instante con aviso, no un bloque de trabajo.
  final bool isReminder;

  /// Hora local de inicio.
  final DateTime start;
  final int? minutes;
  final bool done;
  final bool repeats;

  /// Fin del bloque; sin duración cuenta como 30 min.
  DateTime get end => start.add(Duration(minutes: minutes ?? 30));

  @override
  List<Object?> get props => [
    id,
    title,
    start,
    minutes,
    done,
    repeats,
    isReminder,
  ];
}

/// Tarea abierta sin hora, lista para ponerla en la agenda.
class UnscheduledTask extends Equatable {
  const UnscheduledTask({
    required this.id,
    required this.title,
    this.minutes,
    this.isReminder = false,
  });

  final String id;
  final String title;
  final int? minutes;
  final bool isReminder;

  @override
  List<Object?> get props => [id, title, minutes, isReminder];
}

/// Todo lo que muestra el Home, leído en una sola consulta.
class HomeDashboard extends Equatable {
  const HomeDashboard({
    required this.level,
    required this.currentXp,
    required this.xpToNextLevel,
    required this.coins,
    required this.hpCurrent,
    required this.hpMax,
    required this.isWeakened,
    required this.habits,
    required this.habitsDone,
    required this.habitsTotal,
    required this.streakDays,
    required this.tasksDone,
    required this.tasksTotal,
    required this.focusMinutes,
    this.displayName,
    this.characterClass,
    this.priorityTask,
    this.stalledGoal,
    this.agenda = const [],
    this.unscheduled = const [],
    this.events = const [],
    this.calendarAccess = CalendarAccess.denied,
  });

  final String? displayName;
  final String? characterClass;
  final int level;
  final int currentXp;
  final int xpToNextLevel;
  final int coins;
  final int hpCurrent;
  final int hpMax;

  /// HP ≤ 20 %: −10 % de XP y Monedas, sin bloquear nada (RF-034).
  final bool isWeakened;

  /// Null cuando no hay tareas abiertas.
  final PriorityTask? priorityTask;

  /// Null si todas las metas avanzaron esta semana.
  final StalledGoal? stalledGoal;
  final List<TodayHabit> habits;
  final int habitsDone;
  final int habitsTotal;

  /// Racha más larga en curso entre los hábitos de hoy.
  final int streakDays;
  final int tasksDone;
  final int tasksTotal;
  final int focusMinutes;

  /// Bloques de hoy por hora de inicio.
  final List<AgendaBlock> agenda;
  final List<UnscheduledTask> unscheduled;

  /// Eventos de hoy del calendario del teléfono (fase 4).
  final List<PhoneEvent> events;
  final CalendarAccess calendarAccess;

  /// El mismo día con los eventos del teléfono.
  HomeDashboard withCalendar(CalendarAccess access, List<PhoneEvent> events) =>
      HomeDashboard(
        displayName: displayName,
        characterClass: characterClass,
        level: level,
        currentXp: currentXp,
        xpToNextLevel: xpToNextLevel,
        coins: coins,
        hpCurrent: hpCurrent,
        hpMax: hpMax,
        isWeakened: isWeakened,
        priorityTask: priorityTask,
        stalledGoal: stalledGoal,
        habits: habits,
        habitsDone: habitsDone,
        habitsTotal: habitsTotal,
        streakDays: streakDays,
        tasksDone: tasksDone,
        tasksTotal: tasksTotal,
        focusMinutes: focusMinutes,
        agenda: agenda,
        unscheduled: unscheduled,
        events: events,
        calendarAccess: access,
      );

  @override
  List<Object?> get props => [
    displayName,
    characterClass,
    level,
    currentXp,
    xpToNextLevel,
    coins,
    hpCurrent,
    hpMax,
    isWeakened,
    priorityTask,
    stalledGoal,
    habits,
    habitsDone,
    habitsTotal,
    streakDays,
    tasksDone,
    tasksTotal,
    focusMinutes,
    agenda,
    unscheduled,
    events,
    calendarAccess,
  ];
}
