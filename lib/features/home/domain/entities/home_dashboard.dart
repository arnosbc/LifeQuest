import 'package:equatable/equatable.dart';

/// Única escala de urgencia de la app (`urgency_level`).
enum UrgencyLevel { low, medium, high }

/// La "Misión actual" que RPGenie elige para el Home (RF-097).
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
  ];
}
