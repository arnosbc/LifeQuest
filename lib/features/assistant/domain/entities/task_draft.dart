import 'package:equatable/equatable.dart';

/// Lo que se entendió de una nota antes de guardarla. Cada campo se puede
/// quitar en la vista previa.
class TaskDraft extends Equatable {
  const TaskDraft({
    required this.title,
    this.isNote = false,
    this.scheduledAt,
    this.dueDate,
    this.estimatedMinutes,
    this.reminderMinutes,
    this.repeatRule,
    this.priority = 0,
  });

  final String title;

  /// No es algo por hacer: va a la Bandeja.
  final bool isNote;
  final DateTime? scheduledAt;
  final DateTime? dueDate;
  final int? estimatedMinutes;
  final int? reminderMinutes;

  /// Formato de `tasks.repeat_rule` (032).
  final String? repeatRule;

  /// 0 = baja, 1 = media, 2 = alta.
  final int priority;

  TaskDraft copyWith({
    String? title,
    DateTime? Function()? scheduledAt,
    DateTime? Function()? dueDate,
    int? Function()? estimatedMinutes,
    int? Function()? reminderMinutes,
    String? Function()? repeatRule,
    int? priority,
  }) {
    final at = scheduledAt == null ? this.scheduledAt : scheduledAt();
    return TaskDraft(
      title: title ?? this.title,
      isNote: isNote,
      scheduledAt: at,
      dueDate: dueDate == null ? this.dueDate : dueDate(),
      estimatedMinutes: estimatedMinutes == null
          ? this.estimatedMinutes
          : estimatedMinutes(),
      // Sin hora no hay aviso.
      reminderMinutes: at == null
          ? null
          : (reminderMinutes == null
                ? this.reminderMinutes
                : reminderMinutes()),
      repeatRule: repeatRule == null ? this.repeatRule : repeatRule(),
      priority: priority ?? this.priority,
    );
  }

  @override
  List<Object?> get props => [
    title,
    isNote,
    scheduledAt,
    dueDate,
    estimatedMinutes,
    reminderMinutes,
    repeatRule,
    priority,
  ];
}

/// Paso de «Dividir en pasos» con su fecha (`DayPlanner.spreadDates`).
class DraftStep extends Equatable {
  const DraftStep(this.title, this.due);

  final String title;
  final DateTime due;

  @override
  List<Object?> get props => [title, due];
}
