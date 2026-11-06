import 'package:equatable/equatable.dart';

import 'package:proyecto_movil/core/calendar/phone_event.dart';

export 'package:proyecto_movil/core/calendar/phone_event.dart'
    show CalendarAccess, PhoneEvent;

/// Única escala de urgencia de la app (`urgency_level`).
enum UrgencyLevel { low, medium, high }

/// La tarea que conviene hacer ahora, elegida por reglas (RF-097).
class PriorityMission extends Equatable {
  const PriorityMission({
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
  const TodayHabit({required this.id, required this.name, required this.done});

  final String id;
  final String name;
  final bool done;

  @override
  List<Object?> get props => [id, name, done];
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
  });

  final String id;
  final String title;

  /// Hora local de inicio.
  final DateTime start;
  final int? minutes;
  final bool done;
  final bool repeats;

  /// Fin del bloque; sin duración cuenta como 30 min.
  DateTime get end => start.add(Duration(minutes: minutes ?? 30));

  @override
  List<Object?> get props => [id, title, start, minutes, done, repeats];
}

/// Tarea abierta sin hora, lista para ponerla en la agenda.
class UnscheduledTask extends Equatable {
  const UnscheduledTask({required this.id, required this.title, this.minutes});

  final String id;
  final String title;
  final int? minutes;

  @override
  List<Object?> get props => [id, title, minutes];
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
    required this.missionsDone,
    required this.missionsTotal,
    required this.focusMinutes,
    this.displayName,
    this.characterClass,
    this.priorityMission,
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

  /// Null cuando no hay misiones abiertas.
  final PriorityMission? priorityMission;
  final List<TodayHabit> habits;
  final int habitsDone;
  final int habitsTotal;

  /// Racha más larga en curso entre los hábitos de hoy.
  final int streakDays;
  final int missionsDone;
  final int missionsTotal;
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
        priorityMission: priorityMission,
        habits: habits,
        habitsDone: habitsDone,
        habitsTotal: habitsTotal,
        streakDays: streakDays,
        missionsDone: missionsDone,
        missionsTotal: missionsTotal,
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
    priorityMission,
    habits,
    habitsDone,
    habitsTotal,
    streakDays,
    missionsDone,
    missionsTotal,
    focusMinutes,
    agenda,
    unscheduled,
    events,
    calendarAccess,
  ];
}
