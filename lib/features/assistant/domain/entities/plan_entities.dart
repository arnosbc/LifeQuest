import 'package:equatable/equatable.dart';

/// Tarea abierta tal como la ve el planificador.
class PlanTask extends Equatable {
  const PlanTask({
    required this.id,
    required this.title,
    this.priority = 0,
    this.due,
    this.scheduledAt,
    this.minutes,
  });

  final String id;
  final String title;

  /// 0 = baja, 1 = media, 2 = alta (`urgency_level`).
  final int priority;
  final DateTime? due;

  /// Bloque ya puesto en la agenda (hora local).
  final DateTime? scheduledAt;
  final int? minutes;

  /// Duración del bloque; 30 min si no tiene.
  int get length => minutes ?? 30;

  @override
  List<Object?> get props => [id, title, priority, due, scheduledAt, minutes];
}

/// Tramo ocupado: un bloque puesto o, en la fase 4, un evento del calendario.
class Busy extends Equatable {
  const Busy(this.start, this.end);

  final DateTime start;
  final DateTime end;

  bool overlaps(DateTime s, DateTime e) => s.isBefore(end) && e.isAfter(start);

  @override
  List<Object?> get props => [start, end];
}

/// Bloque que propone el asistente; se acepta con `schedule_task`.
class ProposedBlock extends Equatable {
  const ProposedBlock({
    required this.taskId,
    required this.title,
    required this.start,
    required this.minutes,
  });

  final String taskId;
  final String title;
  final DateTime start;
  final int minutes;

  DateTime get end => start.add(Duration(minutes: minutes));

  @override
  List<Object?> get props => [taskId, title, start, minutes];
}

/// Qué pide el usuario: llenar el día o reubicar lo atrasado.
enum PlanMode { planDay, replan }

/// Propuesta para revisar antes de aceptar. [left] son las tareas que no
/// cupieron en los huecos libres.
class DayPlan extends Equatable {
  const DayPlan({
    required this.mode,
    required this.blocks,
    this.left = const [],
  });

  final PlanMode mode;
  final List<ProposedBlock> blocks;
  final List<PlanTask> left;

  @override
  List<Object?> get props => [mode, blocks, left];
}
