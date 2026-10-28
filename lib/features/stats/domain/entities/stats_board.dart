import 'package:equatable/equatable.dart';

/// Estadísticas: últimos 7 días frente a los 7 anteriores (CLAUDE.md §13).
class StatsBoard extends Equatable {
  const StatsBoard({
    this.xp = 0,
    this.xpPrev = 0,
    this.missions = 0,
    this.missionsPrev = 0,
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
  final int missions;
  final int missionsPrev;

  /// Minutos de ciclos de Mazmorra terminados.
  final int focusMinutes;
  final int focusMinutesPrev;

  /// Racha actual más larga y récord histórico.
  final int bestStreak;
  final int recordStreak;
  final List<DayXp> xpByDay;
  final List<SkillXp> xpBySkill;
  final List<HabitConsistency> topHabits;

  /// Las 3 observaciones de RPGenie (v1, por reglas). Siempre en tono de
  /// invitación: comparan con uno mismo, nunca culpan.
  List<String> get observations {
    final notes = <String>[];
    if (xp > xpPrev) {
      notes.add(
        'Ganaste ${xp - xpPrev} XP más que la semana pasada. ¡Vas en subida!',
      );
    } else if (xp == 0) {
      notes.add(
        'Esta semana aún no hay XP: una misión pequeña basta para arrancar.',
      );
    } else {
      notes.add('Llevas $xp XP esta semana. Cada misión cuenta, sin prisa.');
    }
    final bestDay = xpByDay.isEmpty
        ? null
        : xpByDay.reduce((a, b) => b.xp > a.xp ? b : a);
    if (bestDay != null && bestDay.xp > 0) {
      notes.add(
        'Tu mejor día fue el ${_weekday(bestDay.day)}: ${bestDay.xp} XP.',
      );
    }
    if (xpBySkill.isNotEmpty) {
      notes.add(
        '${xpBySkill.first.name} es el Área que más creció esta semana.',
      );
    } else if (topHabits.isNotEmpty) {
      notes.add('${topHabits.first.name} es tu hábito más constante del mes.');
    }
    if (focusMinutes > 0 && notes.length < 3) {
      notes.add('Pasaste $focusMinutes minutos en la Mazmorra.');
    }
    if (notes.length < 3) {
      notes.add(
        bestStreak > 0
            ? 'Tu racha de $bestStreak días te está esperando 🔥'
            : 'Un hábito bueno hoy enciende una racha nueva.',
      );
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
    missions,
    missionsPrev,
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
