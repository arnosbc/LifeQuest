import 'package:equatable/equatable.dart';

/// Bueno: da recompensa una vez por día. Malo: resta vida por evento.
enum HabitType { good, bad }

class Habit extends Equatable {
  const Habit({
    required this.id,
    required this.name,
    required this.type,
    this.specificDays = const [],
    this.skillName,
    this.hpPenalty = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.scheduledToday = true,
    this.doneToday = false,
    this.todayCount = 0,
    this.week = const [],
  });

  final String id;
  final String name;
  final HabitType type;

  /// Días que toca (0 = domingo … 6 = sábado); vacío = diario.
  final List<int> specificDays;
  final String? skillName;

  /// Vida que resta cada evento de un hábito malo (3, 5 u 8).
  final int hpPenalty;
  final int currentStreak;
  final int bestStreak;
  final bool scheduledToday;
  final bool doneToday;

  /// Eventos registrados hoy (hábito malo).
  final int todayCount;

  /// Últimos 7 días, del más antiguo a hoy: hubo registro ese día.
  final List<bool> week;

  @override
  List<Object?> get props => [
    id,
    name,
    type,
    specificDays,
    skillName,
    hpPenalty,
    currentStreak,
    bestStreak,
    scheduledToday,
    doneToday,
    todayCount,
    week,
  ];
}
