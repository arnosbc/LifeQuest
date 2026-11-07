import 'package:equatable/equatable.dart';

/// Tarea abierta que vence esta semana o ya venció: hay que decidir qué
/// hacer con ella.
class ReviewTask extends Equatable {
  const ReviewTask({
    required this.id,
    required this.title,
    this.due,
    this.repeats = false,
  });

  final String id;
  final String title;
  final DateTime? due;
  final bool repeats;

  @override
  List<Object?> get props => [id, title, due, repeats];
}

/// La semana en curso (lunes a domingo): lo hecho y lo pendiente
/// (`weekly_review`, 034).
class WeeklyReview extends Equatable {
  const WeeklyReview({
    required this.weekStart,
    required this.done,
    required this.focusMinutes,
    required this.habitDays,
    required this.pending,
    this.inbox = 0,
  });

  final DateTime weekStart;
  final int done;
  final int focusMinutes;

  /// Registros de hábitos buenos cumplidos en la semana.
  final int habitDays;
  final List<ReviewTask> pending;

  /// Notas de la Bandeja sin decidir (044).
  final int inbox;

  @override
  List<Object?> get props => [
    weekStart,
    done,
    focusMinutes,
    habitDays,
    pending,
    inbox,
  ];
}
