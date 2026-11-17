import 'package:equatable/equatable.dart';

/// Qué puede hacer la persona desde una observación.
enum StatsAction { planDay, habits, review }

/// Observación con su acción opcional (el texto siempre va en tono de invitación).
typedef StatsNote = ({String text, StatsAction? action});

/// Estadísticas: últimos 7 días frente a los 7 anteriores (CLAUDE.md §13).
class StatsBoard extends Equatable {
  const StatsBoard({
    this.xp = 0,
    this.xpPrev = 0,
    this.tasks = 0,
    this.tasksPrev = 0,
    this.focusMinutes = 0,
    this.focusMinutesPrev = 0,
    this.bestStreak = 0,
    this.recordStreak = 0,
    this.xpByDay = const [],
    this.xpBySkill = const [],
    this.topHabits = const [],
  });

  final int xp;
  final int xpPrev;
  final int tasks;
  final int tasksPrev;

  /// Minutos de ciclos de Foco terminados.
  final int focusMinutes;
  final int focusMinutesPrev;

  /// Racha actual más larga y récord histórico.
  final int bestStreak;
  final int recordStreak;
  final List<DayXp> xpByDay;
  final List<SkillXp> xpBySkill;
  final List<HabitConsistency> topHabits;

  /// Las 3 observaciones del asistente (v1, por reglas). Siempre en tono de
  /// invitación: comparan con uno mismo, nunca culpan.
  /// Cada observación puede llevar a una acción real (`null` = solo texto).
  List<StatsNote> get observations {
    final notes = <StatsNote>[];
    if (xp > xpPrev) {
      notes.add((
        text:
            'Ganaste ${xp - xpPrev} XP más que la semana pasada. ¡Vas en subida!',
        action: StatsAction.review,
      ));
    } else if (xp == 0) {
      notes.add((
        text: 'Esta semana aún no hay XP: una tarea pequeña basta para arrancar.',
        action: StatsAction.planDay,
      ));
    } else {
      notes.add((
        text: 'Llevas $xp XP esta semana. Cada tarea cuenta, sin prisa.',
        action: StatsAction.planDay,
      ));
    }
    final bestDay = xpByDay.isEmpty
        ? null
        : xpByDay.reduce((a, b) => b.xp > a.xp ? b : a);
    if (bestDay != null && bestDay.xp > 0) {
      notes.add((
        text: 'Tu mejor día fue el ${_weekday(bestDay.day)}: ${bestDay.xp} XP.',
        action: null,
      ));
    }
    if (xpBySkill.isNotEmpty) {
      notes.add((
        text: '${xpBySkill.first.name} es el Área que más creció esta semana.',
        action: null,
      ));
    } else if (topHabits.isNotEmpty) {
      notes.add((
        text: '${topHabits.first.name} es tu hábito más constante del mes.',
        action: null,
      ));
    }
    if (focusMinutes > 0 && notes.length < 3) {
      notes.add((
        text: 'Pasaste $focusMinutes minutos en foco.',
        action: null,
      ));
    }
    if (notes.length < 3) {
      notes.add((
        text: bestStreak > 0
            ? 'Tu racha de $bestStreak días te está esperando.'
            : 'Un hábito bueno hoy enciende una racha nueva.',
        action: StatsAction.habits,
      ));
    }
    return notes.take(3).toList();
  }

  static String _weekday(DateTime d) => const [
    'lunes',
    'martes',
    'miércoles',
    'jueves',
    'viernes',
    'sábado',
    'domingo',
  ][d.weekday - 1];

  @override
  List<Object?> get props => [
    xp,
    xpPrev,
    tasks,
    tasksPrev,
    focusMinutes,
    focusMinutesPrev,
    bestStreak,
    recordStreak,
    xpByDay,
    xpBySkill,
    topHabits,
  ];
}

class DayXp extends Equatable {
  const DayXp(this.day, this.xp);

  final DateTime day;
  final int xp;

  @override
  List<Object?> get props => [day, xp];
}

class SkillXp extends Equatable {
  const SkillXp(this.name, this.xp);

  final String name;
  final int xp;

  @override
  List<Object?> get props => [name, xp];
}

class HabitConsistency extends Equatable {
  const HabitConsistency({
    required this.name,
    required this.days,
    this.streak = 0,
  });

  final String name;

  /// Días cumplidos en los últimos 30.
  final int days;
  final int streak;

  @override
  List<Object?> get props => [name, days, streak];
}
