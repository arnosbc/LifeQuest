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

/// Tarea de la lista «Hoy» del Inicio: vence hoy, ya venció o es de prioridad
/// alta (038, plan S2).
class TodayTask extends Equatable {
  const TodayTask({
    required this.id,
    required this.title,
    required this.priority,
    required this.xpReward,
    this.dueDate,
    this.overdue = false,
  });

  final String id;
  final String title;
  final UrgencyLevel priority;
  final int xpReward;
  final DateTime? dueDate;
  final bool overdue;

  @override
  List<Object?> get props => [id, title, priority, xpReward, dueDate, overdue];
}

/// La última tarea abierta de un mentor (041).
class MentorTask extends Equatable {
  const MentorTask({
    required this.id,
    required this.title,
    required this.mentor,
    required this.xpReward,
  });

  final String id;
  final String title;
  final String mentor;
  final int xpReward;

  @override
  List<Object?> get props => [id, title, mentor, xpReward];
}

/// La meta activa que vence antes (041). El avance es la vida que ya se le
/// quitó, solo para mostrarlo (0–100 %).
class TopGoal extends Equatable {
  const TopGoal({
    required this.id,
    required this.title,
    required this.hp,
    required this.maxHp,
    this.dueDate,
  });

  final String id;
  final String title;
  final int hp;
  final int maxHp;
  final DateTime? dueDate;

  int get progress =>
      maxHp <= 0 ? 0 : ((maxHp - hp) * 100 / maxHp).round().clamp(0, 100);

  @override
  List<Object?> get props => [id, title, hp, maxHp, dueDate];
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

/// Cofre del día: se abre con N misiones que dieron Monedas hoy.
class DailyChest extends Equatable {
  const DailyChest({
    this.progress = 0,
    this.required = 3,
    this.coins = 15,
    this.claimed = false,
  });

  final int progress;
  final int required;
  final int coins;
  final bool claimed;

  bool get ready => !claimed && progress >= required;

  @override
  List<Object?> get props => [progress, required, coins, claimed];
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
    this.todayTasks = const [],
    this.mentorTask,
    this.inboxCount = 0,
    this.topGoal,
    this.chest = const DailyChest(),
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

  /// Lista «Hoy»; puede incluir la [priorityMission] (la pantalla la quita).
  final List<TodayTask> todayTasks;

  /// Tarjetas del Inicio (041): null o 0 si no hay.
  final MentorTask? mentorTask;
  final int inboxCount;
  final TopGoal? topGoal;
  final List<TodayHabit> habits;
  final int habitsDone;
  final int habitsTotal;

  /// Racha más larga en curso entre los hábitos de hoy.
  final int streakDays;
  final int missionsDone;
  final int missionsTotal;
  final int focusMinutes;
  final DailyChest chest;

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
    todayTasks,
    mentorTask,
    inboxCount,
    topGoal,
    habits,
    habitsDone,
    habitsTotal,
    streakDays,
    missionsDone,
    missionsTotal,
    focusMinutes,
    chest,
  ];
}
